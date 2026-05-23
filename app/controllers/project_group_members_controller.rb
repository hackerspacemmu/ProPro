class ProjectGroupMembersController < ApplicationController
  before_action :set_course
  before_action :set_group

  def destroy
    begin
      authorize @course, :grouping_coordinator?

      user = User.find(params[:id])

      member = @group.project_group_members.find_by!(user: user)

      ActiveRecord::Base.transaction do
        member.destroy!

        current_member_count = @group.project_group_members.reload.count

        @group.revert_to_draft! if @group.confirmed? && current_member_count < @course.group_min.to_i
      end

      flash[:notice] = "#{user.name} removed from #{@group.group_name}."
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = 'The student or group membership could not be found.'
    rescue Pundit::NotAuthorizedError
      flash[:alert] = 'You are not authorized to remove students from this group.'
    rescue StandardError => e
      flash[:alert] = e.message
    end

    redirect_to course_project_groups_path(@course), status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:project_group_id])
  end
end
