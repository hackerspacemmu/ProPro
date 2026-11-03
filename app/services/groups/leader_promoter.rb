module Groups
  # Makes an existing member the group leader. Leader-initiated, so it only
  # applies while formation is open and the group is not confirmed.
  class LeaderPromoter
    def initialize(group, target_user_id:)
      @group = group
      @target_user_id = target_user_id
    end

    def promote!
      @group.with_lock do
        return blocked(:window_closed) unless @group.course.grouping_window_open?
        return blocked(:group_confirmed) if @group.confirmed?

        member = @group.project_group_members.find_by(user_id: @target_user_id)
        return blocked(:not_a_member) unless member

        @group.update!(leader_id: member.user_id)
        Result.new(promoted: true, member: member)
      end
    end

    private

    def blocked(reason)
      Result.new(promoted: false, blocked_reason: reason)
    end

    class Result
      attr_reader :blocked_reason, :member

      def initialize(promoted:, blocked_reason: nil, member: nil)
        @promoted = promoted
        @blocked_reason = blocked_reason
        @member = member
      end

      def promoted? = @promoted
      def blocked? = !promoted?

      def message
        return "#{member.user.name} is now the group leader." if promoted?

        case blocked_reason
        when :window_closed then 'Group formation is closed.'
        when :group_confirmed then 'The leader can only be changed while the group is not confirmed.'
        when :not_a_member then 'That student is not a member of this group.'
        end
      end
    end
  end
end
