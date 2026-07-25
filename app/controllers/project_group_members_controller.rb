class ProjectGroupMembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project_group_member, only: %i[destroy]

  def destroy
    authorize @project_group_member

    result = GroupMemberRemover.new(
      @project_group_member,
      current_user: current_user,
      dissolve_confirmed: params[:dissolve_confirmed] == 'true'
    ).remove!

    if result.needs_confirmation?
      render :confirm_dissolve, locals: { member: @project_group_member, result: result }
      return
    end

    if result.blocked?
      redirect_back fallback_location: root_path, alert: result.message
      return
    end

    redirect_back fallback_location: root_path, notice: result.message
  end

  private

  def set_project_group_member
    @project_group_member = ProjectGroupMember.find(params[:id])
  end
end