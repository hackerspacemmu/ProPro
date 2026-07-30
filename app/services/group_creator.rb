# Creates a project group. Student self-creates (becomes leader) or
# coordinator places a specified leader directly.
class GroupCreator
  def initialize(course, leader:, current_user:)
    @course = course
    @leader = leader
    @current_user = current_user
  end

  def create!
    @course.with_lock do
      return blocked(:already_grouped) if already_grouped?
      return blocked(:window_closed) if self_create? && !@course.grouping_window_open?

      group = build_group!
      Result.new(created: true, group: group, blocked_reason: nil)
    end
  end

  private

  def self_create?
    @leader.id == @current_user.id
  end

  def already_grouped?
    @course.project_group_members.exists?(user_id: @leader.id)
  end

  def build_group!
    next_seq = @course.project_groups.maximum(:course_group_sequence).to_i + 1
    group = @course.project_groups.create!(
      leader_id: @leader.id,
      course_group_sequence: next_seq,
      group_name: format('G%03d', next_seq)
    )
    ProjectGroupMember.create!(user: @leader, project_group: group)
    group
  end

  def blocked(reason)
    Result.new(created: false, group: nil, blocked_reason: reason)
  end

  class Result
    attr_reader :group, :blocked_reason

    def initialize(created:, group:, blocked_reason:)
      @created = created
      @group = group
      @blocked_reason = blocked_reason
    end

    def created? = @created
    def blocked? = !created?

    def message
      return "Draft group #{group.group_name} created." if created?

      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      end
    end
  end
end