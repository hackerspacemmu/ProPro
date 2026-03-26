require 'sqids'

# Represents courses
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

  scope :managed_by, ->(user) { joins(:enrolments).where(enrolments: { user_id: user.id, role: %i[lecturer coordinator] }).distinct }

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

  def generate_coursecode!
    raise StandardError, 'Course join code can\'t be used for grouped course' if grouped

    sqids = Sqids.new(alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', min_length: 6)
    self.coursecode = sqids.encode([id, SecureRandom.random_number(1_000_000_000)])
    save!
  end

  STUDENT_CSV_COLUMNS = ['Last name', 'ID number', 'Email address'].freeze

  def parse_csv_grouped(csv_obj)
    ret = {}

    csv_obj.each do |row|
      mapped_columns = STUDENT_CSV_COLUMNS.map { |col| row[col] }
      # in the csv, an empty group still has a row, just that all columns of that row are not populated, this is valid
      next if mapped_columns.all?(&:nil?)

      # if it passed the previous check, it means that the current row is not ALL empty, but ONE OF the columns might still be, this is invalid
      mapped_columns.each { |col| raise StandardError, 'Invalid CSV file' if col.nil? }

      group = row['Group'].strip
      ret[group] ||= Set[]
      ret[group].add({
                       name: row['Last name'].strip,
                       student_id: row['ID number'].strip,
                       email_address: row['Email address'].strip
                     })
    end

    ret
  end

  def parse_csv_solo(csv_obj)
    ret = Set[]

    csv_obj.each do |row|
      mapped_columns = STUDENT_CSV_COLUMNS.map { |col| row[col] }
      mapped_columns.each { |col| raise StandardError, 'Invalid CSV file' if col.nil? }

      ret.add({
                name: row['Last name'].strip,
                student_id: row['ID number'].strip,
                email_address: row['Email address'].strip
              })
    end

    ret
  end

  def lecturer_capacity(lecturer)
    enrolment = enrolments.find_by(user: lecturer, role: :lecturer)
    return empty_capacity if enrolment.nil?

    approved = projects.supervised_by(enrolment).approved.count
    pending  = projects.supervised_by(enrolment).pending_redo.count

    {
      approved_proposals: approved,
      pending_proposals: pending,
      total_proposals: approved + pending,
      max_capacity: supervisor_projects_limit,
      remaining_capacity: [supervisor_projects_limit - approved, 0].max,
      is_at_capacity: approved >= supervisor_projects_limit
    }
  end

  def students_with_status(status, student_list)
    case status
    when 'approved'
      approved_owner_ids = projects.approved.where(owner_type: 'User').pluck(:owner_id)
      student_list.select { |s| approved_owner_ids.include?(s.id) }
    when 'not_submitted'
      submitted_ids = projects.where(owner_type: 'User').pluck(:owner_id)
      student_list.reject { |s| submitted_ids.include?(s.id) }
    when 'pending', 'redo', 'rejected'
      student_list.select do |s|
        projects.find_by(owner_type: 'User', owner_id: s.id)&.current_status == status
      end
    else
      []
    end
  end

  def groups_with_status(status, group_list)
    case status
    when 'not_submitted'
      existing_ids = projects.where(owner_type: 'ProjectGroup').pluck(:owner_id)
      group_list.reject { |g| existing_ids.include?(g.id) }
    when 'approved', 'pending', 'redo', 'rejected'
      group_list.select do |g|
        projects.find_by(owner_type: 'ProjectGroup', owner_id: g.id)&.current_status == status
      end
    else
      []
    end
  end

  private

  def null_number_of_updates_if_not_used
    return if use_progress_updates

    self.number_of_updates = nil
  end

  def empty_capacity
    { approved_proposals: 0, pending_proposals: 0, total_proposals: 0,
      max_capacity: supervisor_projects_limit, remaining_capacity: supervisor_projects_limit,
      is_at_capacity: false }
  end
end
