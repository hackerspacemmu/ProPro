# Student requests to join a locked group they're not currently in.
# Creates a pending ProjectGroupInvite, notifies the group leader by email.
class GroupJoinRequester
  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def request!
    course = @group.course

    return blocked(:window_closed) unless course.grouping_window_open?
    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
    return blocked(:group_confirmed) if @group.confirmed?
    return blocked(:group_unlocked) unless @group.locked?

    join_request = ProjectGroupInvite.create!(
      project_group: @group,
      sender: @current_user,
      kind: :request,
      status: :pending
    )

    GeneralMailer.with(join_request: join_request).Group_Join_Request_Notification.deliver_later

    Result.new(requested: true, blocked_reason: nil)
  rescue ActiveRecord::RecordInvalid
    blocked(:already_requested)
  end

  private

  def blocked(reason)
    Result.new(requested: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(requested:, blocked_reason:)
      @requested = requested
      @blocked_reason = blocked_reason
    end

    def requested? = @requested
    def blocked? = !requested?

    def message
      return 'Join request sent.' if requested?

      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      when :group_confirmed then 'Group already confirmed, not accepting requests.'
      when :group_unlocked then 'Group is unlocked — join it directly instead.'
      when :already_requested then 'Already have a pending request for this group.'
      end
    end
  end
end
