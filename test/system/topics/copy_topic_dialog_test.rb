require 'application_system_test_case'

# Validates the "reuse details from another topic" native <dialog> on
# topics/new — opening, topic selection (turbo frame step-1 → step-2),
# and closing after Copy Details.  Requires a real browser because the
# interaction is driven by showModal() / Stimulus controllers.
class TopicCopyTopicDialogTest < BrowserSystemTestCase
  setup do
    @course = create(:course, require_coordinator_approval: true, toggle_topics: true)
    @lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    # The course factory already creates a shorttext template field (Project Title).
    # Add a dropdown (Supervisor) and a textarea (Description) field so the copy
    # path is exercised for every input type — the textarea case regressed once
    # when its text-editor:update bridge was dropped in the redesign.
    @template = @course.project_template
    @template_field = @template.project_template_fields.create!(
      label: 'Supervisor',
      field_type: 'dropdown',
      applicable_to: 'both',
      required: true,
      options: %w[Alice Bob],
      is_project_title: false
    )
    @description_field = @template.project_template_fields.create!(
      label: 'Description',
      field_type: 'textarea',
      applicable_to: 'both',
      required: false,
      is_project_title: false
    )

    # A topic owned by the lecturer with an approved instance + filled fields
    @source_topic = create(:topic, course: @course, owner: @lecturer)
    @source_instance = create(:topic_instance,
                              topic: @source_topic,
                              created_by: @lecturer,
                              version: 1,
                              status: :approved,
                              title: 'Source Topic')

    @title_field = @template.project_template_fields.find_by(is_project_title: true)
    @source_instance.project_instance_fields.create!(
      project_template_field: @title_field,
      value: 'Origin Title'
    )
    @source_instance.project_instance_fields.create!(
      project_template_field: @template_field,
      value: 'Alice'
    )
    @source_instance.project_instance_fields.create!(
      project_template_field: @description_field,
      value: 'A detailed markdown description **with emphasis**'
    )
  end

  test 'opens dialog, shows source topic, loads step-2, and closes after copy' do
    login_as(@lecturer)
    visit new_course_topic_path(@course)
    wait_for_turbo

    # Step 1: click "Reuse details from another topic" → dialog opens.
    # A physical Capybara click is intermittently swallowed by headless Chrome
    # (the suite's known dropped-first-click race) even with wait_for_turbo, so
    # fall back to a programmatic click if the dialog didn't stick.
    assert_selector '#topic-form', wait: 3
    trigger = find("button[data-action='click->copy-topic#open']", wait: 3)
    unless page.has_selector?('dialog[open]', wait: 2)
      trigger.click
      unless page.has_selector?('dialog[open]', wait: 2)
        page.execute_script(<<~JS)
          document.querySelector("button[data-action='click->copy-topic#open']").click()
        JS
      end
    end
    assert_selector 'dialog[open]', wait: 3
    assert_text 'Source Topic', wait: 3

    # Click the source topic card → turbo frame loads step-2 (same physical-
    # click race; fall back to a programmatic click if the frame didn't move).
    within 'dialog' do
      card = find('a', text: 'Source Topic')
      unless page.has_text?('Copy details from', wait: 2)
        card.click
        unless page.has_text?('Copy details from', wait: 2)
          page.execute_script(<<~JS)
            [...document.querySelectorAll('dialog a')].find((a) => a.textContent.includes('Source Topic')).click()
          JS
        end
      end
    end

    assert_text 'Copy details from', wait: 3
    within 'dialog' do
      assert_text 'Supervisor', wait: 3
    end

    # Click "Copy Details" → values transfer to the main form, dialog closes
    # (same physical-click race; fall back to a programmatic click if the
    # dialog doesn't close).
    # Click "Copy Details" → values transfer to the main form, dialog closes
    # (same physical-click race; fall back to a programmatic click if the
    # dialog doesn't close). The open-state check must run at page scope, not
    # inside `within 'dialog'` (which would only find a nested dialog).
    within 'dialog' do
      find('button', text: 'Copy Details').click
    end
    unless page.has_no_selector?('dialog[open]', wait: 2)
      page.execute_script(<<~JS)
        [...document.querySelectorAll('dialog button')].find((b) => b.textContent.includes('Copy Details')).click()
      JS
    end

    assert_no_selector 'dialog[open]', wait: 3

    # The copied description must reach the EasyMDE editor on the main topic
    # form (regression: the text-editor:update bridge was dropped in the
    # redesign, so textarea copies never populated the visible editor — the
    # raw textarea value alone synced back empty via forceSync).
    editor_text = page.evaluate_script(<<~JS)
      (() => {
        const ta = document.querySelector("textarea[name='fields[#{@description_field.id}]']");
        if (!ta) return null;
        const wrapper = ta.closest('.space-y-1');
        const cm = wrapper && wrapper.querySelector('.CodeMirror');
        return cm ? cm.textContent : null;
      })()
    JS
    assert_includes editor_text.to_s,
                    'A detailed markdown description',
                    'visible EasyMDE editor should show the copied description'
  end

  test 'topics/edit renders the modern takeover layout and template fields' do
    edit_topic = create(:topic, course: @course, owner: @lecturer)
    create(:topic_instance,
           topic: edit_topic,
           created_by: @lecturer,
           version: 1,
           status: :pending,
           title: 'Editable Topic')

    login_as(@lecturer)
    visit edit_course_topic_path(@course, edit_topic)

    # Takeover layout: sticky header title + Google-style section
    assert_text 'Edit Topic', wait: 3
    assert_selector '#topic-form', wait: 3
    assert_selector '#template-fields-container', wait: 3
    assert_text 'Topic Details', wait: 3
  end
end
