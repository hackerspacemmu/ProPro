class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  has_many :project_instances, dependent: :destroy
  #delegate :course, to: :enrolment
  #has_one :course, through: :enrolment
  enum :status, { pending: 0, redo: 1, in_review: 2, rejected: 3, approved: 4}


  #scope :supervisor, -> () {joins(:enrolments).where(enrolments: {role: :lecturer})}

  def supervisor
    Enrolment.find(self.enrolment_id)
  end
end
