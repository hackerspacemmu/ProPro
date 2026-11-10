module Groups
  module Coordinator
    # Reopens a confirmed group to not confirmed on behalf of a coordinator,
    # bypassing the grouping window while preserving imported and project guards.
    class Reopener
      include Groups::GroupLocking

      def initialize(group)
        @group = group
      end

      def reopen!
        course = @group.course

        result = course.with_no_key_update_lock do
          with_group_lock(@group) do
            return blocked(:already_not_confirmed) unless @group.confirmed?
            return blocked(:imported_group) if @group.origin_import?
            return blocked(:has_project) if @group.project.present?

            @group.project_group_invites.direct_request.pending.delete_all

            old_name = @group.group_name.presence || "Group #{@group.id}"
            new_name = course.lowest_free_tmp_group_name

            @group.update!(confirmed: false, group_name: new_name)
            Result.new(reopened: true, old_name: old_name, new_name: new_name)
          end
        end

        return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

        result
      end

      private

      def blocked(reason)
        Result.new(reopened: false, blocked_reason: reason)
      end

      class Result
        attr_reader :old_name, :new_name, :blocked_reason

        def initialize(reopened:, old_name: nil, new_name: nil, blocked_reason: nil)
          @reopened = reopened
          @old_name = old_name
          @new_name = new_name
          @blocked_reason = blocked_reason
        end

        def reopened? = @reopened
        def reverted? = @reopened

        def message
          return "#{old_name} is reopened as #{new_name}." if reopened?

          case blocked_reason
          when :already_not_confirmed, :already_draft then 'This group is already a Not Confirmed Group.'
          when :imported_group then 'This group was imported, so it cannot be reopened.'
          when :has_project then 'This group already has a proposal, so it cannot be reopened.'
          when :group_gone then 'This group no longer exists.'
          end
        end
      end
    end
  end
end
