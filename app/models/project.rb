class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  has_many :project_instances
  #delegate :course, to: :enrolment
  #has_one :course, through: :enrolment
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  def supervisor
    Enrolment.find(self.enrolment_id)
  end
end
