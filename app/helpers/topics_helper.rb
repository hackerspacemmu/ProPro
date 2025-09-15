module TopicsHelper
  def topic_viewable_by_current_user?(course, topic)
    # Coordinators can see everything
    return true if course.enrolments.exists?(user: current_user, role: :coordinator)
    
    owner = topic.owner

    # 1) Student-owned proposals (all statuses except rejected are OK)
    return true if owner.is_a?(User) &&
                   course.enrolments.exists?(user: owner, role: :student)

    # 2) Group-owned proposals (all members are students)
    return true if owner.is_a?(ProjectGroup) &&
                   owner.users.all? { |u| course.enrolments.exists?(user: u, role: :student) }

    # 3) Lecturer-proposed topics, but only once approved
    return true if topic.lecturer? && topic.status.to_s == "approved"

    false
  end

  def current_tab
    params[:tab] || 'details'
  end

  def show_progress_tab?
    @course.use_progress_updates && @current_instance.status == "approved"
  end
end
