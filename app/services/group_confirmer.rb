# Leader comfirms draft group if the grouping window is open and size is legal.
class GroupConfirmer
  def initialize(group)
    @group = group
  end

  def confirm!
    # Check group size and grouping window inside lock to avoid double race condition on submit
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_confirmed) if @group.confirmed?

      # calls the same algorithm as the preview
      legality = Queries::GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
      return blocked(:size_illegal) unless legality.includes_group_of_size?(@group.project_group_members.count)

      @group.update!(confirmed: true)
      Result.new(confirmed: true, blocked_reason: nil)
    end
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

    def message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_confirmed then 'This group has already been confirmed.'
      when :size_illegal then 'This group cannot be confirmed at its current size.'
      when nil then 'Group confirmed.'
      end
    end
  end
end
