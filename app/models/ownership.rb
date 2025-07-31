class Ownership < ApplicationRecord
  belongs_to :owner, polymorphic: true
  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
end
