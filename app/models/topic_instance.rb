class TopicInstance < ApplicationRecord
  self.table_name = 'project_instances'

  enum :project_instance_type, { topic: 0, project: 1 }

  default_scope { where(project_instance_type: :topic) }
  belongs_to :topic, foreign_key: 'project_id'

  has_many :comments, as: :location

  belongs_to :created_by, class_name: 'User'
  belongs_to :source_topic, class_name: 'Project', optional: true

  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }

  has_many :project_instance_fields, dependent: :destroy, as: :instance

  before_validation :set_project_instance_type
  after_save :update_parent_topic

  private

  def update_parent_topic
    return unless topic.topic_instances.order(created_at: :asc).last == self

    topic.update_column(:status, status)
  end

  def set_project_instance_type
    self.project_instance_type = :topic
  end
end
