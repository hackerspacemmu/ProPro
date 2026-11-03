module Groups
  module Coordinator
    # Deletes a group in any state. A group that owns a proposal is only deleted
    # after an explicitly confirmed request.
    class GroupDeleter
      def initialize(group, confirm: false)
        @group = group
        @confirm = confirm
      end

      def delete!
        # Deleting a confirmed group changes the course-wide head-count, so the
        # course lock is taken before the group row.
        @group.course.with_lock do
          @group.with_lock do
            return needs_confirmation(@group.project.current_title) if @group.project.present? && !@confirm

            @group.destroy!
            Result.new(deleted: true)
          end
        end
      end

      private

      def needs_confirmation(project_title)
        Result.new(deleted: false, project_title: project_title)
      end

      class Result
        attr_reader :project_title

        def initialize(deleted:, project_title: nil)
          @deleted = deleted
          @project_title = project_title
        end

        def deleted? = @deleted
        def needs_confirmation? = !deleted? && project_title.present?
        def blocked? = !deleted? && !needs_confirmation?

        def message
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
