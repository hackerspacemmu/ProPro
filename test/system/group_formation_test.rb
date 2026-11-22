require 'application_system_test_case'

class GroupFormationTest < BrowserSystemTestCase
  setup do
    @course = create(:course, :grouped, group_formation_enabled: true,
                                        group_min: 2, group_max: 4, prevent_leftover_students: false)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @viewer = create(:user)
    create(:enrolment, user: @viewer, course: @course)

    @leader = create(:user, name: 'Alpha Leader')
    create(:enrolment, user: @leader, course: @course)
    @member = create(:user, name: 'Zelda Searchable')
    create(:enrolment, user: @member, course: @course)
    @other_leader = create(:user, name: 'Other Leader')
    create(:enrolment, user: @other_leader, course: @course)

    @group = create(:project_group, course: @course, leader_id: @leader.id, group_name: 'Alpha Group')
    create(:project_group_member, project_group: @group, user: @leader)
    create(:project_group_member, project_group: @group, user: @member)

    @confirmed = create(:project_group, course: @course, leader_id: @other_leader.id,
                                        group_name: 'Confirmed Group', confirmed: true)
    create(:project_group_member, project_group: @confirmed, user: @other_leader)
  end

  test 'search filters via htmx and expands matched rows' do
    login_as @viewer
    visit course_group_formation_path(@course)
    wait_for_turbo

    search_for 'Searchable'

    assert_text 'Alpha Group'
    assert_text 'Zelda Searchable'
    assert_no_text 'Confirmed Group'
    assert_selector '[data-row-toggle][aria-expanded="true"]'
  end

  test 'status filter shows only confirmed groups' do
    login_as @viewer
    visit course_group_formation_path(@course)
    wait_for_turbo

    select 'Confirmed', from: 'formation-status-filter'

    assert_text 'Confirmed Group'
    assert_no_text 'Alpha Group'
  end

  test 'staff Manage loads lazily and destructive actions use the shared confirm dialog' do
    login_as @coordinator
    visit course_group_formation_path(@course)
    wait_for_turbo
    assert_selector 'turbo-cable-stream-source[connected]', visible: :all
    page.document.synchronize do
      connected = page.evaluate_script(<<~JS)
        (() => {
          const element = document.querySelector('#project_group_#{@group.id} [data-controller="modal"]');
          return !!(window.Stimulus && element && window.Stimulus.getControllerForElementAndIdentifier(element, 'modal'));
        })()
      JS
      raise Capybara::ElementNotFound, 'The management dialog controller has not connected' unless connected
    end

    within "#project_group_#{@group.id}" do
      find_link('Manage').execute_script('this.click()')
    end

    assert_text 'MEMBERS'
    assert_selector 'h3', text: /add student/i, visible: :all

    within 'dialog[open]' do
      all('button', text: 'Remove', visible: :all).first.execute_script('this.click()')
    end

    assert_selector '#confirm-dialog[open]'
    assert_text 'Remove Alpha Leader?'

    within '#confirm-dialog' do
      find_button('Cancel').execute_script('this.click()')
    end

    assert_no_selector '#confirm-dialog[open]'
  end

  test 'creating a group from the Create group dialog leaves the page usable' do
    login_as @coordinator
    visit course_group_formation_path(@course)
    wait_for_turbo

    find_button('Create group', exact: true).execute_script('this.click()')
    assert_selector 'dialog[open] h2', text: 'Create group'
    within 'dialog[open]' do
      find_button('Create', exact: true).execute_script('this.click()')
    end

    assert_text 'Group Tmp001 created.'
    assert_equal 0, page.evaluate_script("document.querySelectorAll('dialog:modal').length")
    fill_in 'formation-search', with: 'Alpha'
  end

  test 'deleting a group from the Manage dialog leaves the page usable' do
    doomed_leader = create(:user, name: 'Doomed Leader')
    create(:enrolment, user: doomed_leader, course: @course)
    group = create(:project_group, course: @course, leader_id: doomed_leader.id, group_name: 'Doomed Group')
    create(:project_group_member, project_group: group, user: doomed_leader)

    login_as @coordinator
    visit course_group_formation_path(@course)
    wait_for_turbo

    within "#project_group_#{group.id}" do
      find_link('Manage').execute_script('this.click()')
    end
    assert_selector 'dialog[open] h3', text: 'MEMBERS'

    within 'dialog[open]' do
      find_button('Delete group').execute_script('this.click()')
    end
    within '#confirm-dialog[open]' do
      find_button('Delete group').execute_script('this.click()')
    end

    assert_no_selector "#project_group_#{group.id}"
    assert_text 'Group deleted.'
    assert_equal 0, page.evaluate_script("document.querySelectorAll('dialog:modal').length")
    fill_in 'formation-search', with: 'Alpha'
  end

  private

  def search_for(query)
    page.execute_script(
      "const input = document.querySelector('#formation-search');" \
      'input.value = arguments[0];' \
      "input.dispatchEvent(new Event('input', { bubbles: true }));",
      query
    )
  end
end
