module Groups
  # Sets whether joining this group requires leader approval. Leader-initiated,
  # so it only applies while formation is open and the group is not confirmed.
  class ApprovalToggler
    def initialize(group, locked:)
      @group = group
      @locked = locked
    end

    def set!
      @group.with_lock do
        return blocked(:window_closed) unless @group.course.grouping_window_open?
        return blocked(:group_confirmed) if @group.confirmed?
        return blocked(:no_leader) if @locked && @group.leader_id.blank?

        @group.update!(locked: @locked)
        Result.new(updated: true, locked: @locked)
      end
    end

    private

    def blocked(reason)
      Result.new(updated: false, blocked_reason: reason, locked: @locked)
    end

    class Result
      attr_reader :blocked_reason

      def initialize(updated:, locked:, blocked_reason: nil)
        @updated = updated
        @locked = locked
        @blocked_reason = blocked_reason
      end

      def updated? = @updated
      def blocked? = !updated?

      def message
        return (@locked ? 'This group now requires approval to join.' : 'This group no longer requires approval to join.') if updated?

        case blocked_reason
        when :window_closed then 'Group formation is closed.'
        when :group_confirmed then 'Approval can only be changed while the group is not confirmed.'
        when :no_leader then 'Assign a leader before requiring approval.'
        end
      end
    end
  end
end
