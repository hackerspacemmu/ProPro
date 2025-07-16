class Enrolment < ApplicationRecord
    belongs_to :user
    belongs_to :course
    enum :role, { lecturer: 0, coordinator: 1 }
end
