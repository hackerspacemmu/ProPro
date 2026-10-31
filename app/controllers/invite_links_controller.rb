class InviteLinksController < ApplicationController
  before_action :set_invite_link

  def show; end

  private

  def set_invite_link
    @invite_link = ProjectGroupInviteLink.find_by(token: params[:token])
  end
end
