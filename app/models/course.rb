class Course < ApplicationRecord
    has_many :enrolments
    has_many :project_groups
    has_many :projects
    has_one :project_template
    enum :student_access, { owner_only: 0, own_lecturer_only: 1, no_restriction: 2 }
    attribute :student_access, :integer, default: 2
    attribute :lecturer_access, :integer, default: 1

    def coordinator
        self.enrolments.where(role: :coordinator)
    end

    def students
        self.enrolments.where(role: :student)
    end

    def lecturers
        self.enrolments.where(role: :lecturer)
    end
end
