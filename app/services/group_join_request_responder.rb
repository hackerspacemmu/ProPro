# Leader accepts or declines a pending join request.
# Accept adds the sender as a member and clears their other pending requests
# course-wide. Decline just flips status enum, no state changes.
class GroupJoinRequestResponder
  def initialize(join_request, current_user:)
    @join_request = join_request
    @current_user = current_user
    @group = join_request.project_group
  end

  def accept!
    @group.with_lock do
      return blocked(:already_responded) unless @join_request.pending?

      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @join_request.sender_id)
      return blocked(:group_confirmed) if @group.confirmed?
      return blocked(:group_full) if @group.project_group_members.count >= course.group_max.to_i

      # Creates new group membership
      ProjectGroupMember.create!(user: @join_request.sender, project_group: @group)
      @join_request.update!(status: :accepted)
      # Clears all existing requests
      clear_conflicting_requests!

      GeneralMailer.with(join_request: @join_request).Group_Join_Request_Accepted.deliver_later

      Result.new(outcome: :accepted, blocked_reason: nil)
    end
  end

  def decline!
    return blocked(:already_responded) unless @join_request.pending?

    @join_request.update!(status: :declined)
    GeneralMailer.with(join_request: @join_request).Group_Join_Request_Declined.deliver_later

    Result.new(outcome: :declined, blocked_reason: nil)
  end

  private

  def clear_conflicting_requests!
    ProjectGroupInvite
      .where(sender_id: @join_request.sender_id, kind: :request, status: :pending)
      .where(project_group_id: @group.course.project_groups.select(:id))
      .destroy_all
  end

  def blocked(reason)
    Result.new(outcome: :blocked, blocked_reason: reason)
  end

  class Result
    attr_reader :outcome, :blocked_reason

    def initialize(outcome:, blocked_reason:)
      @outcome = outcome
      @blocked_reason = blocked_reason
    end

    def accepted? = outcome == :accepted
    def declined? = outcome == :declined
    def blocked? = outcome == :blocked

    def message
      return blocked_message if blocked?

      case outcome
      when :accepted then 'Request accepted. Member added to the group.'
      when :declined then 'Request declined.'
      end
    end

    private

    def blocked_message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'This student already joined another group.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_full then 'Group has reached its maximum size.'
      when :already_responded then 'This request has already been responded to.'
      end
    end
  end
end