class ProjectGroupInviteLinksController < ApplicationController
  before_action :set_invite_link, only: %i[show redeem]

  def show; end

  def redeem
    unless @invite_link
      redirect_to root_path, alert: 'This invite link is invalid or has expired.'
      return
    end

    authorize @invite_link

    result = GroupInviteLinkRedeemer.new(@invite_link, current_user: current_user).redeem!

    if result.redeemed?
      redirect_to course_project_groups_path(result.group.course), notice: result.message
    else
      redirect_to project_group_invite_link_path(@invite_link.token), alert: result.message
    end
  end

  private

  def set_invite_link
    @invite_link = ProjectGroupInviteLink.find_by(token: params[:token])
  end
end
