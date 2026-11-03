module Groups
  module Coordinator
    # Sets whether joining this group requires leader approval in any state.
    class ApprovalToggler
      def initialize(group, locked:)
        @group = group
        @locked = locked
      end

      def set!
        @group.with_lock do
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

          'Assign a leader before requiring approval.' if blocked_reason == :no_leader
        end
      end
    end
  end
end
