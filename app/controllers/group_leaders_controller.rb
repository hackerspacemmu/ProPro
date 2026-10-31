class GroupLeadersController < ApplicationController
  before_action :set_course
  before_action :set_group

  def update
    authorize @group, :promote_leader?

    target_member = @group.project_group_members.find_by!(user_id: params[:user_id])

    begin
      @group.update!(leader_id: target_member.user_id)
    rescue StandardError => e
      redirect_to course_group_formation_path(@course), alert: e.message
      return
    end

    redirect_to course_group_formation_path(@course), notice: "#{target_member.user.name} is now the group leader."
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:group_id])
  end
end
