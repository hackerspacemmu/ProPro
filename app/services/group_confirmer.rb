# Leader comfirms draft group if formation is open and size is legal.
class GroupConfirmer
  include Groups::GroupLocking

  def initialize(group)
    @group = group
  end

  def confirm!
    course = @group.course

    result = course.with_no_key_update_lock do
      with_group_lock(@group) do
        return blocked(:formation_closed) unless course.group_formation_open?
        return blocked(:already_confirmed) if @group.confirmed?

        return blocked(:size_illegal) unless @group.confirmable?

        @group.update!(confirmed: true, group_name: course.lowest_free_confirmed_group_name(excluding: @group))
        @group.clear_invite_links!
        Result.new(confirmed: true, blocked_reason: nil)
      end
    end

    return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

    result
  end

  private

  def blocked(reason)
    Result.new(confirmed: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(confirmed:, blocked_reason:)
      @confirmed = confirmed
      @blocked_reason = blocked_reason
    end

    def confirmed? = @confirmed
    def blocked? = !confirmed?

    def message
      case blocked_reason
      when :formation_closed then 'Group formation is closed.'
      when :already_confirmed then 'This group has already been confirmed.'
      when :size_illegal then 'This group cannot be confirmed at its current size.'
      when :group_gone then 'This group no longer exists.'
      when nil then 'Group confirmed.'
      end
    end
  end
end
