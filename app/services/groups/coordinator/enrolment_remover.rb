module Groups
  module Coordinator
    # Removes a student's course enrolment together with their group
    # membership and pending invites. Removing the last member of a group that
    # owns a proposal needs an explicit confirmation because the group and
    # proposal are deleted together.
    class EnrolmentRemover
      def initialize(enrolment, confirm: false)
        @enrolment = enrolment
        @course = enrolment.course
        @confirm = confirm
      end

      def remove!
        @course.with_no_key_update_lock do
          member_result = remove_group_membership

          next Result.new(outcome: :needs_confirmation, project_title: member_result.project_title) if member_result&.needs_confirmation?

          # The membership may already be gone, or its group deleted while we
          # waited; either way the course enrolment still has to be removed.
          ProjectGroupInvite.clear_pending_for!(@enrolment.user, @course)
          @enrolment.destroy!
          Result.new(outcome: :removed, group_deleted: member_result&.group_deleted? || false)
        end
      end

      private

      def remove_group_membership
        membership = @course.project_group_members.find_by(user_id: @enrolment.user_id)
        return unless membership

        MemberRemover.new(membership, confirm: @confirm).remove!
      end

      # Outcome of a removal: removed, or awaiting confirmation before deleting a proposal.
      class Result
        attr_reader :outcome, :project_title

        def initialize(outcome:, project_title: nil, group_deleted: false)
          @outcome = outcome
          @project_title = project_title
          @group_deleted = group_deleted
        end

        def removed? = outcome == :removed
        def needs_confirmation? = outcome == :needs_confirmation
        def group_deleted? = @group_deleted

        def message
          return "Removing this student will permanently delete the project “#{project_title}”. This can't be undone." if needs_confirmation?

          if group_deleted?
            'Student removed from course. The group had no remaining members and was deleted.'
          else
            'Student removed from course.'
          end
        end
      end
    end
  end
end
