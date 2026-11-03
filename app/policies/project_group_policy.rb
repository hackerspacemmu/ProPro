class ProjectGroupPolicy < ApplicationPolicy
  def enrolment
    @enrolment ||= record.course.enrolments.find_by(user:)
  end

  def coordinator?
    enrolment&.coordinator?
  end

  def grouping_window_open?
    record.course.grouping_window_open?
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
    return true if manage_groups_policy.manage_groups?

    record.leader_id == user.id
  end

  def destroy?
    return coordinator? if record.confirmed?

    grouping_window_open? && record.leader_id == user.id
  end

  def edit?
    manage_groups_policy.manage_groups? || update?
  end

  def update?
    return true if coordinator?

    grouping_window_open? &&
      record.leader_id == user.id && !record.confirmed?
  end

  def promote_leader?
    return true if coordinator?

    grouping_window_open? &&
      record.leader_id == user.id && !record.confirmed?
  end

  def join?
    enrolment.present? && enrolment.student?
  end

  def request_to_join?
    enrolment.present? && enrolment.student?
  end

  def generate_invite_link?
    record.leader_id == user.id
  end

  def direct_invite?
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
