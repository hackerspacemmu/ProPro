class TopicInstance < ApplicationRecord
  self.table_name = "project_instances"

  enum :project_type, { topic: 0, project: 1 }
  
  default_scope { where(project_type: :topic) }
  belongs_to :topic, foreign_key: "project_id"
  
  #belongs_to :enrolment
  belongs_to :created_by, class_name: "User"
  belongs_to :source_topic, class_name: "Project", foreign_key: "source_topic_id", optional: true

  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }

  has_many :project_instance_fields, dependent: :destroy

  after_save :update_parent_topic
=begin
  def supervisor
    User.find(Enrolment.find(self.enrolment_id).user_id)
  end
=end
  private
  def update_parent_topic
    if topic.topic_instances.order(created_at: :asc).last == self
      topic.update(
        status: self.status,
      )
    end
  end
end
