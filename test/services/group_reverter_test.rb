require 'test_helper'

class GroupReverterTest < ActiveSupport::TestCase
  test 'reverts a confirmed group to draft' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)

    result = GroupReverter.new(group).revert!

    assert result.reverted?
    assert_not group.reload.confirmed?
  end

  test 'blocks with window_closed when grouping window is closed' do
    course = create(:course, grouping_enabled: true, grouping_closes_at: 1.hour.ago, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocks with already_draft when group is already draft' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :already_draft, result.blocked_reason
  end

  test 'blocks with imported_group when the group was imported' do
    course = create(:course, :grouped, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, :imported, course: course)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :imported_group, result.blocked_reason
    assert_equal 'This group was imported, so it cannot be reopened.', result.message
    assert group.reload.confirmed?
  end

  test 'blocks with has_project when the group already has a project' do
    course = create(:course, :grouped, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: course)
    Project.create!(course: course, owner: group, supervisor_enrolment: supervisor)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :has_project, result.blocked_reason
    assert group.reload.confirmed?
  end

  test 'reopening gives the group the lowest free temporary number' do
    course = create(:course, :grouped, grouping_enabled: true,
                                       student_list_finalised: false, group_min: 2, group_max: 4)
    group = create(:project_group, course: course, group_name: 'G002', confirmed: true)

    result = GroupReverter.new(group).revert!

    assert result.reverted?
    assert_equal 'Tmp001', group.reload.group_name
  end

  test 'reopening frees the confirmed number for the next confirmation' do
    course = create(:course, :grouped, grouping_enabled: true,
                                       student_list_finalised: false, group_min: 2, group_max: 4)
    create(:project_group, course: course, group_name: 'G001', confirmed: true)
    group = create(:project_group, course: course, group_name: 'G002', confirmed: true)
    create_list(:project_group_member, 3, project_group: group)

    GroupReverter.new(group).revert!
    assert_equal 'Tmp001', group.reload.group_name

    result = GroupConfirmer.new(group).confirm!

    assert result.confirmed?
    assert_equal 'G002', group.reload.group_name
  end

  test 'reopening clears the group\'s pending join requests but keeps pending invites' do
    course = create(:course, :grouped, grouping_enabled: true,
                                       student_list_finalised: false, group_min: 2, group_max: 4)
    group = create(:project_group, course: course, confirmed: true)
    request = create(:project_group_invite, project_group: group, kind: :direct_request, status: :pending)
    invite  = create(:project_group_invite, project_group: group, kind: :direct_invite, status: :pending)

    result = GroupReverter.new(group).revert!

    assert result.reverted?
    assert_not ProjectGroupInvite.exists?(request.id)
    assert ProjectGroupInvite.exists?(invite.id)
  end
end
