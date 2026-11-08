module Groups
  # Removes a member who is leaving their own group. A confirmed group keeps
  # every member, and a group that owns a proposal is never left here.
  class Leaver
    include Groups::GroupLocking

    def initialize(member)
      @member = member
      @group = member.project_group
    end

    def leave!
      result = with_group_lock(@group) do
        member = @group.project_group_members.find_by(id: @member.id)

        return blocked(:already_removed) unless member
        return blocked(:window_closed) unless @group.course.grouping_window_open?
        return blocked(:group_confirmed) if @group.confirmed?
        return blocked(:has_project) if @group.project.present?

        was_leader = @group.leader?(member.user)
        member.destroy!

        if @group.project_group_members.none?
          @group.destroy!
          return Result.new(outcome: :group_deleted)
        end

        promote_next_leader! if was_leader
        Result.new(outcome: :removed)
      end

      return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

      result
    end

    private

    def promote_next_leader!
      successor = @group.project_group_members.order(:created_at, :id).first
      @group.update!(leader_id: successor.user_id)
    end

    def blocked(reason)
      Result.new(outcome: :blocked, blocked_reason: reason)
    end

    class Result
      attr_reader :outcome, :blocked_reason

      def initialize(outcome:, blocked_reason: nil)
        @outcome = outcome
        @blocked_reason = blocked_reason
      end

      def removed? = outcome == :removed
      def group_deleted? = outcome == :group_deleted
      def blocked? = outcome == :blocked
      def needs_confirmation? = false

      def message
        return blocked_message if blocked?

        if group_deleted?
          'You left, and the group was deleted because it had no remaining members.'
        else
          'You have left the group.'
        end
      end

      private

      def blocked_message
        case blocked_reason
        when :already_removed then 'This member has already been removed.'
        when :window_closed then 'Group formation is closed.'
        when :group_confirmed then 'You cannot leave a confirmed group.'
        when :has_project then 'This group has a proposal, so only a coordinator can remove members.'
        when :group_gone then 'This group no longer exists.'
        end
      end
    end
  end
end
