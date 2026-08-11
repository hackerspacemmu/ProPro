class ProjectGroup < ApplicationRecord
  has_many :project_group_members, dependent: :destroy
  belongs_to :course

  has_many :users, through: :project_group_members
  has_one :project, dependent: :destroy, as: :owner
  has_many :project_group_invites, dependent: :destroy
  has_many :project_group_invite_links, dependent: :destroy

  def revert_to_draft!
    update!(confirmed: false)
  end

  def pending_requests
    project_group_invites.pending
  end

  def has_project?
    project.exists?
  end

  def leader?(user)
    leader_id == user.id
  end
end
