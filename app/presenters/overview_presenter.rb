# View object for the courses/show Overview tab.
# Wraps the current user's enrolment and data collections to expose
# intention-revealing methods for section visibility in the view.
class OverviewPresenter
  attr_reader :pending_proposals, :reviewed_proposals, :pending_topics, :submission, :submission_state,
              :course, :group, :current_user

  def initialize(enrolment:, approved_projects:, pending_proposals:, reviewed_proposals:, pending_topics:,
                 course_description:, file_link:, submission_state:, submission:, toggle_topics: true,
                 course: nil, group: nil, current_user: nil)
    @enrolment = enrolment
    @approved_projects = approved_projects
    @pending_proposals = pending_proposals
    @reviewed_proposals = reviewed_proposals
    @pending_topics = pending_topics
    @course_description = course_description
    @file_link = file_link
    @submission_state = submission_state
    @submission = submission
    @toggle_topics = toggle_topics
    @course = course
    @group = group
    @current_user = current_user
  end

  def show_supervised_projects? = !student?
  def show_pending_proposals?    = !student?
  def show_reviewed_proposals?   = !student?
  def show_pending_topics?       = coordinator? && @toggle_topics

  def supervised_projects = @approved_projects

  # Project Details — three states. Filled when EITHER description or file_link
  # is present (the mockup's "there's nothing here at all" only when BOTH blank).
  def project_details_empty?        = @course_description.blank? && @file_link.blank?
  def show_project_details_add_cta? = coordinator? && project_details_empty?

  def show_group_formation?
    return false unless coordinator? || lecturer?

    @course.present? && @course.grouped? && @course.grouping_enabled?
  end

  # Student My Group: student in a grouped course with group present
  def show_my_group?
    student? && @course&.grouped? && @group.present?
  end

  # My Submission — students only; hidden when student has an unconfirmed group
  def show_my_submission?
    student? && (@group.nil? || @group.confirmed?)
  end

  # Group formation window and count helpers
  def grouping_window_open?
    @course&.grouping_window_open? || false
  end

  def grouping_closes_at
    @course&.grouping_closes_at
  end

  def total_groups_count
    @total_groups_count ||= @course ? @course.project_groups.count : 0
  end

  def unconfirmed_groups_count
    @unconfirmed_groups_count ||= @course ? @course.project_groups.where(confirmed: false).count : 0
  end

  def confirmed_groups_count
    total_groups_count - unconfirmed_groups_count
  end

  def ungrouped_students_count
    @ungrouped_students_count ||= @course ? @course.ungrouped_students.count : 0
  end

  def show_formation_attention_banner?
    coordinator? && !grouping_window_open? && (unconfirmed_groups_count.positive? || ungrouped_students_count.positive?)
  end

  # My group helpers
  def my_group_confirmed?
    @group&.confirmed? || false
  end

  def my_group_leader?
    return false unless @group && @current_user

    @group.leader_id == @current_user.id
  end

  # nil means no maximum ("no limit" default); the view prints the bare count
  def group_max
    @course&.group_max
  end

  def any_sections?
    (show_supervised_projects? && @approved_projects.any?) ||
      (show_pending_proposals?   && @pending_proposals.any?) ||
      (show_reviewed_proposals?  && @reviewed_proposals.any?) ||
      (show_pending_topics?      && @pending_topics.any?)
  end

  def student?     = @enrolment&.student?
  def coordinator? = @enrolment&.coordinator?
  def lecturer?    = @enrolment&.lecturer?
end
