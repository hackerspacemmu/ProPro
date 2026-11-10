require 'test_helper'

class GroupsCoordinatorReopenerTest < ActiveSupport::TestCase
  test 'reopens a confirmed group to unconfirmed and renames to lowest free Tmp number' do
    course = create(:course, grouping_enabled: true, grouping_open: true)
    group = create(:project_group, course: course, confirmed: true, group_name: 'G001')

    result = Groups::Coordinator::Reopener.new(group).reopen!

    assert result.reopened?
    assert_not group.reload.confirmed?
    assert_equal 'Tmp001', group.group_name
    assert_equal 'G001 is reopened as Tmp001.', result.message
  end

  test 'reopens a confirmed group when the grouping window is closed' do
    course = create(:course, grouping_enabled: true, grouping_open: false)
    group = create(:project_group, course: course, confirmed: true, group_name: 'G001')

    result = Groups::Coordinator::Reopener.new(group).reopen!

    assert result.reopened?
    assert_not group.reload.confirmed?
  end

  test 'deletes pending join requests when reopening' do
    course = create(:course, grouping_enabled: true, grouping_open: true)
    group = create(:project_group, course: course, confirmed: true, group_name: 'G001')
    student = create(:user)
    create(:enrolment, :student, course: course, user: student)
    create(:project_group_invite, project_group: group, sender: student, recipient: student, status: :pending)

    assert_equal 1, group.project_group_invites.direct_request.pending.count

    result = Groups::Coordinator::Reopener.new(group).reopen!

    assert result.reopened?
    assert_equal 0, group.project_group_invites.direct_request.pending.count
  end

  test 'blocks reopening when already not confirmed' do
    course = create(:course, grouping_enabled: true, grouping_open: true)
    group = create(:project_group, course: course, confirmed: false, group_name: 'Tmp001')

    result = Groups::Coordinator::Reopener.new(group).reopen!

    assert_not result.reopened?
    assert_equal :already_not_confirmed, result.blocked_reason
    assert_equal 'This group is already not confirmed.', result.message
  end

  test 'blocks reopening an imported group' do
    course = create(:course, grouping_enabled: true, grouping_open: true)
    group = create(:project_group, :imported, course: course, confirmed: true, group_name: 'Team Import')

    result = Groups::Coordinator::Reopener.new(group).reopen!

    assert_not result.reopened?
    assert_equal :imported_group, result.blocked_reason
    assert_equal 'This group was imported, so it cannot be reopened.', result.message
  end

  test 'blocks reopening a group with a project' do
    course = create(:course, grouping_enabled: true, grouping_open: true)
    group = create(:project_group, course: course, confirmed: true, group_name: 'G001')
    supervisor = create(:enrolment, :lecturer, course: course)
    Project.create!(course: course, owner: group, supervisor_enrolment: supervisor)

    result = Groups::Coordinator::Reopener.new(group).reopen!

    assert_not result.reopened?
    assert_equal :has_project, result.blocked_reason
    assert_equal 'This group already has a proposal, so it cannot be reopened.', result.message
  end
end
