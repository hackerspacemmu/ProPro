module Groups
  module Coordinator
    # Deletes a group in any state. A group that owns a proposal is only deleted
    # after an explicitly confirmed request.
    class GroupDeleter
      include Groups::GroupLocking

      def initialize(group, confirm: false)
        @group = group
        @confirm = confirm
      end

      def delete!
        # Deleting a confirmed group changes the course-wide head-count, so the
        # course lock is taken before the group row.
        result = @group.course.with_no_key_update_lock do
          with_group_lock(@group) do
            return needs_confirmation(@group.project.current_title) if @group.project.present? && !@confirm

            @group.destroy!
            Result.new(deleted: true)
          end
        end

        return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

        result
      end

      private

      def needs_confirmation(project_title)
        Result.new(deleted: false, project_title: project_title)
      end

      def blocked(reason)
        Result.new(deleted: false, blocked_reason: reason)
      end

      class Result
        attr_reader :project_title, :blocked_reason

        def initialize(deleted:, project_title: nil, blocked_reason: nil)
          @deleted = deleted
          @project_title = project_title
          @blocked_reason = blocked_reason
        end

        def deleted? = @deleted
        def blocked? = blocked_reason.present?
        def needs_confirmation? = !deleted? && project_title.present?

        def message
          return 'This group no longer exists.' if blocked_reason == :group_gone

          if needs_confirmation?
            return 'Deleting this group will permanently delete the project ' \
                   "“#{project_title}”. This can't be undone."
          end

          'Group deleted.' if deleted?
        end
      end
    end
  end
end
