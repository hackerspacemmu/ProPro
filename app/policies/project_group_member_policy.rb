class ProjectGroupMemberPolicy < ApplicationPolicy
  def destroy?
    return true if record.user_id == user.id
    return true if record.project_group.leader?(user)

    CoursePolicy.new(user, record.project_group.course).manage_groups?
  end

  private

  def enrolment
    @enrolment ||= record.project_group.course.enrolments.find_by(user:)
  end
end
