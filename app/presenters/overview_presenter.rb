# View object for the courses/show Overview tab.
# Wraps the current user's enrolment and data collections to expose
# intention-revealing methods for section visibility in the view.
class OverviewPresenter
  attr_reader :pending_proposals, :reviewed_proposals, :pending_topics, :submission, :submission_state

  def initialize(enrolment:, approved_projects:, pending_proposals:, reviewed_proposals:, pending_topics:,
                 course_description:, file_link:, submission_state:, submission:)
    @enrolment = enrolment
    @approved_projects = approved_projects
    @pending_proposals = pending_proposals
    @reviewed_proposals = reviewed_proposals
    @pending_topics = pending_topics
    @course_description = course_description
    @file_link = file_link
    @submission_state = submission_state
    @submission = submission
  end

  def show_supervised_projects? = !student?
  def show_pending_proposals?    = !student?
  def show_reviewed_proposals?   = !student?
  def show_pending_topics?       = coordinator?

  def supervised_projects = @approved_projects

  # Project Details — three states. Filled when EITHER description or file_link
  # is present (the mockup's "there's nothing here at all" only when BOTH blank).
  def project_details_empty?        = @course_description.blank? && @file_link.blank?
  def show_project_details_add_cta? = coordinator? && project_details_empty?

  # My Submission — students only; the state is resolved by the controller.
  def show_my_submission? = student?

  def any_sections?
    (show_supervised_projects? && @approved_projects.any?) ||
      (show_pending_proposals?   && @pending_proposals.any?) ||
      (show_reviewed_proposals?  && @reviewed_proposals.any?) ||
      (show_pending_topics?      && @pending_topics.any?)
  end

  private

  def student?     = @enrolment&.student?
  def coordinator? = @enrolment&.coordinator?
end
