require 'test_helper'

class GroupReverterTest < ActiveSupport::TestCase
  test 'reverts a confirmed group to draft' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)

    result = GroupReverter.new(group).revert!

    assert result.reverted?
    assert_not group.reload.confirmed?
  end

  test 'blocks with window_closed when grouping window is closed' do
    course = create(:course, grouping_enabled: true, grouping_open: false, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocks with already_draft when group is already draft' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :already_draft, result.blocked_reason
  end

  test 'blocks with imported_group when the group was imported' do
    course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, :imported, course: course)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :imported_group, result.blocked_reason
    assert_equal 'This group was imported, so it cannot be reopened.', result.message
    assert group.reload.confirmed?
  end

  test 'blocks with has_project when the group already has a project' do
    course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: course)
    Project.create!(course: course, owner: group, supervisor_enrolment: supervisor)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :has_project, result.blocked_reason
    assert group.reload.confirmed?
  end
end
