require 'test_helper'

class OverviewPresenterTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped, group_formation_enabled: true)
    @student = create(:user)
    @coordinator = create(:user)
    @lecturer = create(:user)
    @student_enrolment = create(:enrolment, :student, user: @student, course: @course)
    @coordinator_enrolment = create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer, course: @course)
  end

  def presenter(enrolment:, description: nil, file_link: nil, submission_state: nil, submission: nil, toggle_topics: true, course: @course, group: nil, current_user: nil)
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
      toggle_topics: toggle_topics,
      course: course,
      group: group,
      current_user: current_user
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

  test 'show_my_submission? is true for students with no group or confirmed group, and false for unconfirmed group' do
    confirmed_group = create(:project_group, course: @course, confirmed: true)
    unconfirmed_group = create(:project_group, course: @course, confirmed: false)

    # Student with no group: true (shows empty state)
    assert presenter(enrolment: @student_enrolment, group: nil).show_my_submission?

    # Student with confirmed group: true (shows submission or no proposal empty state)
    assert presenter(enrolment: @student_enrolment, group: confirmed_group).show_my_submission?

    # Student with unconfirmed group: false (hidden entirely)
    assert_not presenter(enrolment: @student_enrolment, group: unconfirmed_group).show_my_submission?

    # Staff: false
    assert_not presenter(enrolment: @coordinator_enrolment, group: confirmed_group).show_my_submission?
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

  test 'show_group_formation? is visible for coordinator and lecturer when grouped and enabled' do
    assert presenter(enrolment: @coordinator_enrolment).show_group_formation?
    assert presenter(enrolment: @lecturer_enrolment).show_group_formation?
    assert_not presenter(enrolment: @student_enrolment).show_group_formation?

    # Non-grouped course hides group formation
    non_grouped = create(:course, grouped: false)
    coord_non_grouped = create(:enrolment, :coordinator, user: @coordinator, course: non_grouped)
    assert_not presenter(enrolment: coord_non_grouped, course: non_grouped).show_group_formation?

    # Grouping disabled hides group formation
    disabled_course = create(:course, :grouped, group_formation_enabled: false)
    coord_disabled = create(:enrolment, :coordinator, user: @coordinator, course: disabled_course)
    assert_not presenter(enrolment: coord_disabled, course: disabled_course).show_group_formation?
  end

  test 'show_my_group? is true only for student in a grouped course with group present' do
    group = create(:project_group, course: @course, confirmed: false)

    assert presenter(enrolment: @student_enrolment, group: group).show_my_group?
    assert_not presenter(enrolment: @student_enrolment, group: nil).show_my_group?
    assert_not presenter(enrolment: @coordinator_enrolment, group: group).show_my_group?

    non_grouped = create(:course, grouped: false)
    student_non_grouped = create(:enrolment, :student, user: @student, course: non_grouped)
    assert_not presenter(enrolment: student_non_grouped, course: non_grouped, group: group).show_my_group?
  end

  test 'formation counts and attention banner helper' do
    create(:project_group, course: @course, confirmed: true)
    create(:project_group, course: @course, confirmed: false)
    ungrouped_student = create(:user)
    create(:enrolment, :student, user: ungrouped_student, course: @course)

    p = presenter(enrolment: @coordinator_enrolment, course: @course)
    assert_equal 2, p.total_groups_count
    assert_equal 1, p.unconfirmed_groups_count
    assert_equal 1, p.confirmed_groups_count
    assert_equal 2, p.ungrouped_students_count

    # Formation is open -> no banner
    assert_not p.show_formation_attention_banner?

    # Formation closed -> banner shows for coordinator
    @course.update!(group_formation_closes_at: 1.hour.ago)
    p_closed = presenter(enrolment: @coordinator_enrolment, course: @course)
    assert p_closed.show_formation_attention_banner?

    # Lecturer does not see banner
    p_lecturer_closed = presenter(enrolment: @lecturer_enrolment, course: @course)
    assert_not p_lecturer_closed.show_formation_attention_banner?
  end

  test 'my_group helper methods' do
    group = create(:project_group, course: @course, confirmed: false, leader_id: @student.id)

    p_leader = presenter(enrolment: @student_enrolment, group: group, current_user: @student)
    assert_not p_leader.my_group_confirmed?
    assert p_leader.my_group_leader?

    other_user = create(:user)
    p_member = presenter(enrolment: @student_enrolment, group: group, current_user: other_user)
    assert_not p_member.my_group_leader?
  end

  test 'group_max passes the course value through; nil means no maximum' do
    assert_nil presenter(enrolment: @student_enrolment).group_max

    @course.update!(group_max: 4)
    assert_equal 4, presenter(enrolment: @student_enrolment).group_max
  end
end
