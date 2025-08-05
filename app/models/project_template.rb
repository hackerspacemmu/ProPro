class ProjectTemplate < ApplicationRecord
  belongs_to :course
  has_many :project_template_fields, dependent: :destroy
  accepts_nested_attributes_for :project_template_fields, allow_destroy: true, reject_if: :all_blank

  before_validation :ensure_title_field

  private

  def ensure_title_field
    return if project_template_fields.any? { |f| f.label == "Project Title" }

    project_template_fields.build(
      label:         "Project Title",
      field_type:    "shorttext",
      applicable_to: "both"
    )
  end
end
