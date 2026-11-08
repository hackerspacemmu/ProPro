# Responds to a pending ProjectGroupInvite — either a direct_request
# (leader accepts/declines a student's request) or a direct_invite
# (student accepts/declines a leader's invite). Joining user is inferred
# from kind: sender for direct_request, recipient for direct_invite.
# Accept adds the joining user as a member and clears their other pending
# invites/requests course-wide. Decline just flips status, no state change.
class GroupInviteResponder
  include Groups::GroupLocking

  def initialize(invite, current_user:)
    @invite = invite
    @current_user = current_user
    @group = invite.project_group
  end

  def accept!
    result = with_group_lock(@group) do
      @invite.reload
      return blocked(:already_responded) unless @invite.pending?

      course = @group.course
      joining_user = joining_user_for(@invite)

      return blocked(:not_enrolled) unless course.enrolments.exists?(user_id: joining_user.id, role: :student)
      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: joining_user.id)
      return blocked(:group_confirmed) if @group.confirmed?
      return blocked(:group_full) if course.group_full?(@group.project_group_members.count)

      return blocked(:already_grouped) unless ProjectGroupMember.add(user: joining_user, group: @group)

      @invite.update!(status: :accepted)
      ProjectGroupInvite.clear_pending_for!(joining_user, course)

      Result.new(outcome: :accepted, blocked_reason: nil)
    end

    return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

    deliver_mailer(:accepted) if result.accepted?
    result
  end

  def decline!
    return blocked(:already_responded) unless @invite.pending?

    @invite.update!(status: :declined)
    deliver_mailer(:declined)

    Result.new(outcome: :declined, blocked_reason: nil)
  end

  private

  def joining_user_for(invite)
    invite.direct_request? ? invite.sender : invite.recipient
  end

  def deliver_mailer(outcome)
    method =
      if @invite.direct_request?
        outcome == :accepted ? :Group_Direct_Request_Accepted : :Group_Direct_Request_Declined
      else
        outcome == :accepted ? :Group_Direct_Invite_Accepted : :Group_Direct_Invite_Declined
      end

    GeneralMailer.with(invite: @invite).public_send(method).deliver_later
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
      when :accepted then 'Accepted. Member added to the group.'
      when :declined then 'Declined.'
      end
    end

    private

    def blocked_message
      case blocked_reason
      when :not_enrolled then 'This student is no longer enrolled in this course.'
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'This student already joined another group.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_full then 'Group has reached its maximum size.'
      when :already_responded then 'This has already been responded to.'
      when :group_gone then 'This group no longer exists.'
      end
    end
  end
end
