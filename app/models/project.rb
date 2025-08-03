class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  has_many :project_instances, dependent: :destroy
  has_many :comments, dependent: :destroy
  delegate :owner, to: :ownership
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  def supervisor
    User.find(Enrolment.find(self.enrolment_id).user_id)
  end
end
