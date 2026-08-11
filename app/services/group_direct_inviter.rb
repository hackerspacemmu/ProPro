# Leader sends a direct invite to a specific student, dropdown-picked —
# no token, no link. Creates a pending ProjectGroupInvite
# (kind: direct_invite), notifies the recipient by mandatory email.
class GroupDirectInviter
  def initialize(group, current_user:, recipient:)
    @group = group
    @current_user = current_user
    @recipient = recipient
  end

  def invite!
    course = @group.course
    recipient_enrolment = course.enrolments.find_by(user: @recipient)

    return blocked(:invalid_recipient) unless recipient_enrolment&.student?
    return blocked(:window_closed) unless course.grouping_window_open?
    return blocked(:group_confirmed) if @group.confirmed?
    return blocked(:group_full) if group_full?(course)
    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @recipient.id)

    invite = ProjectGroupInvite.create!(
      project_group: @group,
      sender: @current_user,
      recipient: @recipient,
      kind: :direct_invite,
      status: :pending
    )

    GeneralMailer.with(invite: invite).Group_Direct_Invite_Notification.deliver_later

    Result.new(invited: true, blocked_reason: nil)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    blocked(:already_invited)
  end

  private

  def group_full?(course)
    course.group_max.present? && @group.project_group_members.count >= course.group_max
  end

  def blocked(reason)
    Result.new(invited: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(invited:, blocked_reason:)
      @invited = invited
      @blocked_reason = blocked_reason
    end

    def invited? = @invited
    def blocked? = !invited?

    def message
      return 'Invite sent.' if invited?

      case blocked_reason
      when :invalid_recipient then 'This user cannot be invited to a group.'
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_full then 'Group has reached its maximum size.'
      when :already_grouped then 'This student already joined another group.'
      when :already_invited then 'This student already has a pending invite for this group.'
      end
    end
  end
end