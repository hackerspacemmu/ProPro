class ProjectInstanceField < ApplicationRecord
  belongs_to :instance, polymorphic: true
  belongs_to :project_template_field
  belongs_to :source_field, class_name: 'ProjectInstanceField', optional: true
end
