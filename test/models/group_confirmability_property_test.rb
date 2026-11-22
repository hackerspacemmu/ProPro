require 'test_helper'

class GroupConfirmabilityPropertyTest < ActiveSupport::TestCase
  test 'random group confirmation orders keep the unconfirmed students confirmable' do
    confirmability_configs.each do |group_min, group_max, student_count, seed|
      course = create(:course, :grouped, group_formation_enabled: true, prevent_leftover_students: true,
                                         group_min: group_min, group_max: group_max)
      create_list(:enrolment, student_count, course: course, role: :student)
      students = course.students.to_a
      random = Random.new(seed)

      groups = random_group_sizes(random, student_count, group_max).map do |size|
        group = create(:project_group, course: course)
        students.shift(size).each { |student| create(:project_group_member, project_group: group, user: student) }
        group
      end

      assert feasible?(course.unconfirmed_students_count, group_min, group_max),
             "initial count #{student_count} is infeasible (min=#{group_min}, max=#{group_max})"

      confirmed = 0
      groups.shuffle(random: random).each do |group|
        next unless group.confirmable?

        result = GroupConfirmer.new(group).confirm!
        assert result.confirmed?,
               "group #{group.id} was confirmable but confirmation was blocked (min=#{group_min}, max=#{group_max}, seed=#{seed})"
        confirmed += 1

        remaining = course.unconfirmed_students_count
        assert remaining.zero? || feasible?(remaining, group_min, group_max),
               "confirming group #{group.id} left #{remaining} students ungroupable (min=#{group_min}, max=#{group_max}, seed=#{seed})"
      end

      assert confirmed.positive?,
             "no group was confirmable (min=#{group_min}, max=#{group_max}, seed=#{seed})"
    end
  end

  private

  def confirmability_configs
    [
      [2, 4, 10, 11],
      [2, 5, 17, 2026],
      [3, 6, 24, 7],
      [1, 3, 11, 99],
      [4, 4, 12, 5]
    ]
  end

  def random_group_sizes(random, total, group_max)
    sizes = []
    remaining = total

    while remaining.positive?
      size = random.rand(1..[group_max, remaining].min)
      sizes << size
      remaining -= size
    end

    sizes
  end

  def feasible?(count, group_min, group_max)
    count.zero? || (1..count).any? { |groups| count.between?(groups * group_min, groups * group_max) }
  end
end
