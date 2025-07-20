class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :course
  belongs_to :ownership

  scope :supervisor, -> () {joins(:enrolments).where(enrolments: {role: :lecturer})}
end
