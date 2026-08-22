class ProjectGroupInvitesController < ApplicationController
  before_action :set_course
  before_action :set_group
  before_action :set_invite, only: %i[accept decline]

  def create
    authorize @group, :request_to_join?

    result = GroupDirectRequester.new(@group, current_user: current_user).request!

    if result.requested?
      redirect_to course_project_groups_path(@course), notice: result.message
    else
      redirect_to course_project_groups_path(@course), alert: result.message
    end
  end

  def direct_invite
    authorize @group, :direct_invite?
    recipient = User.find(params[:user_id])

    result = GroupDirectInviter.new(@group, current_user: current_user, recipient: recipient).invite!

    if result.invited?
      redirect_to course_project_groups_path(@course), notice: result.message
    else
      redirect_to course_project_groups_path(@course), alert: result.message
    end
  end

  def accept
    authorize @invite

    result = GroupInviteResponder.new(@invite, current_user: current_user).accept!

    if result.accepted?
      redirect_to course_project_groups_path(@course), notice: result.message
    else
      redirect_to course_project_groups_path(@course), alert: result.message
    end
  end

  def decline
    authorize @invite

    result = GroupInviteResponder.new(@invite, current_user: current_user).decline!

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

  def set_invite
    @invite = @group.project_group_invites.find(params[:id])
  end
end
