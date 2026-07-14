# Runs on every group trying to confirm to determine it's legality
class GroupSizeLegalityCalculator
  def initialize(course:)
    @course = course
  end

  def calculate_distribution(students_to_group:)
    group_min = @course.group_min
    group_max = @course.group_max

    if group_min.blank? || group_max.blank?
      return Result.new(found: false, breakdown: [], group_count: 0, error: :group_size_limits_not_configured)
    end

    if students_to_group <= 0
      return Result.new(found: false, breakdown: [], group_count: 0, error: :no_students_to_group)
    end

    allowed_sizes_largest_first = group_max.downto(group_min).to_a
    cache = {}

    chosen_size = find_group_size_for(students_to_group, allowed_sizes_largest_first, cache)

    if chosen_size.nil?
      return Result.new(found: false, breakdown: [], group_count: 0, error: :no_legal_combination_exists)
    end

    sizes_chosen = []
    students_remaining = students_to_group

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

  private

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

    def found?
      @found
    end

    # The actual legality check GroupConfirmer will call.
    def includes_group_of_size?(size)
      return false unless found?

      breakdown.any? { |entry| entry[:group_size] == size }
    end
  end
end