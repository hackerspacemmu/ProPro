class ProjectVersionComparisonsController < ApplicationController
  include VersionBrowsing

  before_action :set_course
  before_action :set_project

  def show
    authorize @project, :show?

    load_versions(@project.project_instances.order(version: :asc))

    @owner = @project.owner
    @status = @project.status
    @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]

    @comments = @project.comments.order(created_at: :asc)
    @new_comment = Comment.new(user: current_user, location: @current_instance)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_project
    @project = @course.projects.find_by(id: params[:project_id])
    return if @project

    redirect_to course_path(@course), alert: 'Project not found.' and return
  end
end
