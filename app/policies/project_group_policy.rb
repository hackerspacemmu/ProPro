class ProjectGroupPolicy < ApplicationPolicy
  # record = ProjectGroup instance
  # user   = current_user

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
    return false if coordinator?
    enrolment.present? &&
      grouping_window_open? &&
      !record.course.project_group_members.exists?(user:)
  end

  def confirm?
    return true if coordinator?
    grouping_window_open? && record.leader_id == user.id
  end

  def revert?
    return true if coordinator?
    grouping_window_open? && record.leader_id == user.id
  end

  def destroy?
    return true if coordinator?
    grouping_window_open? && record.leader_id == user.id
  end
end