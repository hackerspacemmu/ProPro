# Applies a coordinator's batch of lecturer capacity offset/exclusion changes
# for a course. Validates every row against a single base-capacity snapshot
# before persisting anything, so no row's validation depends on another row
# already having been saved earlier in the same request.
class SupervisorCapacityUpdater
  class Result
    attr_reader :course, :errors

    def initialize(updated:, course:, errors: [])
      @updated = updated
      @course = course
      @errors = errors
    end

    def updated?
      @updated
    end
  end

  def initialize(course)
    @course = course
  end

  def update_capacities(offsets:, excluded_ids:)
    @offsets = offsets
    @excluded_ids = excluded_ids.map(&:to_s)
    errors = []

    base = base_capacity
    targets = load_targets

    targets.each_value { |enrolment| errors.concat(check(enrolment, base)) }

    if errors.any?
      Result.new(updated: false, course: @course, errors: errors)
    else
      persist(targets)
      Result.new(updated: true, course: @course)
    end
  end

  private

  def base_capacity
    SupervisorCapacityCalculator.new(@course).calculate.base
  end

  def load_targets
    ids = (@offsets.keys.map(&:to_s) + @excluded_ids).uniq
    @course.enrolments.where(id: ids, role: :lecturer).index_by { |e| e.id.to_s }
  end

  def check(enrolment, base)
    id = enrolment.id.to_s

    enrolment.supervisor_capacity_offset = @offsets[id].to_i if @offsets.key?(id)
    enrolment.supervisor_capacity_excluded = @excluded_ids.include?(id)

    return [] if enrolment.supervisor_capacity_excluded?
    return [] if base + enrolment.supervisor_capacity_offset > 0

    ["#{enrolment.user.name}'s offset would result in negative or zero capacity."]
  end

  def persist(targets)
    ActiveRecord::Base.transaction do
      targets.each_value { |enrolment| enrolment.save!(validate: false) }
    end
  end
end
