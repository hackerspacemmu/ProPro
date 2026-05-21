# test/models/project_group_grouping_test.rb

require 'test_helper'

class ProjectGroupGroupingTest < ActiveSupport::TestCase
  # can_confirm? — default mode

  test 'can_confirm? returns true when member count is within min/max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)
    assert group.can_confirm?
  end

  test 'can_confirm? returns false when member count is below min in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 3, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 2, project_group: group)
    assert_not group.can_confirm?
  end

  test 'can_confirm? returns false when member count exceeds max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 3)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 4, project_group: group)
    assert_not group.can_confirm?
  end

  # can_confirm? — fixed list mode

  test 'can_confirm? returns true when group size appears in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    # Enrol 7 students — legal distribution is [4, 3]
    create_list(:enrolment, 7, course: course, role: :student)
    group = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)
    assert group.can_confirm?
  end

  test 'can_confirm? returns false when group size does not appear in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    # Enrol 7 students — legal distribution is [4, 3], size 2 is not legal
    create_list(:enrolment, 7, course: course, role: :student)
    group = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 2, project_group: group)
    assert_not group.can_confirm?
  end

  test 'can_confirm? returns false when no legal distribution exists' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 4, group_max: 4)
    # Enrol 7 students — no legal distribution exists for groups of exactly 4
    create_list(:enrolment, 7, course: course, role: :student)
    group = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 4, project_group: group)
    assert_not group.can_confirm?
  end

  # confirm!

  test 'confirm! sets confirmed to true when can_confirm? is true' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)
    assert group.confirm!
    assert group.reload.confirmed?
  end

  test 'confirm! returns false and does not update when can_confirm? is false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 3, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 1, project_group: group)
    assert_not group.confirm!
    assert_not group.reload.confirmed?
  end

  # revert_to_draft!

  test 'revert_to_draft! sets confirmed to false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)
    group.revert_to_draft!
    assert_not group.reload.confirmed?
  end
end
