class ProjectGroupPolicy < ApplicationPolicy
  def enrolment
    @enrolment ||= record.course.enrolments.find_by(user:)
  end

  def coordinator?
    record.course.enrolments.exists?(user_id: user.id, role: :coordinator)
  end

  def group_formation_open?
    record.course.group_formation_open?
  end

  def create?
    staff? || student?
  end

  def confirm?
    return true if manage_groups_policy.manage_groups?

    record.leader_id == user.id
  end

  def revert?
    return false if record.project.present?
    return false if record.origin_import?
    return true if manage_groups_policy.manage_groups?

    record.leader_id == user.id
  end

  def destroy?
    return true if coordinator?
    return false if record.confirmed?

    group_formation_open? && record.leader_id == user.id
  end

  def edit?
    manage_groups_policy.manage_groups? || update?
  end

  def update?
    return true if coordinator?

    group_formation_open? &&
      record.leader_id == user.id && !record.confirmed?
  end

  def join?
    enrolment.present? && enrolment.student?
  end

  # Requests are for confirmed formation groups only (D28); the service
  # re-checks enrolment, origin and formation state.
  def request_to_join?
    enrolment.present? && enrolment.student? && !record.origin_import? && record.confirmed?
  end

  def generate_invite_link?
    return false if record.origin_import?

    record.leader_id == user.id
  end

  def direct_invite?
    return false if record.origin_import?

    record.leader_id == user.id
  end

  private

  def staff?
    manage_groups_policy.manage_groups?
  end

  def student?
    enrolment&.student?
  end

  def current_user_in_any_group?
    ProjectGroupMember.joins(:project_group)
                      .exists?(user_id: user.id,
                               project_groups: { course_id: record.course_id })
  end

  def manage_groups_policy
    Pundit.policy(user, record.course)
  end
end
