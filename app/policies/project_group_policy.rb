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

  def index?
    return true if coordinator?

    enrolment.present? && record.course.grouping_enabled?
  end

  def create?
    return true if coordinator?

    enrolment.present? && enrolment.student?
  end

  def confirm?
    return true if manage_groups_policy.manage_groups?
    
    record.leader_id == user.id
  end

  def revert?
    return true if manage_groups_policy.manage_groups?

    record.leader_id == user.id
  end


  def destroy?
    return coordinator? if record.confirmed?

    grouping_window_open? && record.leader_id == user.id
  end

  def lock?
    return true if coordinator?

    grouping_window_open? &&
      record.leader_id == user.id && !record.confirmed?
  end

  def unlock?
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

  def leave?
    grouping_window_open? &&
      record.project_group_members.exists?(user_id: user.id)
  end

  # Leader or coordinator can kick a member.
  def kick_member?
    grouping_window_open? &&
      (coordinator? || record.leader?(user))
  end

  def generate_invite_link?
    record.leader_id == user.id
  end

  def direct_invite?
    record.leader_id == user.id
  end

  private

  def current_user_in_any_group?
    ProjectGroupMember.joins(:project_group)
                      .exists?(user_id: user.id,
                               project_groups: { course_id: record.course_id })
  end

  def manage_groups_policy
    Pundit.policy(user, record.course)
  end
end
