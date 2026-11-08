# Student requests to join a confirmed group.
# Creates a pending ProjectGroupInvite (kind: direct_request)
# Sends email to the leader
class GroupDirectRequester
  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def request!
    course = @group.course

    return blocked(:not_enrolled) unless course.enrolments.exists?(user_id: @current_user.id, role: :student)
    return blocked(:window_closed) unless course.grouping_window_open?
    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
    return blocked(:group_not_confirmed) unless @group.confirmed?
    return blocked(:no_leader_assigned) if @group.leader_id.blank?

    invite = ProjectGroupInvite.create!(
      project_group: @group,
      sender: @current_user,
      recipient_id: @group.leader_id,
      kind: :direct_request,
      status: :pending
    )

    GeneralMailer.with(invite: invite).Group_Direct_Request_Notification.deliver_later

    Result.new(requested: true, blocked_reason: nil)
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.record.errors.of_kind?(:sender_id, :taken)

    blocked(:already_requested)
  rescue ActiveRecord::RecordNotUnique
    # The pending-request unique index is the race backstop.
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
      when :not_enrolled then 'You are not enrolled in this course.'
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      when :group_not_confirmed then 'Requests are for confirmed groups. Join this group instead.'
      when :already_requested then 'Already have a pending request for this group.'
      when :no_leader_assigned then "This group hasn't been assigned a leader yet."
      end
    end
  end
end
