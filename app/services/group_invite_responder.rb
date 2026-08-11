# Responds to a pending ProjectGroupInvite — either a direct_request
# (leader accepts/declines a student's request) or a direct_invite
# (student accepts/declines a leader's invite). Joining user is inferred
# from kind: sender for direct_request, recipient for direct_invite.
# Accept adds the joining user as a member and clears their other pending
# invites/requests course-wide. Decline just flips status, no state change.
class GroupInviteResponder
  def initialize(invite, current_user:)
    @invite = invite
    @current_user = current_user
    @group = invite.project_group
  end

  def accept!
    @group.with_lock do
      @invite.reload
      return blocked(:already_responded) unless @invite.pending?

      course = @group.course
      joining_user = joining_user_for(@invite)

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: joining_user.id)
      return blocked(:group_confirmed) if @group.confirmed?
      return blocked(:group_full) if group_full?(course)

      ProjectGroupMember.create!(user: joining_user, project_group: @group)
      @invite.update!(status: :accepted)
      clear_conflicting_invites!(joining_user)

      deliver_mailer(:accepted)

      Result.new(outcome: :accepted, blocked_reason: nil)
    end
  end

  def decline!
    return blocked(:already_responded) unless @invite.pending?

    @invite.update!(status: :declined)
    deliver_mailer(:declined)

    Result.new(outcome: :declined, blocked_reason: nil)
  end

  private

  def group_full?(course)
    course.group_max.present? && @group.project_group_members.count >= course.group_max
  end

  def joining_user_for(invite)
    invite.direct_request? ? invite.sender : invite.recipient
  end

  # Clears the direct request and invites for the student
  def clear_conflicting_invites!(joining_user)
    ProjectGroupInvite
      .where(status: :pending)
      .where('sender_id = :id OR recipient_id = :id', id: joining_user.id)
      .where(project_group_id: @group.course.project_groups.select(:id))
      .destroy_all
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
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'This student already joined another group.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_full then 'Group has reached its maximum size.'
      when :already_responded then 'This has already been responded to.'
      end
    end
  end
end
