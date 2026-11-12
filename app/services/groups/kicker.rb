module Groups
  # Removes a member at the leader's request. Only while formation is open and
  # the group is not imported or owned by a proposal; a leader cannot kick
  # themselves. Removing a member from a confirmed group reopens it.
  class Kicker
    include Groups::GroupLocking

    def initialize(member, current_user:)
      @member = member
      @current_user = current_user
      @group = member.project_group
    end

    def kick!
      result = @group.course.with_no_key_update_lock do
        with_group_lock(@group) do
          member = @group.project_group_members.find_by(id: @member.id)

          return blocked(:already_removed) unless member
          # Re-check inside the lock: a concurrent removal can replace the leader.
          return blocked(:not_leader) unless @group.leader?(@current_user)
          return blocked(:self_kick) if member.user_id == @current_user.id
          return blocked(:formation_closed) unless @group.course.group_formation_open?
          return blocked(:imported_group) if @group.origin_import?
          return blocked(:has_project) if @group.project.present?

          was_confirmed = @group.confirmed?
          removed_user = member.user
          member.destroy!
          new_name = @group.reopen! if was_confirmed

          Result.new(removed: true, reopened: was_confirmed, new_name: new_name,
                     removed_user: removed_user)
        end
      end

      return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

      notify_members_of_reopen(result.removed_user) if result.reopened?

      result
    end

    private

    def notify_members_of_reopen(removed_user)
      @group.users.find_each do |member|
        GeneralMailer.with(group: @group, removed_user: removed_user, recipient: member)
                     .Group_Reopened_Notification.deliver_later
      end
    end

    def blocked(reason)
      Result.new(removed: false, blocked_reason: reason)
    end

    class Result
      attr_reader :blocked_reason, :new_name, :removed_user

      def initialize(removed:, blocked_reason: nil, reopened: false, new_name: nil, removed_user: nil)
        @removed = removed
        @blocked_reason = blocked_reason
        @reopened = reopened
        @new_name = new_name
        @removed_user = removed_user
      end

      def removed? = @removed
      def reopened? = @reopened
      def blocked? = !removed?
      def needs_confirmation? = false

      def message
        return "Group reopened because #{removed_user.name} was removed." if reopened?
        return 'Member removed.' if removed?

        case blocked_reason
        when :already_removed then 'This member has already been removed.'
        when :not_leader then 'Only the group leader can remove members.'
        when :self_kick then 'You cannot remove yourself from the group.'
        when :formation_closed then 'Group formation is closed.'
        when :imported_group then 'This group was imported, so it cannot be reopened.'
        when :has_project then 'This group already has a proposal, so it cannot take new members.'
        when :group_gone then 'This group no longer exists.'
        end
      end
    end
  end
end
