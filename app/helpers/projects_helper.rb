module ProjectsHelper
  def current_tab
    params[:tab] || 'details'
  end

  def show_progress_tab?
    @course.use_progress_updates && @current_instance.status == "approved"
  end

  def username(user_id)
    return nil unless user_id.present?
    User.find_by(id: user_id)&.username 
  end 
end
