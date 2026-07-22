# Leader confirms a draft group, if the grouping window is open and size is legal.
# Authorization (leader-only) lives in Pundit; this service only re-checks
# window + legality against the DB, inside a lock, to close the double-submit race.
class GroupConfirmer
  def initialize(group)
    @group = group
  end

  def confirm!
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_confirmed) if @group.confirmed?

      legality = GroupSizeLegalityCalculator.new(course, students_to_group: course.students.count).execute
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
  end
end