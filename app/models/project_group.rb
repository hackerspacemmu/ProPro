class ProjectGroup < ApplicationRecord
  enum :origin, { formation: 'formation', import: 'import' }, prefix: true, validate: true

  has_many :project_group_members, dependent: :destroy
  belongs_to :course

  has_many :users, through: :project_group_members
  has_one :project, dependent: :destroy, as: :owner
  has_many :project_group_invites, dependent: :destroy
  has_many :project_group_invite_links, dependent: :destroy

  # Membership changes touch the group. Notify both grouping pages only after
  # the transaction commits, so counts, leadership and status refresh together.
  after_commit :refresh_grouping_displays

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

  def confirmable?
    Queries::GroupSizeConfirmabilityCalculator
      .new(course, students_to_group: course.unconfirmed_students_count)
      .execute
      .confirmable_size?(project_group_members.count)
  end

  private

  def refresh_grouping_displays
    Turbo::StreamsChannel.broadcast_refresh_to(course, :grouping)
  end
end
