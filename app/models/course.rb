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
  has_many :project_group_members, through: :project_groups

  attribute :student_access, :integer, default: :no_restriction
  attribute :lecturer_access, :boolean, default: true
  attribute :use_progress_updates, :boolean, default: false
  attribute :require_coordinator_approval, :boolean, default: false
  attribute :auto_approve_copied_topics_without_changes, :boolean, default: false

  attribute :supervisor_projects_limit, :integer, default: 1
  attribute :starting_week, :integer, default: 1
  attribute :number_of_updates, :integer

  enum :student_access, { owner_only: 0, own_lecturer_only: 1, no_restriction: 2 }

  TMP_GROUP_PREFIX = 'Tmp'.freeze
  CONFIRMED_GROUP_PREFIX = 'G'.freeze

  scope :managed_by, ->(user) { joins(:enrolments).where(enrolments: { user_id: user.id, role: %i[lecturer coordinator] }).distinct }
  scope :by_coursecode, ->(code) { where(coursecode: code) }

  validates :course_name, presence: { message: 'cannot be empty' }
  validates :require_coordinator_approval, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :grouped, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :starting_week, presence: { message: 'cannot be empty' }, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }

  validates :use_progress_updates, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :number_of_updates, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole if using progress updates number' }, if: :use_progress_updates

  validates :lecturer_access, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :student_access, presence: { message: 'cannot be empty' }, inclusion: { in: Course.student_accesses.keys.map, message: 'is invalid' }
  validates :supervisor_projects_limit, presence: { message: 'cannot be empty' }, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }
  validates :coursecode, uniqueness: { message: 'has already been taken' }, allow_nil: true
  validates :auto_approve_copied_topics_without_changes, inclusion: { in: [true, false], message: 'must be true or false' }

  # Prevent leftover students needs both limits to build a legal distribution.
  validates :group_min, presence: { message: 'is required when Prevent leftover students is on' }, if: :prevent_leftover_students?
  validates :group_max, presence: { message: 'is required when Prevent leftover students is on' }, if: :prevent_leftover_students?
  validates :group_min, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }, allow_nil: true

  validates :group_max,
            numericality: { only_integer: true, greater_than_or_equal_to: :group_min_for_validation, message: 'must be greater than or equal to minimum' },
            allow_nil: true,
            if: -> { group_min.present? && group_max.present? }

  # prevent_leftover_students cannot be true if group_formation_enabled is false.
  validates :prevent_leftover_students, inclusion: { in: [false], message: 'cannot be set without self-grouping enabled' }, unless: :group_formation_enabled?

  before_validation :null_number_of_updates_if_not_used
  before_validation :clear_grouping_fields_if_disabled

  def generate_coursecode!
    raise StandardError, 'Course join code can\'t be used for grouped course' if grouped

    sqids = Sqids.new(alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', min_length: 6)
    self.coursecode = sqids.encode([id, SecureRandom.random_number(1_000_000_000)])
    save!
  end

  def effective_group_min = group_min || 1

  def group_full?(member_count)
    group_max.present? && member_count >= group_max
  end

  def size_within_limits?(member_count)
    member_count >= effective_group_min && (group_max.nil? || member_count <= group_max)
  end

  def group_for(user)
    project_groups.joins(:project_group_members)
                  .find_by(project_group_members: { user_id: user.id })
  end

  def ungrouped_students
    students.where.not(id: project_group_members.select(:user_id)).order(:name)
  end

  def group_formation_open?
    group_formation_enabled? && (group_formation_closes_at.nil? || Time.current <= group_formation_closes_at)
  end

  def with_no_key_update_lock(&)
    transaction do
      lock!('FOR NO KEY UPDATE')
      yield
    end
  end

  # Callers hold the course lock, so two writers cannot pick the same number.
  def lowest_free_tmp_group_name
    lowest_free_group_name(TMP_GROUP_PREFIX)
  end

  def lowest_free_confirmed_group_name(excluding: nil)
    lowest_free_group_name(CONFIRMED_GROUP_PREFIX, excluding: excluding)
  end

  def unconfirmed_students_count
    confirmed_member_count = ProjectGroupMember
                             .joins(:project_group)
                             .where(project_groups: { course_id: id, confirmed: true })
                             .count

    students.count - confirmed_member_count
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
                       instid: row['ID number'].strip,
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
                instid: row['ID number'].strip,
                email_address: row['Email address'].strip
              })
    end

    ret
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
    when 'not_confirmed'
      group_list.reject(&:confirmed?)
    when 'not_submitted'
      existing_ids = projects.where(owner_type: 'ProjectGroup').pluck(:owner_id)
      group_list.select { |g| g.confirmed? && !existing_ids.include?(g.id) }
    when 'approved', 'pending', 'redo', 'rejected'
      group_list.select do |g|
        g.confirmed? && projects.find_by(owner_type: 'ProjectGroup', owner_id: g.id)&.current_status == status
      end
    else
      []
    end
  end

  def solo_supervisor?
    enrolments.where(role: %i[lecturer coordinator]).count < 3
  end

  private

  def lowest_free_group_name(prefix, excluding: nil)
    taken = project_groups.where.not(id: excluding&.id).pluck(:group_name).to_set
    number = 1
    number += 1 while taken.include?(format("#{prefix}%03d", number))
    format("#{prefix}%03d", number)
  end

  def null_number_of_updates_if_not_used
    return if use_progress_updates

    self.number_of_updates = nil
  end

  def clear_grouping_fields_if_disabled
    return if group_formation_enabled?

    self.prevent_leftover_students = false
    self.group_min                 = nil
    self.group_max                 = nil
    self.group_formation_closes_at = nil
  end

  def group_min_for_validation
    group_min || 0
  end

  def empty_capacity
    { approved_proposals: 0, pending_proposals: 0, total_proposals: 0,
      max_capacity: supervisor_projects_limit, remaining_capacity: supervisor_projects_limit,
      is_at_capacity: false }
  end
end
