class ProjectGroupInvitePolicy < ApplicationPolicy
  def accept?
    leader?
  end

  def decline?
    leader?
  end

  private

  def leader?
    record.project_group.leader_id == user.id
  end
end
