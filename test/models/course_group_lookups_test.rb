require 'test_helper'

class CourseGroupLookupsTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped)
    @other_course = create(:course, :grouped)
    @grouped = create(:user, name: 'Zoe Grouped')
    @ungrouped = create(:user, name: 'Amy Ungrouped')
    @lecturer = create(:user, name: 'Lee Lecturer')
    @grouped_elsewhere = create(:user, name: 'Bob Elsewhere')
    @group = create(:project_group, course: @course, leader_id: @grouped.id)
    @other_group = create(:project_group, course: @other_course, leader_id: @grouped_elsewhere.id)

    create(:enrolment, course: @course, user: @grouped, role: :student)
    create(:enrolment, course: @course, user: @ungrouped, role: :student)
    create(:enrolment, course: @course, user: @lecturer, role: :lecturer)
    create(:enrolment, course: @other_course, user: @grouped_elsewhere, role: :student)
    create(:project_group_member, project_group: @group, user: @grouped)
    create(:project_group_member, project_group: @other_group, user: @grouped_elsewhere)
  end

  test 'group_for returns the user group in this course' do
    assert_equal @group, @course.group_for(@grouped)
  end

  test 'group_for returns nil for an ungrouped student' do
    assert_nil @course.group_for(@ungrouped)
  end

  test 'group_for ignores groups in other courses' do
    assert_nil @course.group_for(@grouped_elsewhere)
  end

  test 'ungrouped_students returns only students without a group in this course' do
    assert_equal [@ungrouped], @course.ungrouped_students.to_a
  end

  test 'ungrouped_students includes every student when no group exists' do
    @group.destroy!

    assert_equal [@ungrouped, @grouped], @course.ungrouped_students.to_a
  end
end
