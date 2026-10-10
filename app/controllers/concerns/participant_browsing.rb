# Shared list-filtering helpers for the course tab pages that render a browse
# table: the Groups tab (groups), the People tab (students half), and the Topics
# directory (list_state / filters_active? only). Extracted from
# CoursesController when the tabs became real routes (ADR 0019); the code itself
# is unchanged — it reads @course / @projects_by_owner / @group_list /
# @student_list off the including controller.
module ParticipantBrowsing
  extend ActiveSupport::Concern

  # Params that narrow a list. "all" is the selects' neutral choice and counts
  # as inactive, as does an absent/blank param.
  PARTICIPANT_FILTER_KEYS = %w[search_query lecturer_filter status_filter].freeze

  # A list renders one of three states, and only the first two are ever
  # displayed — a non-empty list renders rows and never consults the state:
  #
  #   :matched    — the filter returned rows
  #   :no_matches — the base has rows, the filter returned none
  #   :empty      — the base itself is empty; nothing has ever existed here
  #
  # The base is always the unfiltered, policy-scoped list, so a viewer whose
  # policy scope hides everything is :empty rather than a false "no matches"
  # (a student on a course with no approved topics has not filtered anything
  # out). Both arguments are loaded by the time this runs (ADR 0018).
  def list_state(base_list, filtered_list)
    return :matched if filtered_list.any?

    base_list.any? ? :no_matches : :empty
  end

  # True when any of the given filter params narrows the list. "all" is the
  # selects' neutral choice, so it does not count.
  def filters_active?(keys)
    keys.any? { |key| params[key].present? && params[key] != 'all' }
  end

  def search_groups(group_list, query)
    downcased_query = query.downcase

    group_list.select do |group|
      project = participant_project(group, 'ProjectGroup')

      group_name_match = group.group_name.downcase.include?(downcased_query)
      member_match = group.project_group_members.any? do |member|
        member.user.name.downcase.include?(downcased_query)
      end
      title_match = project&.current_title&.downcase&.include?(downcased_query) || false

      group_name_match || member_match || title_match
    end
  end

  def search_students(student_list, query)
    downcased_query = query.downcase

    student_list.select do |student|
      project = participant_project(student, 'User')

      name_match  = student.name.downcase.include?(downcased_query)
      id_match    = student.instid&.downcase&.include?(downcased_query) || false
      title_match = project&.current_title&.downcase&.include?(downcased_query) || false

      name_match || id_match || title_match
    end
  end

  def sort_descending?
    params[:sort_dir] == 'desc'
  end

  def participant_project(item, owner_type)
    @projects_by_owner[[owner_type, item.id]]
  end

  def sort_value_for_group(group)
    project = participant_project(group, 'ProjectGroup')
    case params[:sort_by]
    when 'status'
      Project::STATUS_SORT_ORDER.fetch(project&.current_status || 'not_submitted', 99)
    when 'project_title'
      project&.current_title&.downcase || ''
    when 'supervisor'
      project&.supervisor&.name&.downcase || ''
    else
      group.group_name.downcase
    end
  end

  def sort_value_for_student(student)
    project = participant_project(student, 'User')
    case params[:sort_by]
    when 'status'
      Project::STATUS_SORT_ORDER.fetch(project&.current_status || 'not_submitted', 99)
    when 'project_title'
      project&.current_title&.downcase || ''
    when 'supervisor'
      project&.supervisor&.name&.downcase || ''
    else
      student.name.downcase
    end
  end

  def supervised_owner_ids(owner_type)
    # only filters by lecturer_enrolment_ids. No coordinator_enrolment_ids
    return nil unless params[:lecturer_filter].present? && params[:lecturer_filter] != 'all'

    enrolment_ids = @course.enrolments.where(user_id: params[:lecturer_filter]).pluck(:id)
    return nil if enrolment_ids.empty?

    @course.projects.supervised_by(enrolment_ids).where(owner_type: owner_type).pluck(:owner_id)
  end

  def filtered_group_list
    group_list = @group_list

    if (ids = supervised_owner_ids('ProjectGroup'))
      group_list = group_list.select { |g| ids.include?(g.id) }
    end

    group_list = @course.groups_with_status(params[:status_filter], group_list) if params[:status_filter].present? && params[:status_filter] != 'all'

    group_list = search_groups(group_list, params[:search_query]) if params[:search_query].present?

    sorted_list = group_list.sort_by { |group| sort_value_for_group(group) }
    sort_descending? ? sorted_list.reverse : sorted_list
  end

  def filtered_student_list
    student_list = @student_list

    if (ids = supervised_owner_ids('User'))
      student_list = student_list.select { |s| ids.include?(s.id) }
    end

    student_list = @course.students_with_status(params[:status_filter], student_list) if params[:status_filter].present? && params[:status_filter] != 'all'

    student_list = search_students(student_list, params[:search_query]) if params[:search_query].present?

    sorted_list = student_list.sort_by { |student| sort_value_for_student(student) }
    sort_descending? ? sorted_list.reverse : sorted_list
  end
end
