class ProjectGroupInvite < ApplicationRecord
  belongs_to :project_group
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  enum :kind,   { direct_request: 0, direct_invite: 1 }
  enum :status, { pending: 0, accepted: 1, declined: 2 }

  # Blocks a student double-requesting to the same group
  validates :sender_id,
            uniqueness: {
              scope: %i[project_group_id kind],
              conditions: -> { where(status: :pending) },
              message: 'already has a pending request for this group'
            },
            if: -> { direct_request? } 

  # Blocks a leader double-inviting same student into same group.
  validates :recipient_id,
            uniqueness: {
              scope: %i[project_group_id kind],
              conditions: -> { where(status: :pending, kind: :direct_invite) },
              message: 'already has a pending invite for this group'
            },
            if: -> { direct_invite? }

  validates :kind,   presence: true
  validates :status, presence: true

  scope :pending_for_group, ->(group)   { where(project_group: group, status: :pending) }
  scope :for_course,        ->(course)  { joins(:project_group).where(project_groups: { course_id: course.id }) }
  scope :sent_by,           ->(user)    { where(sender: user) }
  scope :sent_to,           ->(user)    { where(recipient: user) }
end
