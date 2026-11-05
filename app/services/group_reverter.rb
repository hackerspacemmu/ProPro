class GroupReverter
  def initialize(group)
    @group = group
  end

  # Leader reverts a confirmed group to not confirmed if the grouping window is open.
  def revert!
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_draft) unless @group.confirmed?
      return blocked(:imported_group) if @group.origin_import?
      return blocked(:has_project) if @group.project.present?

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
      when :already_draft then 'This group is already a Not Confirmed Group.'
      when :imported_group then 'This group was imported, so it cannot be reopened.'
      when :has_project then 'This group already has a proposal, so it cannot be reopened.'
      when nil then 'Group status changed to not confirmed.'
      end
    end
  end
end
