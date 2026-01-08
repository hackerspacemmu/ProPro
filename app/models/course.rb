class Course < ApplicationRecord
  has_many :enrolments, dependent: :destroy
  has_many :users, through: :enrolments

  has_many :students, -> { where(enrolments: { role: :student }) }, through: :enrolments, source: :user
  has_many :coordinators, -> { where(enrolments: { role: :coordinator }) }, through: :enrolments, source: :user
  has_many :lecturers, -> { where(enrolments: { role: :lecturer }) }, through: :enrolments, source: :user

  has_many :projects, dependent: :destroy
  has_many :project_groups, dependent: :destroy

  has_one :project_template, dependent: :destroy

  has_many :topics, dependent: :destroy

  attribute :student_access, :integer, default: :no_restriction
  attribute :lecturer_access, :boolean, default: true
  attribute :use_progress_updates, :boolean, default: false
  attribute :require_coordinator_approval, :boolean, default: false

  attribute :supervisor_projects_limit, :integer, default: 1
  attribute :starting_week, :integer, default: 1
  attribute :number_of_updates, :integer

  enum :student_access, { owner_only: 0, own_lecturer_only: 1, no_restriction: 2 }

  validates :course_name, presence: { message: 'cannot be empty' }
  validates :require_coordinator_approval, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :grouped, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :starting_week, presence: { message: 'cannot be empty' }, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }

  validates :use_progress_updates, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :number_of_updates, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole if using progress updates number' }, if: :use_progress_updates

  validates :lecturer_access, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :student_access, presence: { message: 'cannot be empty' }, inclusion: { in: Course.student_accesses.keys.map, message: 'is invalid' }
  validates :supervisor_projects_limit, presence: { message: 'cannot be empty' }, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }

  before_validation :null_number_of_updates_if_not_used

  private

  def null_number_of_updates_if_not_used
    return if use_progress_updates

    self.number_of_updates = nil
  end
end
