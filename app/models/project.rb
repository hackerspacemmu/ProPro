class Project < ApplicationRecord
  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
  default_scope { where(ownership_type: [:student, :project_group]) }

  belongs_to :enrolment
  belongs_to :course
  belongs_to :owner, polymorphic: true

  has_many :project_instances, dependent: :destroy
  has_many :progress_updates, dependent: :destroy


  # DO NOT WRITE TO STATUS IN PROJECTS, IT'S ONLY MEANT TO KEEP TRACK OF THE STATUS OF THE LATEST PROJECT INSTANCE
  # write to the latest project instance instead
  attribute :status, :integer, default: :pending
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }

  scope :student_owned, -> { where(ownership_type: :student) }
  scope :group_owned, -> { where(ownership_type: :group) }
  scope :not_lecturer_owned, -> { where.not(ownership_type: :lecturer) }
  scope :lecturer_owned, -> { where(ownership_type: :lecturer ) }

  # Status filters
  scope :pending, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }
  scope :pending_redo, -> { where(status: [:pending, :redo]) }
  scope :proposals, -> { where(status: [:pending, :redo, :rejected]) }

  # Enrolment (supervisor) filters
  scope :supervised_by, ->(enrolment) { where(enrolment: enrolment) }
  scope :student_projects_for_lecturer, ->(lecturer_enrolment) { 
    not_lecturer_owned.supervised_by(lecturer_enrolment) 
  }
  scope :owned_by_user_or_groups, ->(user, groups) {
    with_ownership.where(ownerships: { owner_type: 'User', owner_id: user.id })
      .or(with_ownership.where(ownerships: { owner_type: 'ProjectGroup', owner_id: groups.select(:id) }))
  }

  before_validation :set_ownership_type

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

  private
  def set_ownership_type
    self.ownership_type = :student
  end
end
