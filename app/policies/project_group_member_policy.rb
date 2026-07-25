class ProjectGroupMemberPolicy < ApplicationPolicy
  # Check for Identity only.
  # Window/confirmed project group checks belong in GroupMemberRemover.
  def destroy?
    return true if record.user_id == user.id
    return true if record.project_group.leader?(user)

    enrolment&.coordinator?
  end

  private

  def enrolment
    @enrolment ||= record.project_group.course.enrolments.find_by(user:)
  end
end
