class Enrolment < ApplicationRecord
    belongs_to :user
    belongs_to :course

    has_many :projects, dependent: :destroy
    enum :role, { lecturer: 0, coordinator: 1, student: 2 }
end
