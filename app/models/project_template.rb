class ProjectTemplate < ApplicationRecord
  belongs_to :course
  has_many :project_template_fields, -> { order(position: :asc) }, dependent: :destroy
  accepts_nested_attributes_for :project_template_fields, allow_destroy: true, reject_if: :reject_incomplete_field

  private

  def reject_incomplete_field(attrs)
    attrs['label'].blank? || attrs['field_type'].blank? || attrs['applicable_to'].blank?
  end
end
