# app/services/supervisor_capacity_calculator.rb
#
# Computes per-lecturer effective capacity for a course in a single pass
# one call handles the whole roster, since every real call site (course show,settings page)
# needs every lecturer's numbers, not one in isolation.
class SupervisorCapacityCalculator
  Result = Struct.new(:base, :remainder, :manual_value, :auto_calculated, :lecturer_capacities, keyword_init: true)

  LecturerCapacity = Struct.new(:enrolment, :offset, :approved_count, :pending_count, :effective_cap, keyword_init: true) do
    def excluded?
      enrolment.supervisor_capacity_excluded?
    end

    def at_capacity?
      approved_count >= effective_cap
    end

    def remaining
      [effective_cap - approved_count, 0].max
    end

    def total_proposals
      approved_count + pending_count
    end
  end

  def initialize(course)
    @course = course
  end

  def calculate
    base, remainder = base_and_remainder

    lecturer_capacities = @course.enrolments.where(role: :lecturer).includes(:user).map do |enrolment|
      build_lecturer_capacity(enrolment, base)
    end

    Result.new(
      base: base,
      remainder: remainder,
      manual_value: @course.supervisor_projects_limit,
      auto_calculated: @course.supervisor_auto_calculate_enabled?,
      lecturer_capacities: lecturer_capacities
    )
  end

  private

  def base_and_remainder
    if @course.supervisor_auto_calculate_enabled?
      result = @course.auto_calculate_capacity
      [result[:base], result[:remainder]]
    else
      [@course.supervisor_projects_limit, 0]
    end
  end

  def build_lecturer_capacity(enrolment, base)
    approved = @course.projects.supervised_by(enrolment).approved.count
    pending  = @course.projects.supervised_by(enrolment).pending_redo.count

    effective_cap =
      if enrolment.supervisor_capacity_excluded?
        0
      elsif @course.supervisor_variable_capacity_enabled?
        base + enrolment.supervisor_capacity_offset
      else
        base
      end

    LecturerCapacity.new(
      enrolment: enrolment,
      offset: enrolment.supervisor_capacity_offset,
      approved_count: approved,
      pending_count: pending,
      effective_cap: effective_cap
    )
  end
end