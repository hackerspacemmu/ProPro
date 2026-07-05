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

  attribute :supervisor_projects_limit, :integer, default: 1
  attribute :starting_week, :integer, default: 1
  attribute :number_of_updates, :integer

  enum :student_access, { owner_only: 0, own_lecturer_only: 1, no_restriction: 2 }

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

  # group_min and group_max are required whenever grouping is enabled
  validates :group_min, presence: { message: 'is required when self-grouping is enabled' }, if: :grouping_enabled?
  validates :group_max, presence: { message: 'is required when self-grouping is enabled' }, if: :grouping_enabled?
  validates :group_min, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }, allow_nil: true

  validates :group_max,
            numericality: { only_integer: true, greater_than_or_equal_to: :group_min_for_validation, message: 'must be greater than or equal to minimum' },
            allow_nil: true,
            if: -> { group_min.present? && group_max.present? }

  # student_list_finalised cannot be true if grouping_enabled is false.
  validates :student_list_finalised, inclusion: { in: [false], message: 'cannot be set without self-grouping enabled' }, unless: :grouping_enabled?
  validate :grouping_window_dates_valid, if: -> { grouping_opens_at.present? && grouping_closes_at.present? }

  before_validation :null_number_of_updates_if_not_used
  before_validation :clear_grouping_fields_if_disabled

  def generate_coursecode!
    raise StandardError, 'Course join code can\'t be used for grouped course' if grouped

    sqids = Sqids.new(alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', min_length: 6)
    self.coursecode = sqids.encode([id, SecureRandom.random_number(1_000_000_000)])
    save!
  end

  def grouping_window_open?
    return false unless grouping_enabled?
    return false unless grouping_open?

    opens_ok = grouping_opens_at.nil? || Time.current >= grouping_opens_at
    closes_ok = grouping_closes_at.nil? || Time.current <= grouping_closes_at
    opens_ok && closes_ok
  end

  def disable_grouping!
    transaction do
      project_groups.where(confirmed: false).destroy_all
      update!(grouping_enabled: false, grouping_open: false, student_list_finalised: false)
    end
  end

  # NOTE: Called when coordinator switches from student_list_finalised mode back to default mode.
  # Confirmed groups stay. Draft groups are destroyed.
  def revert_to_default_mode!
    transaction do
      project_groups.where(confirmed: false).destroy_all
      update!(student_list_finalised: false)
    end
  end

  # NOTE: Finds the Largest legal group size combination
  def group_size_distribution(student_count = students.count)
    return { error: 'Group limits are not set' } if group_min.blank? || group_max.blank?
    return { error: 'Student count must be greater than 0' } if student_count <= 0

    cache = {}
    group_size_chosen = find_group_size_for(student_count, group_max.downto(group_min).to_a, cache)

    if group_size_chosen.nil?
      return {
        error: 'No legal combination can be found.'
      }
    end

    size_counts = []
    remaining_students = student_count
    while remaining_students > 0
      chosen_size = cache[remaining_students]
      size_counts << chosen_size
      remaining_students -= chosen_size
    end

    breakdown = size_counts.tally.map { |size, count| { size: size, count: count } }.sort_by { |entry| -entry[:size] }
    { groups: breakdown, total_groups: size_counts.length }
  end

  def find_group_size_for(ungrouped_students, allowed_sizes, cache)
    return 0 if ungrouped_students == 0
    return cache[ungrouped_students] if cache.key?(ungrouped_students)

    allowed_sizes.each do |size|
      next if size > ungrouped_students

      remaining_students = ungrouped_students - size
      result = find_group_size_for(remaining_students, allowed_sizes, cache)

      unless result.nil?
        cache[ungrouped_students] = size
        return size
      end
    end

    cache[ungrouped_students] = nil
    nil
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

  def solo_supervisor?
    enrolments.where(role: %i[lecturer coordinator]).count < 3
  end

  private

  def null_number_of_updates_if_not_used
    return if use_progress_updates

    self.number_of_updates = nil
  end

  def clear_grouping_fields_if_disabled
    return if grouping_enabled?

    self.grouping_open          = false
    self.student_list_finalised = false
    self.group_min              = nil
    self.group_max              = nil
    self.grouping_opens_at      = nil
    self.grouping_closes_at     = nil
  end

  def grouping_window_dates_valid
    return unless grouping_closes_at <= grouping_opens_at

    errors.add(:grouping_closes_at, 'must be after the grouping open time')
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
