class ProjectGroupInvitesController < ApplicationController
  before_action :set_course
  before_action :set_group
  before_action :set_join_request, only: %i[accept decline]

  def create
    authorize @group, :request_to_join?

    result = GroupJoinRequester.new(@group, current_user: current_user).request!

    if result.requested?
      redirect_to course_project_groups_path(@course), notice: result.message
    else
      redirect_to course_project_groups_path(@course), alert: result.message
    end
  end

  def accept
    authorize @join_request

    result = GroupJoinRequestResponder.new(@join_request, current_user: current_user).accept!

    if result.accepted?
      redirect_to course_project_groups_path(@course), notice: result.message
    else
      redirect_to course_project_groups_path(@course), alert: result.message
    end
  end

  def decline
    authorize @join_request

    result = GroupJoinRequestResponder.new(@join_request, current_user: current_user).decline!

    if result.declined?
      redirect_to course_project_groups_path(@course), notice: result.message
    else
      redirect_to course_project_groups_path(@course), alert: result.message
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:project_group_id])
  end

  def set_join_request
    @join_request = @group.project_group_invites.find(params[:id])
  end
end
