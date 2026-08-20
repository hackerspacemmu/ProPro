module Queries
  # (student_list_finalized) uses quota model to determine the confirmability of group size
  # SEE https://docs.google.com/document/d/1RZAhO7-9Al2Ak3rKhHmnLZyvXfej_J7hyZw7ZYmmXng/edit?usp=sharing for more context
  # OR (default mode) group size within min/max.
  class GroupSizeConfirmabilityCalculator
    def initialize(course, students_to_group:)
      @course = course
      @students_to_group = students_to_group
    end

    def execute
      group_min = @course.group_min
      group_max = @course.group_max

      return blank_result(:group_size_limits_not_configured) if group_min.blank? || group_max.blank?

      if @course.student_list_finalised?
        return blank_result(:no_students_to_group) if @students_to_group <= 0

        execute_quota(group_min, group_max)
      else
        execute_min_max(group_min, group_max)
      end
    end

    def self.feasible_count?(count, group_min, group_max)
      return true if count.zero?
      return false if count.negative?

      k = (count.to_f / group_max).ceil
      (count / k) >= group_min
    end

    private

    def blank_result(error)
      Result.new(found: false, breakdown: [], group_count: 0, error: error)
    end

    # Auto-Confirmability mode
    def execute_quota(group_min, group_max)
      k = (@students_to_group.to_f / group_max).ceil
      base = @students_to_group / k
      rem = @students_to_group % k

      return blank_result(:no_legal_combination_exists) if base < group_min

      breakdown = []
      breakdown << { group_size: base + 1, number_of_groups: rem } if rem.positive?
      breakdown << { group_size: base, number_of_groups: k - rem } if (k - rem).positive?
      breakdown.sort_by! { |entry| -entry[:group_size] }

      Result.new(found: true, breakdown: breakdown, group_count: k, error: nil,
                 group_min: group_min, group_max: group_max,
                 students_to_group: @students_to_group, finalised: true)
    end

    # Default mode
    def execute_min_max(group_min, group_max)
      breakdown = (group_min..group_max).map { |size| { group_size: size, number_of_groups: nil } }
      Result.new(found: true, breakdown: breakdown, group_count: nil, error: nil,
                 group_min: group_min, group_max: group_max,
                 students_to_group: @students_to_group, finalised: false)
    end

    class Result
      attr_reader :breakdown, :group_count, :error

      def initialize(found:, breakdown:, group_count:, error:,
                      group_min: nil, group_max: nil, students_to_group: nil, finalised: nil)
        @found = found
        @breakdown = breakdown
        @group_count = group_count
        @error = error
        @group_min = group_min
        @group_max = group_max
        @students_to_group = students_to_group
        @finalised = finalised
      end

      def found? = @found
      def success? = @error.nil?
      def error? = !success?

      def confirmable_size?(size)
        return false unless found?
        return false unless (@group_min..@group_max).cover?(size)
        return true unless @finalised

        remainder = @students_to_group - size
        GroupSizeConfirmabilityCalculator.feasible_count?(remainder, @group_min, @group_max)
      end

      def message
        case error
        when :group_size_limits_not_configured then 'Group size limits are not set for this course.'
        when :no_students_to_group then 'Enter a student count greater than 0.'
        when :no_legal_combination_exists then 'No legal group size combination exists for this number of students.'
        end
      end
    end
  end
end