class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :course
  belongs_to :ownership

  has_one :course, through: :enrolment

  scope :supervisor, -> () {joins(:enrolments).where(enrolments: {role: :lecturer})}
end
