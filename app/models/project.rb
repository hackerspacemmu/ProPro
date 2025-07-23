class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  has_one :project_instance
  #delegate :course, to: :enrolment
  #has_one :course, through: :enrolment
  enum :status, { pending: 0, approved: 1, rejected: 2 }


  #scope :supervisor, -> () {joins(:enrolments).where(enrolments: {role: :lecturer})}

  def supervisor
    Enrolment.find(self.enrolment_id)
  end
end
