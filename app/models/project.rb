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

  scope :pending_for_lecturer, ->(lecturer_enrolment) {
  includes(:ownership, :supervisor_enrolment).where(status: 'pending', supervisor_enrolment: lecturer_enrolment).joins(:ownership)
    .where.not(ownerships: { ownership_type: Ownership.ownership_types[:lecturer] })
  }

  def supervisor
    User.find(Enrolment.find(self.enrolment_id).user_id)
  end

  def member
    if ownership.owner.is_a?(ProjectGroup)
      ownership.owner.users
    else
      [ ownership.user ]
    end
  end
  
end
