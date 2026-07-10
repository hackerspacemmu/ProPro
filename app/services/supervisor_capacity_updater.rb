class SupervisorCapacityUpdater
  class Result
    attr_reader :course, :errors

    def initialize(updated:, course:, errors: [])
      @updated = updated
      @course = course
      @errors = errors
    end

    def updated? = @updated
  end

  def initialize(course)
    @course = course
  end

  def update_capacities(offsets:, excluded_ids:)
    excluded_ids = excluded_ids.map(&:to_s)
    errors = []

    all_lecturers = @course.enrolments.where(role: :lecturer).to_a

    all_lecturers.each do |enrolment|
      id = enrolment.id.to_s
      next unless offsets.key?(id) || excluded_ids.include?(id)

      enrolment.supervisor_capacity_offset = offsets[id].to_i if offsets.key?(id)
      enrolment.supervisor_capacity_excluded = excluded_ids.include?(id)
    end

    base = SupervisorCapacityCalculator.new(@course, lecturer_enrolments: all_lecturers).calculate.base

    targets = all_lecturers.select { |e| offsets.key?(e.id.to_s) || excluded_ids.include?(e.id.to_s) }
    targets.each { |enrolment| errors.concat(check(enrolment, base)) }

    if errors.any?
      Result.new(updated: false, course: @course, errors: errors)
    else
      persist(targets)
      Result.new(updated: true, course: @course)
    end
  end

  private

  def check(enrolment, base)
    return [] if enrolment.supervisor_capacity_excluded?
    return [] if base + enrolment.supervisor_capacity_offset > 0

    ["#{enrolment.user.name}'s offset would result in negative or zero capacity."]
  end

  def persist(targets)
    ActiveRecord::Base.transaction { targets.each { |e| e.save!(validate: false) } }
  end
end
