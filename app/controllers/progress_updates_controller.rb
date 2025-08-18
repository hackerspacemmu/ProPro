class ProgressUpdatesController < ApplicationController
before_action :access
  
def new
  @progress_update = ProgressUpdate.new
end

def create
  begin
    ActiveRecord::Base.transaction do
      @progress_update = ProgressUpdate.create!(
        project: @project,
        rating: params[:progress_update][:rating],
        feedback: params[:progress_update][:feedback],
        date: params[:progress_update][:date]
        )
    end
  rescue StandardError => e
    render :new, status: :unprocessable_entity
    return
  end

  #redirect_to course_project_progress_update_path(@course, @project, @progress_update)
end

def edit
end

def update
end

def delete
end

private

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


