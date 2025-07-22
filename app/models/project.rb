class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course
  #delegate :course, to: :enrolment

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  #has_one :course, through: :enrolment

  scope :supervisor, -> () {joins(:enrolments).where(enrolments: {role: :lecturer})}
end
