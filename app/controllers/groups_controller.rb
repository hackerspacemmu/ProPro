# The Groups tab — /courses/:course_id/groups (route-per-tab, ADR 0019).
# One page: the full Groups view for an enrolled user, plus the htmx branch
# that used to be courses#show's `section=groups` dispatch (same partial, same
# locals). 404s on an ungrouped course: the tab does not exist there, so the
# route doesn't either.
class GroupsController < ApplicationController
  include ParticipantBrowsing

  before_action :set_course
  before_action :authorize_course
  before_action :ensure_grouped

  def index
    # Same preload the old courses#show carried: one query feeding the
    # projects_by_owner map every row and the search/sort helpers read.
    projects = @course.projects.includes(project_instances: { supervisor_enrolment: :user }).load
    @projects_by_owner = projects.index_by { |p| [p.owner_type, p.owner_id] }

    # Groups tab lists every project group, confirmed or draft — drafts are
    # real memberships and must not vanish from the table.
    @group_list = @course.project_groups.includes(project_group_members: :user).to_a

    @filtered_group_list = filtered_group_list
    @show_all = params[:show_all] == 'true'
    # Counts the matches, taken before the truncation below: the table footer's
    # "Showing X of Y" is about the current criteria, not the course total.
    @total_group_count = @filtered_group_list.count
    @filtered_group_list = @filtered_group_list.first(Rails.application.config.participants_pagination_threshold) unless @show_all

    # Empty vs no-matches, decided here rather than in the partials (ADR 0018).
    @group_list_state = list_state(@group_list, @filtered_group_list)
    # The filter controls sit outside the htmx-swapped containers, so the
    # partials are told a filter is active rather than re-deriving it from params.
    @filters_active = filters_active?(PARTICIPANT_FILTER_KEYS)

    return unless request.headers['HX-Request']

    render partial: 'courses/groups_table',
           locals: {
             course: @course,
             groups: @filtered_group_list,
             projects_by_owner: @projects_by_owner,
             total_count: @total_group_count,
             displayed_count: @filtered_group_list.count,
             show_all: @show_all,
             state: @group_list_state,
             filters_active: @filters_active
           }
    nil
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
  end

  def authorize_course
    authorize @course, :show?
  end

  def ensure_grouped
    raise ActiveRecord::RecordNotFound unless @course.grouped?
  end
end
