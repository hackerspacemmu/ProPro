class ProjectInstance < ApplicationRecord
  belongs_to :project
  belongs_to :enrolment
  belongs_to :created_by, class_name: "User"
  belongs_to :source_topic, class_name: "Project", foreign_key: "source_topic_id", optional: true

  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }

  has_many :project_instance_fields, dependent: :destroy


  after_save :update_parent_project

  private
  def update_parent_project
    if project.project_instances.order(created_at: :asc).last == self
      project.update(
        status: self.status,
        enrolment: self.enrolment
      )
    end
  end
end
