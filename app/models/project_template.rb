class ProjectTemplate < ApplicationRecord
  belongs_to :course
  has_many :project_template_fields, dependent: :destroy
end
