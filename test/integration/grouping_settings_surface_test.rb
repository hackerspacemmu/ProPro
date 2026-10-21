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
    get course_project_groups_path(@course)

    assert_response :success
    assert_match 'Grouping settings', response.body
    assert_match settings_course_path(@course), response.body
    assert_match 'Default mode', response.body
  end

  test 'coordinator sees the renamed mode labels on course settings' do
    get settings_course_path(@course)

    assert_response :success
    assert_match 'Default mode', response.body
    assert_match 'Auto-Confirmability mode', response.body
    assert_match 'Grouping mode', response.body
  end

  test 'a student sees the workspace without the settings link' do
    sign_in @student

    get course_project_groups_path(@course)

    assert_response :success
    assert_match 'Default mode', response.body
    assert_no_match(/Grouping settings/, response.body)
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
