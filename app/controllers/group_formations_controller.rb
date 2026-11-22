class GroupFormationsController < ApplicationController
  include RequiresGroupedCourse

  before_action :set_course
  before_action :ensure_grouped

  def show
    authorize @course, :grouping?

    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @my_group = @course.group_for(current_user)

    @my_group_can_confirm = @my_group.present? && !@my_group.confirmed? && @my_group.confirmable?

    @my_group_invite_token = @my_group.project_group_invite_links.find_by(sender: current_user)&.token if @my_group
    @incoming_join_requests = @my_group.present? ? @my_group.project_group_invites.pending_for_group(@my_group).where(kind: :direct_request).unexpired : []
    @incoming_direct_invites = ProjectGroupInvite.for_course(@course).sent_to(current_user).pending.where(kind: :direct_invite)
    @my_requested_group_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_request).unexpired.pluck(:project_group_id)
    @my_invited_student_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_invite).pluck(:recipient_id)

    @groups = @course.project_groups
                     .includes(:project, project_group_members: :user)
                     .order(:created_at)
    @ungrouped_students = @course.ungrouped_students

    @filtered_groups = filtered_groups
    @filters_active = formation_filters_active?
    @group_list_state = list_state(@groups, @filtered_groups)
    @total_group_count = @filtered_groups.count
    @show_all = params[:show_all] == 'true'
    @filtered_groups = @filtered_groups.first(Rails.application.config.participants_pagination_threshold) unless @show_all

    return unless request.headers['HX-Request']

    render partial: 'group_formations/groups_table',
           locals: {
             course: @course,
             groups: @filtered_groups,
             my_group: @my_group,
             requested_group_ids: @my_requested_group_ids,
             filters_active: @filters_active,
             list_state: @group_list_state,
             total_count: @total_group_count,
             displayed_count: @filtered_groups.count,
             show_all: @show_all
           }
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def filtered_groups
    groups = @groups.to_a
    status = params[:status_filter].to_s
    query = params[:search_query].to_s.strip.downcase

    groups = case status
             when 'confirmed'     then groups.select(&:confirmed?)
             when 'not_confirmed' then groups.reject(&:confirmed?)
             when 'invalid'       then groups.select { |group| helpers.group_size_state(group, @course) != :ok }
             else groups
             end

    if query.present?
      groups = groups.select do |group|
        group.group_name.to_s.downcase.include?(query) ||
          group.project_group_members.any? { |member| member.user.name.to_s.downcase.include?(query) }
      end
    end

    groups
  end

  def formation_filters_active?
    [params[:search_query], params[:status_filter]].any? { |value| value.present? && value != 'all' }
  end

  def list_state(base_list, filtered_list)
    return :matched if filtered_list.any?

    base_list.any? ? :no_matches : :empty
  end
end
