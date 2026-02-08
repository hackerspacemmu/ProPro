class ProjectInstance < ApplicationRecord
  enum :project_instance_type, { topic: 0, project: 1 }

  default_scope { where(project_instance_type: :project) }

  belongs_to :project
  belongs_to :enrolment

  has_many :comments, as: :location

  belongs_to :created_by, class_name: 'User'
  belongs_to :source_topic, class_name: 'Topic', optional: true

  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }

  has_many :project_instance_fields, dependent: :destroy, as: :instance

  before_validation :set_project_type
  after_save :update_parent_project

  def supervisor
    return nil unless enrolment_id.present?

    enrolment = Enrolment.find_by(id: enrolment_id)
    enrolment&.user
  end

  private

  def update_parent_project
    return unless project.project_instances.order(created_at: :asc).last == self

    project.update(
      status: status,
      enrolment: enrolment
    )
  end

  def set_project_type
    self.project_instance_type = :project
  end
end
