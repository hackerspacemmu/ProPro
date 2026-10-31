class GroupFormationsController < ApplicationController
  before_action :set_course

  def show
    authorize @course, :grouping?

    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @my_group = @course.project_groups
                       .includes(project_group_members: :user)
                       .joins(:project_group_members)
                       .find_by(project_group_members: { user_id: current_user.id })

    @my_group_can_confirm = @my_group.present? && !@my_group.confirmed? && @my_group.confirmable?

    @my_group_invite_token = @my_group.project_group_invite_links.find_by(sender: current_user)&.token if @my_group
    @incoming_join_requests = @my_group.present? ? @my_group.project_group_invites.pending_for_group(@my_group).where(kind: :direct_request) : []
    @incoming_direct_invites = ProjectGroupInvite.for_course(@course).sent_to(current_user).pending.where(kind: :direct_invite)
    @my_requested_group_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_request).pluck(:project_group_id)
    @my_invited_student_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_invite).pluck(:recipient_id)

    @groups = @course.project_groups
                     .includes(project_group_members: :user)
                     .order(:created_at)
    enrolled_student_ids = @course.enrolments.where(role: :student).pluck(:user_id)
    grouped_student_ids = ProjectGroupMember.joins(:project_group)
                                            .where(project_groups: { course_id: @course.id })
                                            .pluck(:user_id)
    ungrouped_ids = enrolled_student_ids - grouped_student_ids
    @ungrouped_students = User.where(id: ungrouped_ids).order(:name)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end
end
