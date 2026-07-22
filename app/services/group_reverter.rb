# Leader reverts a confirmed group back to draft, if the grouping window is open.
class GroupReverter
  def initialize(group)
    @group = group
  end

  def revert!
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_draft) unless @group.confirmed?

      @group.update!(confirmed: false)
      Result.new(reverted: true, blocked_reason: nil)
    end
  end

  private

  def blocked(reason)
    Result.new(reverted: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(reverted:, blocked_reason:)
      @reverted = reverted
      @blocked_reason = blocked_reason
    end

    def reverted? = @reverted
  end
end