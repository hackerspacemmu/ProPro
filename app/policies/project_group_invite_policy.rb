class ProjectGroupInvitePolicy < ApplicationPolicy
  def accept?
    responder_authorized?
  end

  def decline?
    responder_authorized?
  end

  private

  def responder_authorized?
    if record.direct_request?
      record.project_group.leader_id == user.id
    else
      record.recipient_id == user.id
    end
  end
end
