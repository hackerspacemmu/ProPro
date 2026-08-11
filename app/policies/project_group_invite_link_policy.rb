class ProjectGroupInviteLinkPolicy < ApplicationPolicy
  def redeem?
    enrolment&.student?
  end

  private

  def enrolment
    record.project_group.course.enrolments.find_by(user:)
  end
end