class ProgressUpdatesController < ApplicationController
before_action :access
  
def new

  @progress_update = @project.progress_updates.new
end

def create

  @progress_update = @project.progress_updates.new(params[:progress_update])

  if @progress_update.save
    redirect_to course_project_progress_update_path(@course, @project, @progress_update)
  else
    render :new
  end
end

def access 
  @course = Course.find(params[:course_id])
  @project = @course.projects.find(params[:project_id])
  @instances = @project.project_instances.order(version: :asc)
  @index = @instances.size
  @current_instance = @instances[@index - 1]

  if @current_instance.supervisor != current_user
    redirect_to(course_project_path(@course, @project), alert: "You are not authorized")
  end

end
end


