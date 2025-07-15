class Course < ApplicationRecord
    has_many :enrolments
    has_many :project_groups
    enum :student_access, { own_group_only: 0, own_lecturer_only: 1, no_restriction: 2 }
    enum :lecturer_access, { false: 0, true: 1 }
    attribute :student_access, :integer, default: 2
    attribute :lecturer_access, :integer, default: 1
end
