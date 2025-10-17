class ProjectTemplate < ApplicationRecord
  belongs_to :course
  has_many :project_template_fields, dependent: :destroy
  accepts_nested_attributes_for :project_template_fields, allow_destroy: true, reject_if: :reject_incomplete_field

  before_validation :ensure_title_field

  private

  def ensure_title_field
    return if project_template_fields.empty?
    return if project_template_fields.first&.field_type == "shorttext"

    project_template_fields.unshift(
      project_template_fields.build(
        label: "Project Title",
        field_type: :shorttext,
        applicable_to: :both
      )
    )
  end

  def reject_incomplete_field(attrs)
    attrs['label'].blank? || attrs['field_type'].blank? || attrs['applicable_to'].blank?
  end
end
