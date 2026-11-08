module Groups
  # Removes a member at the leader's request. Only while formation is open and
  # the group is not confirmed; a leader cannot kick themselves.
  class Kicker
    include Groups::GroupLocking

    def initialize(member, current_user:)
      @member = member
      @current_user = current_user
      @group = member.project_group
    end

    def kick!
      result = with_group_lock(@group) do
        member = @group.project_group_members.find_by(id: @member.id)

        return blocked(:already_removed) unless member
        # Re-check inside the lock: a concurrent removal can replace the leader.
        return blocked(:not_leader) unless @group.leader?(@current_user)
        return blocked(:self_kick) if member.user_id == @current_user.id
        return blocked(:window_closed) unless @group.course.grouping_window_open?
        return blocked(:group_confirmed) if @group.confirmed?

        member.destroy!
        Result.new(removed: true)
      end

      return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

      result
    end

    private

    def blocked(reason)
      Result.new(removed: false, blocked_reason: reason)
    end

    class Result
      attr_reader :blocked_reason

      def initialize(removed:, blocked_reason: nil)
        @removed = removed
        @blocked_reason = blocked_reason
      end

      def removed? = @removed
      def blocked? = !removed?
      def needs_confirmation? = false

      def message
        return 'Member removed.' if removed?

        case blocked_reason
        when :already_removed then 'This member has already been removed.'
        when :not_leader then 'Only the group leader can remove members.'
        when :self_kick then 'You cannot remove yourself from the group.'
        when :window_closed then 'Group formation is closed.'
        when :group_confirmed then 'The leader can only remove members while the group is not confirmed.'
        when :group_gone then 'This group no longer exists.'
        end
      end
    end
  end
end
