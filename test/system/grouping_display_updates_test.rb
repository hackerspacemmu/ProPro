require 'application_system_test_case'

class GroupingDisplayUpdatesTest < BrowserSystemTestCase
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true,
                                        group_min: 3, group_max: 4, student_list_finalised: false)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, course: @course, user: @coordinator)
    @students = Array.new(4) do
      create(:user).tap { |user| create(:enrolment, course: @course, user: user) }
    end
    @group = create(:project_group, course: @course, leader_id: @students.first.id, group_name: 'Alpha Group')
    @students.first(3).each { |user| create(:project_group_member, project_group: @group, user: user) }
  end

  [false, true].each do |automatic|
    test "coordinator removal updates both pages and the open dialog in #{automatic ? 'automatic' : 'default'} mode" do
      @course.update!(student_list_finalised: automatic)
      @group.update!(confirmed: true)
      watch_groups_tab
      open_formation(@coordinator)
      open_management
      member = @group.project_group_members.find_by!(user: @students.third)

      remove_member(member)

      assert_selector 'dialog[open] h3', text: 'MEMBERS (2 of 4)'
      assert_no_selector "#manage_project_group_member_#{member.id}", visible: :all
      within 'dialog[open]' do
        assert_selector '[data-group-size-warning]', text: warning_for(2)
      end
      within "#project_group_#{@group.id}" do
        assert_text '2 of 4 members'
        assert_text 'Confirmed'
        assert_selector '[data-group-size-warning][role="img"]'
      end
      assert_monitor_count(2, warning: true)
    end
  end

  test 'joining refreshes both pages and clears the warning when the group reaches its minimum' do
    @group.project_group_members.find_by!(user: @students.third).destroy!
    watch_groups_tab_without_drafts
    Capybara.using_session(:formation_observer) do
      open_formation(@students.first)
      select 'Invalid size', from: 'formation-status-filter'
      assert_selector '[data-group-size-warning][role="img"]'
      assert_current_path(/status_filter=invalid/)
    end
    open_formation(@students.last)
    within "#project_group_#{@group.id}" do
      click_button_in_page 'Join'
    end

    assert_text 'Joined the group.'
    assert_selector "#project_group_#{@group.id}", text: '3 of 4 members'
    assert_no_selector '[data-group-size-warning]'
    assert_groups_monitor_without_drafts
    Capybara.using_session(:formation_observer) do
      assert_selector '#formation-groups', text: 'No groups match your current filters.'
      assert_selector '#formation-status-filter option:checked', text: /Invalid size/
      assert_selector '#my-group-panel', text: '3 of 4'
      assert_no_text warning_for(2)
    end
  end

  test 'a student leaving updates both pages and warns the remaining group members' do
    @course.update!(student_list_finalised: true)
    watch_groups_tab_without_drafts
    Capybara.using_session(:formation_observer) { open_formation(@students.first) }
    open_formation(@students.third)

    within '#my-group-panel' do
      click_button_in_page 'Leave group'
    end
    within '#confirm-dialog[open]' do
      click_button_in_page 'Leave group'
    end

    assert_no_selector '#my-group-panel'
    assert_selector "#project_group_#{@group.id}", text: '2 of 4 members'
    assert_groups_monitor_without_drafts
    Capybara.using_session(:formation_observer) do
      assert_selector '#my-group-panel', text: '2 of 4'
      assert_selector '#my-group-panel', text: warning_for(2)
    end
  end

  test 'removing the last member removes the group and its open dialog from both pages' do
    @group.project_group_members.where.not(user: @students.first).destroy_all
    @group.update!(confirmed: true)
    watch_groups_tab
    open_formation(@coordinator)
    open_management

    remove_member(@group.project_group_members.first)

    assert_no_selector "#project_group_#{@group.id}"
    assert_no_selector 'dialog[open]'
    assert_text 'No groups yet'
    Capybara.using_session(:groups_monitor) do
      assert_no_selector "#project_group_#{@group.id}"
    end
  end

  private

  def open_formation(user)
    login_as(user)
    visit course_group_formation_path(@course)
    wait_for_turbo
    assert_selector 'turbo-cable-stream-source[connected]', visible: :all
    wait_for_controller('#confirm-dialog', 'confirm-dialog')
    wait_for_controller('#formation-groups', 'expandable-rows')
    wait_for_turbo
  end

  def watch_groups_tab
    Capybara.using_session(:groups_monitor) do
      login_as(@coordinator)
      visit course_groups_path(@course)
      wait_for_turbo
      assert_selector 'turbo-cable-stream-source[connected]', visible: :all
      count = @group.project_group_members.count
      assert_selector "#project_group_#{@group.id}", text: "#{count} #{count == 1 ? 'member' : 'members'}"
    end
  end

  # While the window is open the Groups tab hides not-confirmed
  # groups entirely, so the coordinator's monitor session asserts their absence
  # instead of watching their rows update.
  def watch_groups_tab_without_drafts
    Capybara.using_session(:groups_monitor) do
      login_as(@coordinator)
      visit course_groups_path(@course)
      wait_for_turbo
      assert_selector 'turbo-cable-stream-source[connected]', visible: :all
      assert_no_selector "#project_group_#{@group.id}"
    end
  end

  def assert_groups_monitor_without_drafts
    Capybara.using_session(:groups_monitor) do
      assert_no_selector "#project_group_#{@group.id}"
    end
  end

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

  def remove_member(member)
    within "#manage_project_group_member_#{member.id}" do
      click_button_in_page 'Remove'
    end
    within '#confirm-dialog[open]' do
      click_button_in_page 'Remove from group'
    end
  end

  def click_button_in_page(label)
    # Exercise the real button/form handlers without depending on focus between
    # the three independent headless Chrome windows used by these live tests.
    find_button(label, exact: true).execute_script('this.click()')
  end

  def assert_monitor_count(count, warning:)
    Capybara.using_session(:groups_monitor) do
      within "#project_group_#{@group.id}" do
        assert_text "#{count} members"
        if warning
          assert_selector '[data-group-size-warning][role="img"]'
        else
          assert_no_selector '[data-group-size-warning]'
        end
      end
    end
  end

  def warning_for(count)
    "Warning: Alpha Group has #{count} members; the allowed size is 3–4 members."
  end
end
