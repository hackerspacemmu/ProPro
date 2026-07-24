module Queries
  class SupervisorCapacityCalculator
    class Result
      attr_reader :base, :remainder, :total, :manual_value, :auto_calculated, :lecturer_capacities

      def initialize(base:, remainder:, total:, manual_value:, auto_calculated:, lecturer_capacities:)
        @base = base
        @remainder = remainder
        @total = total
        @manual_value = manual_value
        @auto_calculated = auto_calculated
        @lecturer_capacities = lecturer_capacities
      end

      def auto_calculated?
        @auto_calculated
      end
    end

    class LecturerCapacity
      attr_reader :enrolment, :offset, :approved_count, :pending_count, :effective_cap

      def initialize(enrolment:, offset:, approved_count:, pending_count:, effective_cap:)
        @enrolment = enrolment
        @offset = offset
        @approved_count = approved_count
        @pending_count = pending_count
        @effective_cap = effective_cap
      end

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

    def initialize(course, lecturer_enrolments: nil)
      @course = course
      @lecturer_enrolments = lecturer_enrolments
    end

    def execute
      base, remainder, total = base_remainder_and_total

      capacities = lecturer_enrolments.map { |enrolment| build_lecturer_capacity(enrolment, base) }

      Result.new(
        base: base, remainder: remainder, total: total,
        manual_value: @course.supervisor_projects_limit,
        auto_calculated: @course.supervisor_auto_calculate_enabled?,
        lecturer_capacities: capacities
      )
    end

    private

    def lecturer_enrolments
      @lecturer_enrolments ||= @course.enrolments.where(role: :lecturer).includes(:user).to_a
    end

    def base_remainder_and_total
      return [@course.supervisor_projects_limit, 0, nil] unless @course.supervisor_auto_calculate_enabled?

      total = @course.grouped? ? @course.project_groups.count : @course.projects.where(owner_type: 'User').count
      eligible = lecturer_enrolments.reject(&:supervisor_capacity_excluded?)
      return [0, 0, total] if eligible.empty?

      positive_offset_sum = eligible.sum { |e| [e.supervisor_capacity_offset, 0].max }
      adjusted_total = total - positive_offset_sum
      [adjusted_total / eligible.count, adjusted_total % eligible.count, total]
    end

    def build_lecturer_capacity(enrolment, base)
      approved = @course.projects.supervised_by(enrolment).approved.count
      pending  = @course.projects.supervised_by(enrolment).pending_redo.count

      effective_cap = enrolment.supervisor_capacity_excluded? ? 0 : base + enrolment.supervisor_capacity_offset

      LecturerCapacity.new(
        enrolment: enrolment,
        offset: enrolment.supervisor_capacity_offset,
        approved_count: approved,
        pending_count: pending,
        effective_cap: effective_cap
      )
    end
  end
end