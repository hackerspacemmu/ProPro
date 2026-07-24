module Queries
  # Determines whether a given number of students can be split into legal group sizes for a course,
  # OR (default mode) simply whether a single group's size falls within min/max.
  class GroupSizeLegalityCalculator
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
        execute_dp(group_min, group_max)
      else
        execute_min_max(group_min, group_max)
      end
    end

    private

    def blank_result(error)
      Result.new(found: false, breakdown: [], group_count: 0, error: error)
    end

    # Fixed-list mode: legality is calculated per group using the live enrolled students count
    def execute_dp(group_min, group_max)
      allowed_sizes_largest_first = group_max.downto(group_min).to_a
      cache = {}

      chosen_size = find_group_size_for(@students_to_group, allowed_sizes_largest_first, cache)
      return blank_result(:no_legal_combination_exists) if chosen_size.nil?

      sizes_chosen = []
      students_remaining = @students_to_group

      while students_remaining.positive?
        size = cache.fetch(students_remaining)
        sizes_chosen << size
        students_remaining -= size
      end

      breakdown = sizes_chosen
                  .tally
                  .map { |size, count| { group_size: size, number_of_groups: count } }
                  .sort_by { |entry| -entry[:group_size] }

      Result.new(found: true, breakdown: breakdown, group_count: sizes_chosen.length, error: nil)
    end

    # Default mode: no distribution, no enrolled-count dependency. A size is legal if it's within [group_min, group_max].
    # Does not utilize students_to_group, but passed parameter for Fixed-list mode
    def execute_min_max(group_min, group_max)
      breakdown = (group_min..group_max).map { |size| { group_size: size, number_of_groups: nil } }
      Result.new(found: true, breakdown: breakdown, group_count: nil, error: nil)
    end

    def find_group_size_for(students_remaining, allowed_sizes_largest_first, cache)
      return 0 if students_remaining.zero?
      return cache[students_remaining] if cache.key?(students_remaining)

      allowed_sizes_largest_first.each do |size|
        next if size > students_remaining

        remainder_result = find_group_size_for(students_remaining - size, allowed_sizes_largest_first, cache)
        next if remainder_result.nil?

        cache[students_remaining] = size
        return size
      end

      cache[students_remaining] = nil
      nil
    end

    class Result
      attr_reader :breakdown, :group_count, :error

      def initialize(found:, breakdown:, group_count:, error:)
        @found = found
        @breakdown = breakdown
        @group_count = group_count
        @error = error
      end

      def found? = @found
      def success? = @error.nil?
      def error? = !success?

      def includes_group_of_size?(size)
        return false unless found?

        breakdown.any? { |entry| entry[:group_size] == size }
      end
    end
  end
end