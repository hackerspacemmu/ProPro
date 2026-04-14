class ProjectInstance < ApplicationRecord
  enum :project_instance_type, { topic: 0, project: 1 }

  default_scope { where(project_instance_type: :project) }

  belongs_to :project
  belongs_to :supervisor_enrolment, class_name: 'Enrolment', foreign_key: 'enrolment_id'

  has_many :comments, as: :location, dependent: :destroy

  belongs_to :created_by, class_name: 'User'
  belongs_to :source_topic, class_name: 'Topic', optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }, default: :pending
  # attribute :status, :integer, default: :pending

  has_many :project_instance_fields, dependent: :destroy, as: :instance

  before_validation :set_project_type
  before_save :sync_title_from_fields
  after_save :update_parent_project

  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :title, presence: true

  def supervisor
    supervisor_enrolment.user
  end

  private

  def update_parent_project
    return unless project.project_instances.order(version: :desc, created_at: :desc).first == self

    project.update(
      status: status,
      supervisor_enrolment: supervisor_enrolment
    )
  end

  def set_project_type
    self.project_instance_type = :project
  end

  def sync_title_from_fields
    title_field = project_instance_fields.detect do |f|
      label = f.project_template_field&.label
      label&.downcase&.include?('title')
    end

    return if title_field.blank?

    self.title = title_field.value
  end
end
