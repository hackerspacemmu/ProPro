class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  has_many :project_instances, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :progress_updates, dependent: :destroy
  delegate :owner, to: :ownership
  belongs_to :parent_project, class_name: 'Project', optional: true
  has_many :child_projects, class_name: 'Project', foreign_key: 'parent_project_id'

  # DO NOT WRITE TO STATUS IN PROJECTS, IT'S ONLY MEANT TO KEEP TRACK OF THE STATUS OF THE LATEST PROJECT INSTANCE
  # write to the latest project instance instead
  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3 }

  scope :pending_for_lecturer, ->(lecturer_enrolment) {
  includes(:ownership, :enrolment)
    .where(status: :pending, enrolment: lecturer_enrolment)
    .joins(:ownership)
    .where.not(ownerships: { ownership_type: Ownership.ownership_types[:lecturer] })
 }

  scope :pending_student_proposals, -> {
    includes(:ownership).where(status: ['pending', 'redo', 'rejected']).joins(:ownership)
    .where.not(ownerships: { ownership_type: Ownership.ownership_types[:lecturer] })
  }

  scope :approved_student_proposals, -> {
  includes(:ownership, :enrolment)
    .where(status: :approved)
    .joins(:ownership)
    .where.not(ownerships: { ownership_type: Ownership.ownership_types[:lecturer] })
}

scope :approved_for_lecturer, ->(lecturer_enrolment) {
  includes(:ownership, :enrolment)
    .where(status: :approved, enrolment: lecturer_enrolment)
    .joins(:ownership)
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
