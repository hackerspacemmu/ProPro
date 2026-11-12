# Leader sends a direct invite to a student
# Creates a pending ProjectGroupInvite (kind: direct_invite)
# Sends email to the student
class GroupDirectInviter
  def initialize(group, current_user:, recipient:)
    @group = group
    @current_user = current_user
    @recipient = recipient
  end

  def invite!
    course = @group.course
    recipient_enrolment = course.enrolments.find_by(user: @recipient)

    return blocked(:imported_group) if @group.origin_import?
    return blocked(:has_project) if @group.project.present?
    return blocked(:invalid_recipient) unless recipient_enrolment&.student?
    return blocked(:formation_closed) unless course.group_formation_open?
    return blocked(:group_full) if course.group_full?(@group.project_group_members.count)
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
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.record.errors.of_kind?(:recipient_id, :taken)

    blocked(:already_invited)
  rescue ActiveRecord::RecordNotUnique
    # The pending-invite unique index is the race backstop.
    blocked(:already_invited)
  end

  private

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
      when :imported_group then 'This group was imported, so it cannot take new members.'
      when :has_project then 'This group already has a proposal, so it cannot take new members.'
      when :invalid_recipient then 'This user cannot be invited to a group.'
      when :formation_closed then 'Group formation is closed.'
      when :group_full then 'This group has reached its maximum size.'
      when :already_grouped then 'This student already joined another group.'
      when :already_invited then 'This student already has a pending invite for this group.'
      end
    end
  end
end
