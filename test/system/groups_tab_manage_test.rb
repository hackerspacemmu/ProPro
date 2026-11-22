require 'application_system_test_case'

# The Groups tab reuses the formation page's Manage dialog, so its destructive
# buttons depend on the page hosting the shared confirm dialog and the #modals
# turbo-stream target.
class GroupsTabManageTest < BrowserSystemTestCase
  setup do
    @course = create(:course, :grouped, group_formation_enabled: true,
                                        group_min: 2, group_max: 4, prevent_leftover_students: false)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @student = create(:user, name: 'Solo Student')
    create(:enrolment, user: @student, course: @course)
    @group = create(:project_group, course: @course, leader_id: @student.id,
                                    group_name: 'Alpha Group', confirmed: true)
    create(:project_group_member, project_group: @group, user: @student)
  end

  test 'deleting a group with no project asks for confirmation on the Groups tab' do
    login_as @coordinator
    visit course_groups_path(@course)
    wait_for_turbo
    open_management

    within 'dialog[open]' do
      find_button('Delete group').execute_script('this.click()')
    end

    assert_selector '#confirm-dialog[open]'
    within '#confirm-dialog[open]' do
      find_button('Cancel').execute_script('this.click()')
    end

    assert_no_selector '#confirm-dialog[open]'
    assert_selector "#project_group_#{@group.id}", text: 'Alpha Group'
  end

  test 'deleting a group with a project shows the warning modal on the Groups tab' do
    supervisor = create(:enrolment, :lecturer, course: @course)
    project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup', supervisor_enrolment: supervisor)
    create(:project_instance, project: project, supervisor_enrolment: supervisor, created_by: @student)

    login_as @coordinator
    visit course_groups_path(@course)
    wait_for_turbo
    open_management

    within 'dialog[open]' do
      find_button('Delete group').execute_script('this.click()')
    end

    assert_selector '#delete-group-warning-modal[open]'
    assert_selector "#project_group_#{@group.id}", text: 'Alpha Group'
  end

  private

  def open_management
    wait_for_controller("#project_group_#{@group.id} [data-controller=\"modal\"]", 'modal')
    within "#project_group_#{@group.id}" do
      find_link('Manage').execute_script('this.click()')
    end
    assert_selector 'dialog[open] h3', text: 'MEMBERS'
  end

  def wait_for_controller(selector, identifier)
    page.document.synchronize do
      connected = page.evaluate_script(<<~JS, selector, identifier)
        (() => {
          const element = document.querySelector(arguments[0]);
          return !!(window.Stimulus && element && window.Stimulus.getControllerForElementAndIdentifier(element, arguments[1]));
        })()
      JS
      raise Capybara::ElementNotFound, "The #{identifier} controller is not ready" unless connected
    end
  end
end
