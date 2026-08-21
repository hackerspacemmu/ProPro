require 'test_helper'

class GroupSizeConfirmabilityCalculatorTest < ActiveSupport::TestCase
  test 'confirmable_size? is true when size is within min/max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when size is below min in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 3, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.confirmable_size?(2)
  end

  test 'confirmable_size? is false when size exceeds max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 3)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.confirmable_size?(4)
  end

  test 'confirmable_size? is true when size appears in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when size does not appear in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert_not result.confirmable_size?(2)
  end

  test 'result is not found when no legal distribution exists' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 4, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert_not result.found?
  end

  test 'breakdown has a single entry, not two, when students divide evenly into group_max' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    # 8 students / max 4 => k=2, base=4, rem=0 — should yield ONE breakdown entry of {size: 4, count: 2}
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 8).execute

    assert result.found?
    assert_equal 1, result.breakdown.length
    assert_equal({ group_size: 4, number_of_groups: 2 }, result.breakdown.first)
  end


  test 'confirmable_size? is true for the size that exactly empties the remaining pool' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    # only one group's worth of students left to place
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 3).execute

    assert result.confirmable_size?(3)
  end


  test 'confirmable_size? is false when confirming this size strands an unconfirmable remainder' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    # 5 students to place; confirming a group of 4 leaves 1 student stranded (below group_min of 3)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 5).execute

    assert_not result.confirmable_size?(4)
  end

  test 'feasible_count? is true for a zero remainder' do
    assert Queries::GroupSizeConfirmabilityCalculator.feasible_count?(0, 2, 4)
  end

  test 'feasible_count? is false for a negative remainder' do
    assert_not Queries::GroupSizeConfirmabilityCalculator.feasible_count?(-1, 2, 4)
  end

  test 'default mode allows a confirmable size even when the course has far fewer students than that' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 1).execute

    assert result.confirmable_size?(4)
  end
end