class GroupJoinRequestsController < ApplicationController
  before_action :set_course
  before_action :set_group
  before_action :set_invite, only: :update

  def create
    authorize @group, :request_to_join?

    result = GroupDirectRequester.new(@group, current_user: current_user).request!

    if result.requested?
      redirect_to course_group_formation_path(@course), notice: result.message
    else
      redirect_to course_group_formation_path(@course), alert: result.message
    end
  end

  def update
    status = params[:status]

    unless %w[accepted declined].include?(status)
      redirect_to course_group_formation_path(@course), alert: 'Invalid invite response.'
      return
    end

    authorize @invite, status == 'accepted' ? :accept? : :decline?

    result = GroupInviteResponder.new(@invite, current_user: current_user)
                                 .public_send(status == 'accepted' ? :accept! : :decline!)

    if result.accepted? || result.declined?
      redirect_to course_group_formation_path(@course), notice: result.message
    else
      redirect_to course_group_formation_path(@course), alert: result.message
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:group_id])
  end

  def set_invite
    @invite = @group.project_group_invites.direct_request.find(params[:id])
  end
end
