module Groups
  module Coordinator
    # Removes a member from a group in any state without changing its status.
    # Removing the last member of a group that owns a proposal needs an explicit
    # confirmation because the group and proposal are deleted together.
    class MemberRemover
      def initialize(member, confirm: false)
        @member = member
        @group = member.project_group
        @confirm = confirm
      end

      def remove!
        # Confirmed membership feeds the course-wide head-count, so the course
        # lock is taken before the group row.
        @group.course.with_no_key_update_lock do
          @group.with_lock do
            member = @group.project_group_members.find_by(id: @member.id)
            return blocked(:already_removed) unless member

            last_member = @group.project_group_members.one?
            return needs_confirmation(@group.project.current_title) if last_member && @group.project.present? && !@confirm

            was_leader = @group.leader?(member.user)
            member.destroy!

            if last_member
              @group.destroy!
              return Result.new(outcome: :group_deleted)
            end

            promote_next_leader! if was_leader
            Result.new(outcome: :removed)
          end
        end
      end

      private

      def promote_next_leader!
        successor = @group.project_group_members.order(:created_at, :id).first
        @group.update!(leader_id: successor.user_id)
      end

      def blocked(reason)
        Result.new(outcome: :blocked, blocked_reason: reason)
      end

      def needs_confirmation(project_title)
        Result.new(outcome: :needs_confirmation, project_title: project_title)
      end

      class Result
        attr_reader :outcome, :blocked_reason, :project_title

        def initialize(outcome:, blocked_reason: nil, project_title: nil)
          @outcome = outcome
          @blocked_reason = blocked_reason
          @project_title = project_title
        end

        def removed? = outcome == :removed
        def group_deleted? = outcome == :group_deleted
        def needs_confirmation? = outcome == :needs_confirmation
        def blocked? = outcome == :blocked

        def message
          return blocked_message if blocked?
          return "Removing this member will permanently delete the project “#{project_title}”. This can't be undone." if needs_confirmation?

          if group_deleted?
            'Member removed. The group had no remaining members and was deleted.'
          else
            'Member removed.'
          end
        end

        private

        def blocked_message
          'This member has already been removed.' if blocked_reason == :already_removed
        end
      end
    end
  end
end
