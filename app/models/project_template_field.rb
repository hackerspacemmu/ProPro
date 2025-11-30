class ProjectTemplateField < ApplicationRecord
  belongs_to :project_template
  has_many   :project_instance_fields, dependent: :destroy
  
  enum :field_type, {shorttext: 0, textarea: 1, dropdown: 2, radio: 3}
  enum :applicable_to, {topics: 0, proposals: 1, both: 2}

  validates :label, presence: true
  validates :field_type, presence: true
  validates :applicable_to, presence: true
  validates :options, presence: true, if: -> { field_type.in?(['dropdown', 'radio']) }

  before_destroy :cannot_delete_if_in_use
  
  
  def option_list
    options.to_s.gsub(/[\[\]"]/, '').split(',').map(&:strip)
  end

  private
  def cannot_delete_if_in_use
    if project_instance_fields.exists?
      errors.add(:base, "Field “#{label}” is in use and can’t be removed")
      throw :abort
    end
  end

end
