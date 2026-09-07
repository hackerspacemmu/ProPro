require 'test_helper'

# Plain unit coverage for the Overview tab's presenter-driven states. No browser.
class OverviewPresenterTest < ActiveSupport::TestCase
  setup do
    @course = create(:course)
    @student = create(:user)
    @coordinator = create(:user)
    @student_enrolment = create(:enrolment, :student, user: @student, course: @course)
    @coordinator_enrolment = create(:enrolment, :coordinator, user: @coordinator, course: @course)
  end

  def presenter(enrolment:, description: nil, file_link: nil, submission_state: nil, submission: nil, toggle_topics: true)
    OverviewPresenter.new(
      enrolment: enrolment,
      approved_projects: [],
      pending_proposals: [],
      reviewed_proposals: [],
      pending_topics: [],
      course_description: description,
      file_link: file_link,
      submission_state: submission_state,
      submission: submission,
      toggle_topics: toggle_topics
    )
  end

  test 'project_details_empty? is true only when both description and file_link are blank' do
    assert presenter(enrolment: @coordinator_enrolment).project_details_empty?
    assert_not presenter(enrolment: @coordinator_enrolment, description: 'Brief').project_details_empty?
    assert_not presenter(enrolment: @coordinator_enrolment, file_link: 'http://example.test/spec.pdf').project_details_empty?
    assert_not presenter(enrolment: @coordinator_enrolment, description: 'Brief', file_link: 'http://example.test/spec.pdf').project_details_empty?
  end

  test 'show_project_details_add_cta? is coordinator-only and only when empty' do
    assert presenter(enrolment: @coordinator_enrolment).show_project_details_add_cta?
    assert_not presenter(enrolment: @coordinator_enrolment, description: 'Brief').show_project_details_add_cta?
    assert_not presenter(enrolment: @student_enrolment).show_project_details_add_cta?
    assert_not presenter(enrolment: nil).show_project_details_add_cta?
  end

  test 'show_my_submission? is student-only' do
    assert presenter(enrolment: @student_enrolment).show_my_submission?
    assert_not presenter(enrolment: @coordinator_enrolment).show_my_submission?
    assert_not presenter(enrolment: nil).show_my_submission?
  end

  test 'submission_state and submission pass through unchanged' do
    p = presenter(enrolment: @student_enrolment, submission_state: :approved, submission: :dummy_project)
    assert_equal :approved, p.submission_state
    assert_equal :dummy_project, p.submission
  end

  test 'existing section visibility predicates still hold' do
    assert presenter(enrolment: @coordinator_enrolment).show_supervised_projects?
    assert presenter(enrolment: @coordinator_enrolment).show_pending_topics?
    assert_not presenter(enrolment: @student_enrolment).show_supervised_projects?
    assert_not presenter(enrolment: @student_enrolment).show_pending_topics?
  end

  test 'show_pending_topics? is gated on the topics toggle' do
    assert_not presenter(enrolment: @coordinator_enrolment, toggle_topics: false).show_pending_topics?
    assert presenter(enrolment: @coordinator_enrolment, toggle_topics: true).show_pending_topics?
  end
end
