# Direct join to an unlocked draft group. Use GroupJoinRequester for locked groups.
class GroupJoiner
  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def join!
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
      return blocked(:group_confirmed) if @group.confirmed?
      return blocked(:group_locked) if @group.locked?
      return blocked(:group_full) if @group.project_group_members.count >= course.group_max.to_i

      ProjectGroupMember.create!(user: @current_user, project_group: @group)
      clear_conflicting_invites!

      Result.new(joined: true, blocked_reason: nil)
    end
  end

  private

  def clear_conflicting_invites!
    ProjectGroupInvite
      .where(sender_id: @current_user.id, kind: :request, status: :pending)
      .where(project_group_id: @group.course.project_groups.select(:id))
      .destroy_all
  end

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
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_locked then 'Group is locked. Send a join request instead.'
      when :group_full then 'Group has reached its maximum size.'
      end
    end
  end
end