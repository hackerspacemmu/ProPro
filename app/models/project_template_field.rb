class ProjectTemplateField < ApplicationRecord
  belongs_to :project_template

  enum :field_type, {shorttext: 0, textarea: 1, dropdown: 2, radio: 3}
  enum :applicable_to, {topics: 0, proposals: 1, both: 2}
end

