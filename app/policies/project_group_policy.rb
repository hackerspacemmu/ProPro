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

    enrolment.present? &&
      grouping_window_open? &&
      !record.course.project_group_members.exists?(user:)
  end

  def confirm?
    record.leader_id == user.id
  end

  def revert?
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

  # Student can join an unlocked draft group if ungrouped and window is open.
  def join?
    grouping_window_open? &&
      !current_user_in_any_group? &&
      !record.confirmed? &&
      !record.locked?
  end

  # Student can send a join request to a locked draft group.
  def request_to_join?
    grouping_window_open? &&
      !current_user_in_any_group? &&
      !record.confirmed?
  end

  # Any member can leave within the grouping window.
  def leave?
    grouping_window_open? &&
      record.project_group_members.exists?(user_id: user.id)
  end

  # Leader or coordinator can kick a member.
  def kick_member?
    grouping_window_open? &&
      (coordinator? || record.leader?(user))
  end

  private

  def current_user_in_any_group?
    ProjectGroupMember.joins(:project_group)
                      .where(user_id: user.id,
                             project_groups: { course_id: record.course_id })
                      .exists?
  end
end
