require 'test_helper'

class GroupConfirmerTest < ActiveSupport::TestCase
  test 'confirms a group when member count is within min/max in default mode' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert result.confirmed?
    assert group.reload.confirmed?
  end

  test 'blocks with size_illegal when member count is below min in default mode' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 3, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 1, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :size_illegal, result.blocked_reason
    assert_not group.reload.confirmed?
  end

  test 'confirms a group when size appears in legal distribution' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    group = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert result.confirmed?
  end

  test 'blocks with size_illegal when size does not appear in legal distribution' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    group = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 2, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :size_illegal, result.blocked_reason
  end

  test 'blocks with window_closed when grouping window is closed' do
    course = create(:course, grouping_enabled: true, grouping_open: false, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocks with already_confirmed when group is already confirmed' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :already_confirmed, result.blocked_reason
  end
end