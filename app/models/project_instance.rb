class ProjectInstance < ApplicationRecord
  belongs_to :project
  belongs_to :created_by, class_name: "User"

  has_many :project_instance_fields, dependent: :destroy
end
