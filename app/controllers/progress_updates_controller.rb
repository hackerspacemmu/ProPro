class ProgressUpdatesController < ApplicationController
  before_action :access
  before_action :supervisor_access

  def index
    raise ActiveRecord::RecordNotFound unless @course.use_progress_updates

    @progress = @project.progress_updates.order(date: :desc)
    @weeks = @course.number_of_updates
    @owner = @project.owner
    @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]
    @comments = @project.comments.order(created_at: :asc)
    @new_comment = Comment.new(user: current_user, location: @current_instance)
  end

  def create
    @progress_update = @project.progress_updates.build(
      rating: params[:progress_update][:rating],
      feedback: params[:progress_update][:feedback],
      date: params[:progress_update][:date]
    )

    flash[:alert] = @progress_update.errors.full_messages.to_sentence unless @progress_update.save

    redirect_to course_project_progress_updates_path(@course, @project)
  end

  def update
    @progress_update = ProgressUpdate.find(params[:id])
    flash[:alert] = @progress_update.errors.full_messages.to_sentence unless @progress_update.update(params.require(:progress_update).permit(:rating, :feedback, :date))

    redirect_to course_project_progress_updates_path(@course, @project)
  end

  def destroy
    @progress_update = ProgressUpdate.find(params[:id])
    @progress_update.destroy
    redirect_to course_project_progress_updates_path(@course, @project), notice: 'Progress update deleted successfully.'
  end

  private

  def access
    @course = Course.find(params[:course_id])
    @project = @course.projects.find(params[:project_id])
    @instances = @project.project_instances.order(version: :asc)
    @index = @instances.size
    @current_instance = @instances[@index - 1]
    @current_version = @index
    @latest_version = @instances.size
  end

  def supervisor_access
    return unless @current_instance.supervisor != current_user

    redirect_to(course_project_path(@course, @project), alert: 'You are not authorized')
  end
end
