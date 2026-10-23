require 'application_system_test_case'

class ProjectFormTest < ApplicationSystemTestCase
  setup do
    @course      = create(:course)
    @student     = create(:user)
    @student_enr = create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, :staff, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)
    create(:enrolment, :lecturer, course: @course)
    create(:enrolment, :coordinator, course: @course)

    @title_field = @course.project_template.project_template_fields.first
  end

  test 'new proposal shows both method cards for a multi-supervisor course' do
    login_as(@student)
    visit new_course_project_path(@course)

    assert_selector 'h2', text: 'Proposal Method'
    assert_selector '[data-controller="method-picker"]'
    assert_selector 'h3', text: 'Propose to Lecturer'
    assert_selector 'h3', text: 'Base on a Topic'
    assert_selector 'button', text: 'Browse Topic Catalog'
    assert_nil find('#based_on_topic', visible: false).value.presence
  end

  test 'creates an own proposal via lecturer_id param' do
    login_as(@student)
    visit new_course_project_path(@course, lecturer_id: @lecturer.id)

    assert_selector "[data-method-picker-target='lecturerName']", text: @lecturer.name
    assert_equal "own_proposal_#{@lecturer_enr.id}", find('#based_on_topic', visible: false).value

    fill_in "fields_#{@title_field.id}", with: 'My Very Own Proposal'
    first(:button, 'Create Proposal').click

    project = Project.where(owner: @student).last
    assert_current_path course_project_path(@course, project)
    assert_equal @lecturer, project.supervisor
    assert_equal 'My Very Own Proposal', project.current_title
    assert_nil project.current_instance.source_topic
  end

  test 'creates a proposal based on a topic and prefills template fields' do
    topic = create(:topic, course: @course, owner: @lecturer)
    topic_instance = create(:topic_instance, topic: topic, status: :approved)
    topic_instance.project_instance_fields.create!(
      project_template_field_id: @title_field.id,
      value: 'Topic Default Title'
    )
    topic.update!(status: :approved)

    login_as(@student)
    visit new_course_project_path(@course, topic_id: topic.id)

    assert_equal 'Topic Default Title', find("#fields_#{@title_field.id}").value
    assert_equal topic.id.to_s, find('#based_on_topic', visible: false).value

    first(:button, 'Create Proposal').click

    project = Project.where(owner: @student).last
    assert_equal @lecturer, project.supervisor
    assert_equal topic, project.current_instance.source_topic
    assert_equal 'Topic Default Title', project.current_title
  end

  test 'student edits their own pending proposal in place' do
    project    = create(:project, course: @course, owner: @student, supervisor_enrolment: @lecturer_enr)
    instance   = create(:project_instance, project: project, supervisor_enrolment: @lecturer_enr,
                                           created_by: @student, version: 1, status: :pending, title: 'Old Title')
    instance.project_instance_fields.create!(project_template_field_id: @title_field.id, value: 'Old Title')

    login_as(@student)
    visit edit_course_project_path(@course, project)

    assert_selector 'h1', text: /Edit Proposal/
    assert_equal 'Old Title', find("#fields_#{@title_field.id}").value

    fill_in "fields_#{@title_field.id}", with: 'Polished Title'
    first(:button, 'Update Proposal').click

    assert_current_path course_project_path(@course, project)
    project.reload
    assert_equal 1, project.project_instances.count
    assert_equal 'Polished Title', project.current_title
  end

  test 'editing after a supervisor comment creates a new version' do
    project  = create(:project, course: @course, owner: @student, supervisor_enrolment: @lecturer_enr)
    instance = create(:project_instance, project: project, supervisor_enrolment: @lecturer_enr,
                                         created_by: @student, version: 1, status: :pending, title: 'V1')
    instance.project_instance_fields.create!(project_template_field_id: @title_field.id, value: 'V1')
    Comment.create!(user: @lecturer, location: instance, text: 'Please polish this before resubmitting.')

    login_as(@student)
    visit edit_course_project_path(@course, project)

    fill_in "fields_#{@title_field.id}", with: 'V2'
    first(:button, 'Update Proposal').click

    project.reload
    assert_equal 2, project.project_instances.maximum(:version)
    assert_equal 'V2', project.current_title
  end

  test 'approved proposal is read-only with only free-edit fields editable' do
    free_edit_field = create(:project_template_field, project_template: @course.project_template,
                                                      label: 'Progress Notes', field_type: :textarea,
                                                      applicable_to: :both, free_edit: true)

    project  = create(:project, course: @course, owner: @student, supervisor_enrolment: @lecturer_enr)
    instance = create(:project_instance, project: project, supervisor_enrolment: @lecturer_enr,
                                         created_by: @student, version: 1, status: :approved, title: 'Approved One')
    instance.project_instance_fields.create!(project_template_field_id: @title_field.id, value: 'Approved One')
    instance.project_instance_fields.create!(project_template_field_id: free_edit_field.id, value: 'note v1')

    login_as(@student)
    visit edit_course_project_path(@course, project)

    assert find("#fields_#{@title_field.id}").disabled?
    assert_not find("#fields_#{free_edit_field.id}").disabled?
    assert_no_selector 'button', text: 'Change'

    fill_in "fields_#{free_edit_field.id}", with: 'note v2'
    first(:button, 'Update Proposal').click

    project.reload
    assert_equal 1, project.project_instances.count
    fields = project.current_instance.project_instance_fields
    assert_equal 'note v2', fields.find_by(project_template_field_id: free_edit_field.id).value
    assert_equal 'Approved One', fields.find_by(project_template_field_id: @title_field.id).value
  end

  test 'solo-supervisor course defaults to own proposal' do
    course   = create(:course)
    student  = create(:user)
    create(:enrolment, :student, user: student, course: course)
    lecturer = create(:user, :staff, name: 'Solo Sam')
    create(:enrolment, :lecturer, user: lecturer, course: course)
    solo_title_field = course.project_template.project_template_fields.first

    login_as(student)
    visit new_course_project_path(course)

    assert_no_selector 'h3', text: 'Propose to Lecturer'
    assert_selector 'h3', text: 'Base on a Topic'

    fill_in "fields_#{solo_title_field.id}", with: 'Solo Proposal'
    first(:button, 'Create Proposal').click

    project = Project.where(owner: student).last
    assert_equal lecturer, project.supervisor
    assert_equal 'Solo Proposal', project.current_title
  end
end

# The proposal-method picker and the markdown description editor are both
# JavaScript, so these need a real browser (the class above runs on rack_test).
class ProjectFormPickerTest < BrowserSystemTestCase
  setup do
    @course  = create(:course)
    @student = create(:user)
    create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, :staff, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @other_lecturer     = create(:user, :staff, name: 'Bob Ray')
    @other_lecturer_enr = create(:enrolment, :lecturer, user: @other_lecturer, course: @course)

    create(:enrolment, :coordinator, course: @course)

    @title_field = @course.project_template.project_template_fields.first
    @description_field = create(:project_template_field,
                                project_template: @course.project_template,
                                label: 'Description', field_type: :textarea,
                                applicable_to: :both, required: true, is_project_title: false)
  end

  test 'changing the supervisor keeps the content and saves the new supervisor' do
    project = build_project

    login_as(@student)
    visit edit_course_project_path(@course, project)
    wait_for_turbo

    open_lecturer_picker
    script_click("button[data-method-picker-target='lecturerOption'][data-enrolment-id='#{@other_lecturer_enr.id}']")

    submit_form

    assert_current_path course_project_path(@course, project)

    project.reload
    assert_equal @other_lecturer, project.supervisor
    assert_equal 'Original Title', project.current_title
    fields = project.current_instance.project_instance_fields
    assert_equal 'Original description', fields.find_by(project_template_field_id: @description_field.id).value
  end

  test 'picking a topic confirms, shows its text in the editor and saves it' do
    topic   = build_topic
    project = build_project

    login_as(@student)
    visit edit_course_project_path(@course, project)
    wait_for_turbo

    open_topic_picker
    pick_topic(topic, accept: true)

    assert confirm_message.present?
    assert_match 'Topic description', find('.CodeMirror').text

    submit_form

    assert_current_path course_project_path(@course, project)

    fields = project.reload.current_instance.project_instance_fields
    assert_equal 'Topic description', fields.find_by(project_template_field_id: @description_field.id).value
  end

  test 'cancelling the topic overwrite changes nothing and keeps the dialog open' do
    topic   = build_topic
    project = build_project

    login_as(@student)
    visit edit_course_project_path(@course, project)
    wait_for_turbo

    open_topic_picker
    pick_topic(topic, accept: false)

    assert_selector 'dialog[open]'
    assert_equal "own_proposal_#{@lecturer_enr.id}", based_on_topic
    assert_equal 'Original description', description_value
  end

  test 'an empty required description shows a visible error instead of a dead submit' do
    project = build_project(description: nil)

    login_as(@student)
    visit edit_course_project_path(@course, project)
    wait_for_turbo

    submit_form

    assert_selector '[data-markdown-editor-error]', visible: true, text: /fill/i
    assert_current_path edit_course_project_path(@course, project)
  end

  private

  # Headless Chrome intermittently swallows native clicks on a freshly loaded
  # page (the suite's known dropped-first-click race), so every interaction
  # here is scripted -- the same approach as
  # test/system/courses/settings_coursecode_test.rb.
  def script_click(selector)
    page.execute_script("document.querySelector(#{selector.inspect}).click()")
  end

  def open_lecturer_picker
    script_click("[data-method-picker-target='lecturerSurface'] button")
    assert_selector 'dialog[open]', wait: 3
  end

  def open_topic_picker
    script_click("[data-method-picker-target='topicEmpty'] button")
    assert_selector 'dialog[open]', wait: 3
  end

  # The topic overwrite asks for confirmation before it replaces the student's
  # own values. The native modal blocks the driver, so it is replaced by a
  # stub that records the prompt and answers it.
  def pick_topic(topic, accept:)
    page.execute_script(<<~JS)
      window.__confirmMessage = null;
      window.confirm = (message) => { window.__confirmMessage = message; return #{accept}; };
    JS
    script_click("button[data-method-picker-target='topicOption'][data-topic-id='#{topic.id}']")
  end

  def confirm_message
    page.evaluate_script('window.__confirmMessage')
  end

  def based_on_topic
    find('#based_on_topic', visible: false).value
  end

  def description_value
    find("#fields_#{@description_field.id}", visible: false).value
  end

  def submit_form
    script_click("#project-form button[type='submit']")
  end

  def build_project(description: 'Original description')
    project = create(:project, course: @course, owner: @student, supervisor_enrolment: @lecturer_enr)
    instance = create(:project_instance, project: project, supervisor_enrolment: @lecturer_enr,
                                         created_by: @student, version: 1, status: :pending,
                                         title: 'Original Title')
    instance.project_instance_fields.create!(project_template_field_id: @title_field.id,
                                             value: 'Original Title')
    if description
      instance.project_instance_fields.create!(project_template_field_id: @description_field.id,
                                               value: description)
    end
    project
  end

  def build_topic
    topic = create(:topic, course: @course, owner: @lecturer)
    instance = create(:topic_instance, topic: topic, created_by: @lecturer,
                                       version: 1, status: :approved, title: 'Topic Title')
    instance.project_instance_fields.create!(project_template_field_id: @title_field.id,
                                             value: 'Topic Title')
    instance.project_instance_fields.create!(project_template_field_id: @description_field.id,
                                             value: 'Topic description')
    topic.update!(status: :approved)
    topic
  end
end
