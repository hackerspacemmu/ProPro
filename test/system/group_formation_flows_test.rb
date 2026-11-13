require 'application_system_test_case'

class GroupFormationFlowsTest < ApplicationSystemTestCase
  setup do
    @course = create(:course, :grouped, group_formation_enabled: true,
                                        group_min: 2, group_max: 4, prevent_leftover_students: false)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @leader = create(:user, name: 'Alpha Leader')
    create(:enrolment, user: @leader, course: @course)
    @member = create(:user, name: 'Beta Member')
    create(:enrolment, user: @member, course: @course)
    @student = create(:user, name: 'Gamma Student')
    create(:enrolment, user: @student, course: @course)
  end

  test 'a student creates a group' do
    login_as @student
    visit course_group_formation_path(@course)

    click_button 'Create group'

    assert_text 'Group Tmp001 created.'
    assert_selector '#my-group-panel'
  end

  test 'a student joins a not-confirmed group' do
    group = not_confirmed_group('Joinable Group')

    login_as @student
    visit course_group_formation_path(@course)

    within "#project_group_#{group.id}" do
      click_button 'Join'
    end

    assert_text 'Joined the group.'
    assert_selector '#my-group-panel'
    within "#project_group_#{group.id}" do
      assert_text '3 of 4 members'
    end
  end

  test 'a student requests to join a confirmed group and the leader accepting reopens it' do
    group = confirmed_group('Confirmed Group')

    login_as @student
    visit course_group_formation_path(@course)

    within "#project_group_#{group.id}" do
      click_button 'Request to join'
    end

    assert_text 'Join request sent.'
    within "#project_group_#{group.id}" do
      assert_text 'Request sent'
    end

    Capybara.using_session(:leader) do
      login_as @leader
      visit edit_course_group_path(@course, group)
      click_button 'Accept'

      assert_text 'Group reopened because'
      within '#my-group-panel' do
        assert_text 'Not confirmed'
        assert_button 'Confirm group'
      end
    end

    visit course_group_formation_path(@course)
    assert_selector '#my-group-panel'
    within "#project_group_#{group.id}" do
      assert_text 'Not confirmed'
    end
  end

  test 'a student accepts an invite from a leader' do
    group = not_confirmed_group('Invite Group')

    Capybara.using_session(:leader) do
      login_as @leader
      visit edit_course_group_path(@course, group)

      within find("[data-list-filter-target='item']", text: @student.name) do
        click_button 'Invite'
      end

      assert_text 'Invite sent.'
    end

    Capybara.using_session(:invited) do
      login_as @student
      visit course_group_formation_path(@course)

      assert_text "Invited by #{@leader.name}"
      within 'div[data-dropdown-target="menu"]' do
        click_button 'Accept'
      end

      assert_selector '#my-group-panel'
    end
  end

  test 'a student joins through an invite link' do
    group = not_confirmed_group('Link Group')
    invite_url = nil

    Capybara.using_session(:leader) do
      login_as @leader
      visit edit_course_group_path(@course, group)
      click_button 'Generate invite link'
      assert_text 'Invite link generated.'

      visit edit_course_group_path(@course, group)
      invite_url = find('input[aria-label="Invite link"]').value
    end

    Capybara.using_session(:invited) do
      login_as @student
      visit invite_url

      click_button 'Accept invite'

      assert_text "You've joined Link Group."
      assert_selector '#my-group-panel'
    end
  end

  test 'a leader confirms and reopens a group' do
    not_confirmed_group('Confirm Group')

    login_as @leader
    visit course_group_formation_path(@course)

    within '#my-group-panel' do
      click_button 'Confirm group'
    end

    within '#my-group-panel' do
      assert_text 'Confirmed'
      assert_button 'Reopen group'
      assert_no_button 'Confirm group'
    end

    within '#my-group-panel' do
      click_button 'Reopen group'
    end

    within '#my-group-panel' do
      assert_text 'Not confirmed'
      assert_button 'Confirm group'
      assert_no_button 'Reopen group'
    end
  end

  test 'a coordinator adds a student to a group' do
    group = not_confirmed_group('Managed Group')

    login_as @coordinator
    visit edit_course_group_path(@course, group)

    within find("[data-list-filter-target='item']", text: @student.name) do
      click_button 'Add'
    end

    assert_text 'Student added to group.'

    visit edit_course_group_path(@course, group)
    assert_text @student.name
    assert_not group.reload.confirmed?
  end

  private

  def not_confirmed_group(name)
    create(:project_group, course: @course, leader_id: @leader.id, group_name: name).tap do |group|
      create(:project_group_member, project_group: group, user: @leader)
      create(:project_group_member, project_group: group, user: @member)
    end
  end

  def confirmed_group(name)
    create(:project_group, course: @course, leader_id: @leader.id,
                           group_name: name, confirmed: true).tap do |group|
      create(:project_group_member, project_group: group, user: @leader)
      create(:project_group_member, project_group: group, user: @member)
    end
  end

  # rack_test runs no JavaScript, so Turbo's cable source never reports itself
  # connected and the default visit wrapper would wait forever.
  def visit(path, **)
    page.visit(path, **)
  end
end
