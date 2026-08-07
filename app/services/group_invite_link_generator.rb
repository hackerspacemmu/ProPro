# Leader generates/regenerates the group's shareable invite link.
# Regenation deletes the old record and creates a new one.
# draft groups, no email notifications, can join if locked
class GroupInviteLinkGenerator
  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def generate!
    course = @group.course

    return blocked(:window_closed) unless course.grouping_window_open?
    return blocked(:group_confirmed) if @group.confirmed?

    @group.with_lock do
      @group.project_group_invite_links.find_by(sender: @current_user)&.destroy!

      link = @group.project_group_invite_links.create!(
        sender: @current_user,
        token: SecureRandom.urlsafe_base64(32),
        expires_at: 24.hours.from_now
      )

      Result.new(generated: true, blocked_reason: nil,
                 token: link.token, expires_at: link.expires_at)
    end
  end

  private

  def blocked(reason)
    Result.new(generated: false, blocked_reason: reason, token: nil, expires_at: nil)
  end

  class Result
    attr_reader :blocked_reason, :token, :expires_at

    def initialize(generated:, blocked_reason:, token:, expires_at:)
      @generated = generated
      @blocked_reason = blocked_reason
      @token = token
      @expires_at = expires_at
    end

    def generated? = @generated
    def blocked? = !generated?

    def message
      return 'Invite link generated.' if generated?

      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'Group already confirmed.'
      end
    end
  end
end
