class ProgressUpdatesController < ApplicationController
  before_action :access
  before_action :supervisor_access, except: [:show]

  def show
    @progress_update = ProgressUpdate.find(params[:id])
  end

  def new
    @progress_update = ProgressUpdate.new
    @weeks = @course.number_of_updates
  end

  def edit
    @progress_update = ProgressUpdate.find(params[:id])
  end

  def create
    @progress_update = @project.progress_updates.build(
      rating: params[:progress_update][:rating],
      feedback: params[:progress_update][:feedback],
      date: params[:progress_update][:date]
    )

    if @progress_update.save
      redirect_to course_project_path(@course, @project)
    else
      @weeks = @course.number_of_updates
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @progress_update = ProgressUpdate.find(params[:id])
    if @progress_update.update(params.require(:progress_update).permit(:rating, :feedback, :date))
      redirect_to course_project_path(@course, @project)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @progress_update = ProgressUpdate.find(params[:id])
    @progress_update.destroy
    redirect_to course_project_path(@course, @project), notice: 'Progress update deleted successfully.'
  end

  private

  def access
    @course = Course.find(params[:course_id])
    @project = @course.projects.find(params[:project_id])
    @instances = @project.project_instances.order(version: :asc)
    @index = @instances.size
    @current_instance = @instances[@index - 1]
  end

  def supervisor_access
    return unless @current_instance.supervisor != current_user

    redirect_to(course_project_path(@course, @project), alert: 'You are not authorized')
  end
end
