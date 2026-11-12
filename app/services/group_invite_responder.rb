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
    course = @group.course

    # Accepting into a confirmed group reopens it, which changes the course's
    # student count, so the course lock comes first (D21). Not-confirmed
    # groups take the same path for one lock order.
    result = course.with_no_key_update_lock do
      with_group_lock(@group) do
        # A project created (or a competing accept) while we waited can clear
        # this row. Reload via find_by so a vanished invite blocks instead of
        # raising RecordNotFound.
        @invite = ProjectGroupInvite.find_by(id: @invite.id)
        return blocked(:invite_gone) if @invite.nil?

        return blocked(:already_responded) unless @invite.pending?
        return blocked(:expired) if @invite.expired?

        joining_user = joining_user_for(@invite)

        return blocked(:imported_group) if @group.origin_import?
        return blocked(:not_enrolled) unless course.enrolments.exists?(user_id: joining_user.id, role: :student)
        return blocked(:window_closed) unless course.grouping_window_open?
        return blocked(:already_grouped) if course.project_group_members.exists?(user_id: joining_user.id)
        return blocked(:has_project) if @group.project.present?
        return blocked(:group_full) if course.group_full?(@group.project_group_members.count)

        return blocked(:already_grouped) unless ProjectGroupMember.add(user: joining_user, group: @group)

        was_confirmed = @group.confirmed?

        @invite.update!(status: :accepted)
        @group.reopen! if was_confirmed
        ProjectGroupInvite.clear_pending_for!(joining_user, course)

        Result.new(outcome: :accepted, blocked_reason: nil, reopened: was_confirmed, joining_user: joining_user)
      end
    end

    return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

    if result.accepted?
      deliver_mailer(:accepted)
      notify_members_of_reopen(result.joining_user) if result.reopened?
    end
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

  def notify_members_of_reopen(joiner)
    @group.users.find_each do |member|
      GeneralMailer.with(group: @group, joiner: joiner, recipient: member)
                   .Group_Reopened_Notification.deliver_later
    end
  end

  def blocked(reason)
    Result.new(outcome: :blocked, blocked_reason: reason)
  end

  class Result
    attr_reader :outcome, :blocked_reason, :joining_user

    def initialize(outcome:, blocked_reason:, reopened: false, joining_user: nil)
      @outcome = outcome
      @blocked_reason = blocked_reason
      @reopened = reopened
      @joining_user = joining_user
    end

    def accepted? = outcome == :accepted
    def declined? = outcome == :declined
    def blocked? = outcome == :blocked
    def reopened? = @reopened

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
      when :imported_group then 'This group was imported, so it cannot take new members.'
      when :not_enrolled then 'This student is no longer enrolled in this course.'
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'This student already joined another group.'
      when :has_project then 'This group already has a proposal, so it cannot take new members.'
      when :group_full then 'Group has reached its maximum size.'
      when :already_responded then 'This has already been responded to.'
      when :expired then 'This request has expired.'
      when :invite_gone then 'This request is no longer available.'
      when :group_gone then 'This group no longer exists.'
      end
    end
  end
end
