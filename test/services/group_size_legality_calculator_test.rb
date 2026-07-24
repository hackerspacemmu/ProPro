require 'test_helper'

class GroupSizeLegalityCalculatorTest < ActiveSupport::TestCase
  test 'includes_group_of_size? is true when size is within min/max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    result = Queries::GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
    assert result.includes_group_of_size?(3)
  end

  test 'includes_group_of_size? is false when size is below min in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 3, group_max: 4)
    result = Queries::GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.includes_group_of_size?(2)
  end

  test 'includes_group_of_size? is false when size exceeds max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 3)
    result = Queries::GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.includes_group_of_size?(4)
  end

  test 'includes_group_of_size? is true when size appears in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
    assert result.includes_group_of_size?(3)
  end

  test 'includes_group_of_size? is false when size does not appear in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.includes_group_of_size?(2)
  end

  test 'result is not found when no legal distribution exists' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 4, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.found?
  end
end