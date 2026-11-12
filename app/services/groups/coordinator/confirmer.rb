module Groups
  module Coordinator
    # Confirms an unconfirmed group on behalf of a coordinator, bypassing the
    # formation open/closed state and overriding size limits.
    class Confirmer
      include Groups::GroupLocking

      def initialize(group)
        @group = group
      end

      def confirm!
        course = @group.course

        result = course.with_no_key_update_lock do
          with_group_lock(@group) do
            return blocked(:already_confirmed) if @group.confirmed?

            old_name = @group.group_name.presence || "Group #{@group.id}"
            new_name = course.lowest_free_confirmed_group_name(excluding: @group)

            @group.update!(confirmed: true, group_name: new_name)
            @group.clear_invite_links!
            Result.new(confirmed: true, old_name: old_name, new_name: new_name)
          end
        end

        return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

        result
      end

      private

      def blocked(reason)
        Result.new(confirmed: false, blocked_reason: reason)
      end

      class Result
        attr_reader :old_name, :new_name, :blocked_reason

        def initialize(confirmed:, old_name: nil, new_name: nil, blocked_reason: nil)
          @confirmed = confirmed
          @old_name = old_name
          @new_name = new_name
          @blocked_reason = blocked_reason
        end

        def confirmed? = @confirmed

        def message
          return "#{old_name} is now confirmed as #{new_name}." if confirmed?

          case blocked_reason
          when :already_confirmed then 'This group has already been confirmed.'
          when :group_gone then 'This group no longer exists.'
          end
        end
      end
    end
  end
end
