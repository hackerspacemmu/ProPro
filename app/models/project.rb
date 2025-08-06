class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  belongs_to :supervisor_enrolment, class_name: "Enrolment", foreign_key: "enrolment_id"

  has_many :project_instances, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :progress_updates, dependent: :destroy
  delegate :owner, to: :ownership
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3 }

  def supervisor
    User.find(Enrolment.find(self.enrolment_id).user_id)
  end
end
