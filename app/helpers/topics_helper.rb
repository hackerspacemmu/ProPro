module TopicsHelper
  def show_progress_tab?
    @course.use_progress_updates && @current_instance.status == 'approved'
  end
end
