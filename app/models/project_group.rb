class ProjectGroup < ApplicationRecord
  has_many :project_group_members, dependent: :destroy
  belongs_to :course

  has_many :users, through: :project_group_members
  has_one :project, dependent: :destroy, as: :owner
  has_many :project_group_invites, dependent: :destroy

  def revert_to_draft!
    update!(confirmed: false)
  end

  # Promotes the earliest-joined remaining member to group leader.
  # If no members remain, dissolves the group.
  # Returns the new leader User, or nil if dissolved.
  def assign_next_leader!
    successor_member = project_group_members.order(created_at: :asc).first

    if successor_member
      update!(leader_id: successor_member.user_id)
      successor_member.user
    else
      dissolve!
      nil
    end
  end

  def pending_requests
    project_group_invites.pending
  end

  # Returns true if this group has at least one associated project.
  def has_project?
    project.exists?
  end

  def leader?(user)
    leader_id == user.id
  end
end
