module Groups
  # Revokes the group's shareable invite link on its leader's request.
  class InviteLinkDisabler
    include Groups::GroupLocking

    def initialize(group)
      @group = group
    end

    def disable!
      result = with_group_lock(@group) do
        return blocked(:formation_closed) unless @group.course.group_formation_open?

        @group.project_group_invite_links.delete_all
        Result.new(disabled: true)
      end

      return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

      result
    end

    private

    def blocked(reason)
      Result.new(disabled: false, blocked_reason: reason)
    end

    # Outcome of a disable attempt, with the flash copy for either path.
    class Result
      attr_reader :blocked_reason

      def initialize(disabled:, blocked_reason: nil)
        @disabled = disabled
        @blocked_reason = blocked_reason
      end

      def disabled? = @disabled
      def blocked? = !disabled?

      def message
        return 'Invite link disabled.' if disabled?

        case blocked_reason
        when :formation_closed then 'Group formation is closed.'
        when :group_gone then 'This group no longer exists.'
        end
      end
    end
  end
end
