class ProjectGroupInviteLinksController < ApplicationController
  def show
    @invite_link = ProjectGroupInviteLink.find_by(token: params[:token])
    # Skeleton — no redeem logic. GroupInviteLinkRedeemer lands session 8.
  end
end
