class ProjectGroupInvitePolicy < ApplicationPolicy
  # Student can create a join request if ungrouped and window is open.
  def create?
    grouping_window_open? &&
      !current_user_in_any_group? &&
      !record.project_group.confirmed?
  end

  # Group leader or coordinator can accept an incoming request.
  def accept?
    record.pending? &&
      grouping_window_open? &&
      (coordinator? || leader_of_group?)
  end

  # Leader, coordinator, or the sender can decline/withdraw.
  def decline?
    record.pending? &&
      (coordinator? || leader_of_group? || own_request?)
  end

  private

  def leader_of_group?
    record.project_group.leader_id == user.id
  end

  def own_request?
    record.sender_id == user.id
  end

  def coordinator?
    # Delegate to CoursePolicy to reuse existing coordinator check.
    CoursePolicy.new(user, record.project_group.course).grouping_coordinator?
  end

  def grouping_window_open?
    record.project_group.course.grouping_window_open?
  end

  def current_user_in_any_group?
    course = record.project_group.course
    ProjectGroupMember.joins(:project_group)
                      .where(user_id: user.id,
                             project_groups: { course_id: course.id })
                      .exists?
  end
end
