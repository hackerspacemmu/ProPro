# View object for the courses/show Overview tab.
# Wraps the current user's enrolment and data collections to expose
# intention-revealing methods for section visibility in the view.
class OverviewPresenter
  attr_reader :pending_proposals, :reviewed_proposals, :pending_topics

  def initialize(enrolment:, approved_projects:, pending_proposals:, reviewed_proposals:, pending_topics:)
    @enrolment = enrolment
    @approved_projects = approved_projects
    @pending_proposals = pending_proposals
    @reviewed_proposals = reviewed_proposals
    @pending_topics = pending_topics
  end

  def show_supervised_projects? = !student?
  def show_pending_proposals?    = !student?
  def show_reviewed_proposals?   = !student?
  def show_pending_topics?       = coordinator?

  def supervised_projects = @approved_projects

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
