class ProjectInstance < ApplicationRecord
  belongs_to :project
  belongs_to :created_by, class_name: "User"

  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3 }

  has_many :project_instance_fields, dependent: :destroy

  after_save :update_parent_project_status

  private
  def update_parent_project_status
    if project.project_instances.order(created_at: :asc).last == self
      project.update(status: self.status)
    end
  end
end
