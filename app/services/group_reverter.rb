class GroupReverter
  def initialize(group)
    @group = group
  end

  # Leader reverts a confirmed group back to draft if the grouping window is open.
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

    def message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_draft then 'This group is already a draft.'
      when nil then 'Group reverted to draft.'
      end
    end
  end
end
