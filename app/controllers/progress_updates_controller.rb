class ProgressUpdatesController < ApplicationController
before_action :access

def show
  @progress_update = ProgressUpdate.find(params[:id])
end
  
def new
  @progress_update = ProgressUpdate.new
  @weeks = @course.number_of_updates
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

  redirect_to course_project_path(@course, @project)
end

def edit
  @progress_update = ProgressUpdate.find(params[:id])
end

def update
  @progress_update = ProgressUpdate.find(params[:id])
  if @progress_update.update(params.require(:progress_update).permit(:rating, :feedback, :date))      # 2
    redirect_to course_project_progress_update_path(@course, @project, @progress_update)   # 3a
  else
    render :edit, status: :unprocessable_entity                     # 3b
  end
end


def destroy
  @progress_update = ProgressUpdate.find(params[:id])
  @progress_update.destroy
  redirect_to course_project_path(@course, @project), notice: "Progress update deleted successfully."
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


