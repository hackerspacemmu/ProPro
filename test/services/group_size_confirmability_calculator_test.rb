require 'test_helper'

class GroupSizeConfirmabilityCalculatorTest < ActiveSupport::TestCase
  test 'confirmable_size? is true when size is within min/max in default mode' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when size is below min in default mode' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: false, group_min: 3, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.confirmable_size?(2)
  end

  test 'confirmable_size? is false when size exceeds max in default mode' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: false, group_min: 2, group_max: 3)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.confirmable_size?(4)
  end

  test 'confirmable_size? is true when size appears in legal distribution' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when size does not appear in legal distribution' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert_not result.confirmable_size?(2)
  end

  test 'result is not found when no legal distribution exists' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: true, group_min: 4, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert_not result.found?
  end

  test 'breakdown has a single entry, not two, when students divide evenly into group_max' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    # 8 students / max 4 => k=2, base=4, rem=0 — should yield ONE breakdown entry of {size: 4, count: 2}
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 8).execute

    assert result.found?
    assert_equal 1, result.breakdown.length
    assert_equal({ group_size: 4, number_of_groups: 2 }, result.breakdown.first)
  end

  test 'confirmable_size? is true for the size that exactly empties the remaining pool' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    # only one group's worth of students left to place
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 3).execute

    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when confirming this size strands an unconfirmable remainder' do
    course = create(:course, group_formation_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
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
    course = create(:course, group_formation_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 1).execute

    assert result.confirmable_size?(4)
  end

  test 'feasible_count? matches an exhaustive search for a legal number of groups' do
    (1..8).each do |group_min|
      (group_min..12).each do |group_max|
        (0..100).each do |count|
          expected = feasible?(count, group_min, group_max)

          assert_equal expected,
                       Queries::GroupSizeConfirmabilityCalculator.feasible_count?(count, group_min, group_max),
                       "count=#{count}, min=#{group_min}, max=#{group_max}"
        end
      end
    end
  end

  test 'random confirm orders never leave an ungroupable remainder' do
    confirm_order_configs.each do |group_min, group_max, count, seed|
      course = build(:course, group_formation_enabled: true, student_list_finalised: true,
                              group_min: group_min, group_max: group_max)
      random = Random.new(seed)
      remaining = count

      assert feasible?(remaining, group_min, group_max),
             "initial count #{count} is infeasible (min=#{group_min}, max=#{group_max})"

      while remaining.positive?
        result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: remaining).execute
        confirmable_sizes = (group_min..group_max).select { |size| result.confirmable_size?(size) }

        assert_not_empty confirmable_sizes,
                         "#{remaining} students left with no confirmable size (min=#{group_min}, max=#{group_max}, seed=#{seed})"

        remaining -= confirmable_sizes.sample(random: random)

        assert remaining.zero? || Queries::GroupSizeConfirmabilityCalculator.feasible_count?(remaining, group_min, group_max),
               "confirming left #{remaining} students ungroupable (min=#{group_min}, max=#{group_max}, seed=#{seed})"
      end

      assert_equal 0, remaining
    end
  end

  test 'an infeasible student count has no confirmable size' do
    [[4, 4, 7], [3, 5, 1], [4, 4, 6]].each do |group_min, group_max, count|
      course = build(:course, group_formation_enabled: true, student_list_finalised: true,
                              group_min: group_min, group_max: group_max)
      result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: count).execute

      assert_not result.found?, "#{count} students should have no legal distribution (min=#{group_min}, max=#{group_max})"
      (group_min..group_max).each { |size| assert_not result.confirmable_size?(size) }
    end
  end

  private

  def confirm_order_configs
    [
      [1, 12, 100, 42],
      [2, 5, 10, 2026],
      [3, 4, 7, 7],
      [4, 8, 37, 1_234],
      [4, 4, 12, 99],
      [2, 3, 99, 12_345]
    ]
  end

  def feasible?(count, group_min, group_max)
    count.zero? || (1..count).any? { |groups| count.between?(groups * group_min, groups * group_max) }
  end
end
