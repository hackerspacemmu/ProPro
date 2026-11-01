class GroupMembersController < ApplicationController
  before_action :set_course
  before_action :set_group

  def create
    if params[:user_id].blank?
      authorize @group, :join?
      result = GroupJoiner.new(@group, current_user: current_user).join!
      flash[result.joined? ? :notice : :alert] = result.message
    else
      authorize @course, :manage_groups?
      user = @course.students.find(params.expect(:user_id))
      result = GroupMemberAdder.new(@group, user: user, current_user: current_user).add!
      flash[result.added? ? :notice : :alert] = result.message
    end

    redirect_to course_group_formation_path(@course), status: :see_other
  end

  def destroy
    member = @group.project_group_members.find_by(id: params[:id])

    if member.nil?
      redirect_back fallback_location: course_group_formation_path(@course), alert: 'This member has already been removed.'
      return
    end

    authorize member, :destroy?

    result = GroupMemberRemover.new(
      member,
      current_user: current_user,
      dissolve_confirmed: params[:dissolve_confirmed] == 'true'
    ).remove!

    if result.needs_confirmation?
      render turbo_stream: turbo_stream.append(
        'modals',
        partial: 'group_members/dissolve_warning_modal',
        locals: { member: member, result: result }
      )
      return
    end

    # Turbo morphs the refreshed page and reloads its open management frame.
    # The redirect also handles browsers without a live stream connection.
    redirect_back fallback_location: course_group_formation_path(@course), status: :see_other,
                  **(result.blocked? ? { alert: result.message } : { notice: result.message })
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:group_id])
  end
end
