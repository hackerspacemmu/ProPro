# Redeems a project group invite link. Whoever holds a valid token joins
# instantly — no approval step, no email. Stateless, no self/leader
# branching (link kind always self-serves). Enrollment/role check lives in
# ProjectGroupInviteLinkPolicy#redeem? (identity concern, not service).
class GroupInviteLinkRedeemer
  include Groups::GroupLocking

  def initialize(invite_link, current_user:)
    @invite_link = invite_link
    @current_user = current_user
  end

  def redeem!
    return blocked(:expired) if @invite_link.expires_at.past?

    group = @invite_link.project_group

    result = with_group_lock(group) do
      course = group.course

      return blocked(:not_enrolled) unless course.enrolments.exists?(user_id: @current_user.id, role: :student)
      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:group_confirmed) if group.confirmed?
      return blocked(:group_full) if group_full?(group, course)
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)

      return blocked(:already_grouped) unless ProjectGroupMember.add(user: @current_user, group: group)

      ProjectGroupInvite.clear_pending_for!(@current_user, course)

      Result.new(redeemed: true, blocked_reason: nil, group: group)
    end

    return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

    result
  end

  private

  def group_full?(group, course)
    course.group_max.present? && group.project_group_members.count >= course.group_max
  end

  def blocked(reason)
    Result.new(redeemed: false, blocked_reason: reason, group: nil)
  end

  class Result
    attr_reader :blocked_reason, :group

    def initialize(redeemed:, blocked_reason:, group:)
      @redeemed = redeemed
      @blocked_reason = blocked_reason
      @group = group
    end

    def redeemed? = @redeemed
    def blocked? = !redeemed?

    def message
      return "You've joined #{group.group_name}." if redeemed?

      case blocked_reason
      when :expired then 'This invite link has expired.'
      when :not_enrolled then 'You are not enrolled in this course.'
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'This group is already confirmed.'
      when :group_full then 'This group has reached its maximum size.'
      when :already_grouped then 'You are already in a group for this course.'
      when :group_gone then 'This group no longer exists.'
      end
    end
  end
end
