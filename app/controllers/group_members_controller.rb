class GroupMembersController < ApplicationController
  include RequiresGroupedCourse

  before_action :set_course
  before_action :ensure_grouped
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

    redirect_to return_target, status: :see_other
  end

  def destroy
    member = @group.project_group_members.find_by(id: params[:id])

    if member.nil?
      redirect_to return_target, status: :see_other,
                                 alert: 'This member has already been removed.'
      return
    end

    authorize member, :destroy?

    result = remove_member(member)

    if result.needs_confirmation?
      render turbo_stream: turbo_stream.append(
        'modals',
        partial: 'group_members/last_member_warning_modal',
        locals: { member: member, result: result }
      )
      return
    end

    redirect_to return_target, status: :see_other,
                               **(result.blocked? ? { alert: result.message } : { notice: result.message })
  end

  private

  def return_target
    url_from(params[:return_to]) || course_group_formation_path(@course)
  end

  def remove_member(member)
    if coordinator?
      Groups::Coordinator::MemberRemover.new(member, confirm: params[:confirm] == 'true').remove!
    elsif member.user_id == current_user.id
      Groups::Leaver.new(member).leave!
    else
      Groups::Kicker.new(member, current_user: current_user).kick!
    end
  end

  def coordinator?
    @course.enrolments.exists?(user_id: current_user.id, role: :coordinator)
  end

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:group_id])
  end
end
