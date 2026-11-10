require 'test_helper'

class GroupingSettingsSurfaceTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, group_min: 2, group_max: 4)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @student = create(:user)
    create(:enrolment, :student, user: @student, course: @course)
    sign_in @coordinator
  end

  test 'coordinator sees the grouping workspace status bar and the settings link' do
    get course_group_formation_path(@course)

    assert_response :success
    assert_match 'Group formation', response.body
    assert_match settings_course_path(@course), response.body
    assert_match '2–4 members per group', response.body
  end

  test 'settings uses the renamed grouping labels' do
    get settings_course_path(@course)

    assert_response :success
    assert_match 'Group Formation', response.body
    assert_match 'Prevent leftover students', response.body
    assert_no_match 'Default mode', response.body
    assert_no_match 'Auto-Confirmability', response.body
    assert_no_match 'Allow student grouping now', response.body
    assert_no_match 'Open from', response.body
    assert_no_match 'Set a window', response.body
  end

  test 'settings renders both grouping switches with hidden false fallbacks' do
    get settings_course_path(@course)

    assert_response :success
    assert_select 'input[type="hidden"][name="course[student_list_finalised]"][value="false"]'
    assert_select 'input[type="checkbox"][name="course[student_list_finalised]"]'
    assert_select 'input[type="hidden"][name="course[grouping_enabled]"][value="false"]'
    assert_select 'input[type="checkbox"][name="course[grouping_enabled]"]'
  end

  test 'coordinator saves both grouping switch values' do
    post handle_settings_course_path(@course),
         params: { course: settings_params(@course, grouping_enabled: 'true',
                                                    student_list_finalised: 'true',
                                                    group_min: '2', group_max: '4') }

    assert_redirected_to settings_course_path(@course)
    @course.reload
    assert @course.grouping_enabled?
    assert @course.student_list_finalised?
  end

  test 'saving settings does not change whether formation is open' do
    @course.update!(grouping_enabled: true, grouping_closes_at: 1.day.from_now)
    assert @course.grouping_window_open?

    post handle_settings_course_path(@course), params: { course: settings_params(@course) }

    assert_redirected_to settings_course_path(@course)
    assert @course.reload.grouping_window_open?
  end

  test 'the workspace explains an unlimited group size' do
    @course.update!(group_min: nil, group_max: nil)

    get course_group_formation_path(@course)

    assert_response :success
    assert_match 'No group size limit', response.body
  end

  test 'a student sees the workspace without the settings link' do
    sign_in @student

    get course_group_formation_path(@course)

    assert_response :success
    assert_match 'Group formation', response.body
    assert_match '2–4 members per group', response.body
  end

  private

  def settings_params(course, overrides = {})
    {
      course_name: course.course_name,
      course_description: course.course_description,
      starting_week: course.starting_week,
      supervisor_projects_limit: course.supervisor_projects_limit,
      student_access: course.student_access,
      lecturer_access: course.lecturer_access.to_s,
      require_coordinator_approval: course.require_coordinator_approval.to_s,
      auto_approve_copied_topics_without_changes: course.auto_approve_copied_topics_without_changes.to_s,
      use_progress_updates: course.use_progress_updates.to_s,
      number_of_updates: course.number_of_updates,
      toggle_topics: course.toggle_topics.to_s,
      file_link: course.file_link,
      supervisor_auto_calculate_enabled: '0',
      grouping_enabled: course.grouping_enabled?.to_s,
      student_list_finalised: course.student_list_finalised?.to_s,
      group_min: course.group_min.to_s,
      group_max: course.group_max.to_s,
      grouping_closes_at: course.grouping_closes_at&.strftime('%Y-%m-%dT%H:%M')
    }.merge(overrides)
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
