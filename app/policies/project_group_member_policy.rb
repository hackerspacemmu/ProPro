class ProjectGroupMemberPolicy < ApplicationPolicy
  def destroy?
    group = record.project_group

    return true if coordinator?
    return false if group.confirmed? && record.user_id == user.id

    if group.confirmed?
      group.leader?(user) && !group.origin_import? && group.project.blank? &&
        group.course.group_formation_open?
    else
      record.user_id == user.id || group.leader?(user)
    end
  end

  private

  def coordinator?
    record.project_group.course.enrolments.exists?(user_id: user.id, role: :coordinator)
  end
end
