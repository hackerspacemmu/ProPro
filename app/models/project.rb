class Project < ApplicationRecord
  belongs_to :enrolment
  belongs_to :ownership
  belongs_to :course

  has_many :project_instances, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :progress_updates, dependent: :destroy
  delegate :owner, to: :ownership
  #has_many :topic_responses, dependent: :destroy
  has_many :proposed_topic_instances, class_name: "ProjectInstance", foreign_key: "source_topic_id"


  # DO NOT WRITE TO STATUS IN PROJECTS, IT'S ONLY MEANT TO KEEP TRACK OF THE STATUS OF THE LATEST PROJECT INSTANCE
  # write to the latest project instance instead
  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }

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

  scope :incoming_proposals, ->(lecturer_enrolment) {
  includes(:ownership, :enrolment)
    .where(status: [:pending, :redo, :rejected], enrolment: lecturer_enrolment)
    .joins(:ownership)
    .where.not(ownerships: { ownership_type: Ownership.ownership_types[:lecturer] })
  }

  scope :pending_and_redo_for_lecturer, ->(lecturer_enrolment) {
    includes(:ownership, :enrolment)
      .where(status: [:pending, :redo], enrolment: lecturer_enrolment)
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

  def current_instance
    if project_instances.column_names.include?("version")
      project_instances.order(version: :desc, created_at: :desc).first
    else
      project_instances.order(created_at: :desc).first
    end
  end

  def current_status
    (current_instance&.status || self.status || :not_submitted).to_s
  end

  def current_title
    current_instance&.title || self.title
  end

end
