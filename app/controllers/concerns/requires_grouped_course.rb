# Guards a group controller against courses that do not use groups. The
# callback must run after set_course.
module RequiresGroupedCourse
  private

  def ensure_grouped
    raise ActiveRecord::RecordNotFound unless @course&.grouped?
  end
end
