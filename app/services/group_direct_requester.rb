# Student requests to join a confirmed group.
# Creates a pending ProjectGroupInvite (kind: direct_request)
# Sends email to the leader
class GroupDirectRequester
  include Groups::GroupLocking

  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def request!
    course = @group.course

    result = with_group_lock(@group) do
      return blocked(:imported_group) if @group.origin_import?
      return blocked(:has_project) if @group.project.present?
      return blocked(:not_enrolled) unless course.enrolments.exists?(user_id: @current_user.id, role: :student)
      return blocked(:formation_closed) unless course.group_formation_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
      return blocked(:group_not_confirmed) unless @group.confirmed?
      return blocked(:no_leader_assigned) if @group.leader_id.blank?
      return blocked(:group_full) if course.group_full?(@group.project_group_members.count)

      # A stale request must not block a fresh one.
      @group.project_group_invites.direct_request.pending
            .where(sender_id: @current_user.id)
            .where(created_at: ..ProjectGroupInvite::REQUEST_TTL.ago)
            .delete_all

      invite = ProjectGroupInvite.create!(
        project_group: @group,
        sender: @current_user,
        recipient_id: @group.leader_id,
        kind: :direct_request,
        status: :pending
      )

      Result.new(requested: true, blocked_reason: nil, invite: invite)
    end

    return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

    GeneralMailer.with(invite: result.invite).Group_Direct_Request_Notification.deliver_later

    result
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
    attr_reader :blocked_reason, :invite

    def initialize(requested:, blocked_reason:, invite: nil)
      @requested = requested
      @blocked_reason = blocked_reason
      @invite = invite
    end

    def requested? = @requested
    def blocked? = !requested?

    def message
      return 'Join request sent.' if requested?

      case blocked_reason
      when :imported_group then 'This group was imported, so you cannot request to join it.'
      when :has_project then 'This group already has a proposal, so it cannot take new members.'
      when :not_enrolled then 'You are not enrolled in this course.'
      when :formation_closed then 'Group formation is closed.'
      when :already_grouped then 'Already in a group for this course.'
      when :group_not_confirmed then 'Requests are for confirmed groups. Join this group instead.'
      when :already_requested then 'Already have a pending request for this group.'
      when :group_full then 'This group has reached its maximum size.'
      when :no_leader_assigned then "This group hasn't been assigned a leader yet."
      when :group_gone then 'This group no longer exists.'
      end
    end
  end
end
