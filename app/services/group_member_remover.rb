# Removes a member from a project group: self-leave, leader-kick, or coordinator-removal.
class GroupMemberRemover
  def initialize(member, current_user:, dissolve_confirmed: false)
    @member = member
    @current_user = current_user
    @dissolve_confirmed = dissolve_confirmed
    @group = member.project_group
  end

  def remove!
    @group.with_lock do
      return blocked(:window_closed) if requires_window_check? && !window_open?
      return blocked(:group_confirmed) if leader_kick? && @group.confirmed?

      remaining_count = @group.project_group_members.count - 1

      return needs_confirmation(@group.project.current_title) if remaining_count.zero? && @group.project.present? && !@dissolve_confirmed

      was_leader = @group.leader?(@member.user)
      @member.destroy!

      if remaining_count.zero?
        dissolve!
        return Result.new(outcome: :dissolved, blocked_reason: nil)
      end

      promote_next_leader! if was_leader

      if @group.confirmed? && (self_leave? || !legal_at_current_size?)
        @group.update!(confirmed: false)
        return Result.new(outcome: :reverted, blocked_reason: nil)
      end

      Result.new(outcome: :unchanged, blocked_reason: nil)
    end
  end

  private

  def self_leave?
    @current_user.id == @member.user_id
  end

  def leader_kick?
    !self_leave? && @group.leader?(@current_user)
  end

  def requires_window_check?
    self_leave? || leader_kick?
  end

  def window_open?
    @group.course.grouping_window_open?
  end

  def legal_at_current_size?
    @group.confirmable?
  end

  def promote_next_leader!
    successor = @group.project_group_members.order(:created_at).first
    @group.update!(leader_id: successor.user_id)
  end

  def dissolve!
    @group.project_group_invites.destroy_all
    @group.project_group_invite_links.destroy_all
    @group.destroy!
  end

  def blocked(reason)
    Result.new(outcome: :blocked, blocked_reason: reason)
  end

  def needs_confirmation(project_title)
    Result.new(outcome: :needs_confirmation, blocked_reason: nil, project_title: project_title)
  end

  class Result
    attr_reader :outcome, :blocked_reason, :project_title

    def initialize(outcome:, blocked_reason:, project_title: nil)
      @outcome = outcome
      @blocked_reason = blocked_reason
      @project_title = project_title
    end

    def dissolved? = outcome == :dissolved
    def reverted? = outcome == :reverted
    def needs_confirmation? = outcome == :needs_confirmation
    def blocked? = outcome == :blocked

    def message
      return blocked_message if blocked?
      return "Removing this member will permanently delete the project “#{project_title}”. This can't be undone." if needs_confirmation?

      case outcome
      when :dissolved then 'Member removed. The group had no remaining members and was dissolved.'
      when :reverted then 'Member removed. The group no longer meets the size requirement and was reverted to draft.'
      else 'Member removed.'
      end
    end

    private

    def blocked_message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'The leader can only remove members while the group is still a draft.'
      end
    end
  end
end
