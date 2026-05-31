class ProjectGroupInvite < ApplicationRecord
  belongs_to :project_group
  belongs_to :sender, class_name: "User"

  enum :kind,   { request: 0 }    # invite (sent from group): 1 reserved for future
  enum :status, { pending: 0, accepted: 1, declined: 2 }

  # Model-level guard that mirrors the partial DB index.
  # Catches duplicates in the same transaction before the DB constraint fires.
  validates :sender_id,
            uniqueness: {
              scope:      [:project_group_id, :kind],
              conditions: -> { where(status: :pending) },
              message:    "already has a pending request for this group"
            }

  validates :kind,   presence: true
  validates :status, presence: true

  # ── Scopes ─────────────────────────────────────────────────────────────────
  scope :pending_for_group, ->(group)   { where(project_group: group, status: :pending) }
  scope :for_course,        ->(course)  { joins(:project_group).where(project_groups: { course_id: course.id }) }
  scope :sent_by,           ->(user)    { where(sender: user) }
end
