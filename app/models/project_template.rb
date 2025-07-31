class ProjectTemplate < ApplicationRecord
  belongs_to :course
  has_many :project_template_fields, dependent: :destroy

  accepts_nested_attributes_for :project_template_fields, allow_destroy: :true, reject_if: ->(attrs){ attrs['label'].blank? }
end
