class Project < ApplicationRecord
  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
  default_scope { where(ownership_type: %i[student project_group]) }

  belongs_to :supervisor_enrolment, class_name: 'Enrolment', foreign_key: 'enrolment_id'
  belongs_to :course
  belongs_to :owner, polymorphic: true

  has_many :project_instances, dependent: :destroy
  has_many :progress_updates, dependent: :destroy
  has_many :comments, through: :project_instances

  # DO NOT WRITE TO STATUS IN PROJECTS, IT'S ONLY MEANT TO KEEP TRACK OF THE STATUS OF THE LATEST PROJECT INSTANCE
  # write to the latest project instance instead
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }, default: :pending
  #attribute :status, :integer, default: :pending

  # Status filters
  scope :pending, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }
  scope :pending_redo, -> { where(status: %i[pending redo]) }
  scope :proposals, -> { where(status: %i[pending redo rejected]) }

  # Enrolment (supervisor) filters
  scope :supervised_by, ->(supervisor_enrolment) { where(supervisor_enrolment: supervisor_enrolment) }

  scope :owned_by_user_or_groups, lambda { |user, groups|
    where(owner: [user] + groups.to_a)
  }
  scope :owned_by_user, ->(user) { where(owner: user) }
  scope :owned_by_groups, ->(groups) { where(owner: groups) }

  before_validation :set_ownership_type

  STATUS_SORT_ORDER = { 'rejected' => 0, 'redo' => 1, 'pending' => 2, 'not_submitted' => 3, 'approved' => 4 }.freeze

  def supervisor
    self.supervisor_enrolment.user
  end

  def member
    if ownership.owner.is_a?(ProjectGroup)
      ownership.owner.users
    else
      [ownership.user]
    end
  end

  def current_instance
    if project_instances.column_names.include?('version')
      project_instances.order(version: :desc, created_at: :desc).first
    else
      project_instances.order(created_at: :desc).first
    end
  end

  def current_status
    (current_instance&.status || status || :not_submitted).to_s
  end

  def current_title
    current_instance&.title || title
  end

  def editable?
    !approved?
  end

  def instance_to_edit(created_by:, has_supervisor_comment:)
    if approved? || rejected? || redo? || (pending? && has_supervisor_comment)
      project_instances.build(
        version: (project_instances.maximum(:version) || 0) + 1,
        created_by: created_by,
        supervisor_enrolment: supervisor_enrolment,
        status: approved? ? :approved : :pending
      )
    else
      # If approved and pending (no supervisor comment) dont create new instance
      project_instances.last
    end
  end

  private

  def set_ownership_type
    self.ownership_type = :student
  end
end
