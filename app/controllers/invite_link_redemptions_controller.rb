class InviteLinkRedemptionsController < ApplicationController
  before_action :set_invite_link

  def create
    unless @invite_link
      redirect_to invite_link_path(params[:invite_link_token]), alert: 'This invite link is invalid or has expired.'
      return
    end

    authorize @invite_link, :redeem?

    result = GroupInviteLinkRedeemer.new(@invite_link, current_user: current_user).redeem!

    if result.redeemed?
      redirect_to course_group_formation_path(result.group.course), notice: result.message
    else
      redirect_to invite_link_path(@invite_link.token), alert: result.message
    end
  end

  private

  def set_invite_link
    @invite_link = ProjectGroupInviteLink.find_by(token: params[:invite_link_token])
  end
end
