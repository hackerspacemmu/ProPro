class ProjectInstance < ApplicationRecord
  belongs_to :project
  belongs_to :created_by, class_name: "User"

  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3 }

  has_many :project_instance_fields, dependent: :destroy
end
