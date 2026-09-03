require 'application_system_test_case'

# Validates the "reuse details from another topic" native <dialog> on
# topics/new — opening, topic selection (turbo frame step-1 → step-2),
# and closing after Copy Details.  Requires a real browser because the
# interaction is driven by showModal() / Stimulus controllers.
class TopicCopyTopicDialogTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  setup do
    @course = create(:course, require_coordinator_approval: true, toggle_topics: true)
    @lecturer = create(:user, is_staff: true)
    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    # The course factory already creates a shorttext template field (Project Title).
    # Add a second (dropdown) field for richer assertions.
    @template = @course.project_template
    @template_field = @template.project_template_fields.create!(
      label: 'Supervisor',
      field_type: 'dropdown',
      applicable_to: 'both',
      required: true,
      options: %w[Alice Bob],
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
  end

  teardown do
    return if @course.nil?

    TopicInstance.where(project_id: @course.topics.ids).find_each do |inst|
      inst.comments.delete_all
      inst.project_instance_fields.delete_all
    end
    TopicInstance.where(project_id: @course.topics.ids).delete_all
    Topic.where(course_id: @course.id).delete_all
    @course.project_template&.project_template_fields&.delete_all
    @course.project_template&.delete
    @course.enrolments.delete_all
    @lecturer&.sessions&.delete_all
    @lecturer&.otp&.delete
    @lecturer&.delete
    @course.delete
  end

  # Turbo submits the login form via fetch; wait deterministically for the
  # post-login redirect so the subsequent `visit` doesn't race it.
  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

  test 'opens dialog, shows source topic, loads step-2, and closes after copy' do
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    # Step 1: click "Reuse details from another topic" → dialog opens
    click_button 'Reuse details from another topic', wait: 3

    assert_selector 'dialog[open]', wait: 3
    assert_text 'Source Topic', wait: 3

    # Click the source topic card → turbo frame loads step-2
    within 'dialog' do
      find('a', text: 'Source Topic').click
    end

    assert_text 'Copying from', wait: 3
    within 'dialog' do
      assert_text 'Supervisor', wait: 3
    end

    # Click "Copy Details" → values transfer to the main form, dialog closes
    within 'dialog' do
      click_button 'Copy Details'
    end

    assert_no_selector 'dialog[open]', wait: 3
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
