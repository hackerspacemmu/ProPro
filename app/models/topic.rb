class Topic < ApplicationRecord
  self.table_name = 'projects'

  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
  default_scope { where(ownership_type: :lecturer) }

  belongs_to :course
  belongs_to :owner, polymorphic: true

  has_many :topic_instances, dependent: :destroy, foreign_key: 'project_id'

  has_many :proposed_project_instances, class_name: 'ProjectInstance', foreign_key: 'source_topic_id'

  # DO NOT WRITE TO STATUS IN PROJECTS, IT'S ONLY MEANT TO KEEP TRACK OF THE STATUS OF THE LATEST PROJECT INSTANCE
  # write to the latest project instance instead
  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }

  # Status filters
  scope :pending, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }
  scope :pending_redo, -> { where(status: %i[pending redo]) }
  scope :proposals, -> { where(status: %i[pending redo rejected]) }

  before_validation :set_ownership_type

  def supervisor
    User.find(Enrolment.find(enrolment_id).user_id)
  end

  def member
    if ownership.owner.is_a?(ProjectGroup)
      ownership.owner.users
    else
      [ownership.user]
    end
  end

  def current_instance
    if topic_instances.column_names.include?('version')
      topic_instances.order(version: :desc, created_at: :desc).first
    else
      topic_instances.order(created_at: :desc).first
    end
  end

  def current_status
    (current_instance&.status || status || :not_submitted).to_s
  end

  def current_title
    current_instance&.title || title
  end

  private

  def set_ownership_type
    self.ownership_type = :lecturer
  end
end
