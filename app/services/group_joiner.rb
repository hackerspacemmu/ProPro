# Direct join to a not confirmed group.
class GroupJoiner
  include Groups::GroupLocking

  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def join!
    result = with_group_lock(@group) do
      course = @group.course

      return blocked(:imported_group) if @group.origin_import?
      return blocked(:not_enrolled) unless course.enrolments.exists?(user_id: @current_user.id, role: :student)
      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
      return blocked(:group_confirmed) if @group.confirmed?
      return blocked(:group_full) if course.group_full?(@group.project_group_members.count)

      return blocked(:already_grouped) unless ProjectGroupMember.add(user: @current_user, group: @group)

      ProjectGroupInvite.clear_pending_for!(@current_user, course)

      Result.new(joined: true, blocked_reason: nil)
    end

    return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

    result
  end

  private

  def blocked(reason)
    Result.new(joined: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(joined:, blocked_reason:)
      @joined = joined
      @blocked_reason = blocked_reason
    end

    def joined? = @joined
    def blocked? = !joined?

    def message
      return 'Joined the group.' if joined?

      case blocked_reason
      when :imported_group then 'This group was imported, so it cannot take new members.'
      when :not_enrolled then 'You are not enrolled in this course.'
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_full then 'Group has reached its maximum size.'
      when :group_gone then 'This group no longer exists.'
      end
    end
  end
end
