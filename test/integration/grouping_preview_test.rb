require 'test_helper'

class GroupingPreviewTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, student_list_finalised: true,
                                        group_min: 2, group_max: 4)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @student = create(:user)
    create(:enrolment, :student, user: @student, course: @course)
  end

  test 'renders the group count and size breakdown for a valid student count' do
    sign_in @coordinator
    get grouping_preview_course_path(@course), params: { student_count: 10 }

    assert_response :success
    assert_match '10 students &rarr; 3 groups', response.body
    assert_match '1 of 4, 2 of 3', response.body
  end

  test 'uses the singular group wording for one group' do
    sign_in @coordinator
    get grouping_preview_course_path(@course), params: { student_count: 2 }

    assert_response :success
    assert_match '2 students &rarr; 1 group', response.body
    assert_match '1 of 2', response.body
  end

  test 'renders the error paragraph and no result line for an impossible count' do
    sign_in @coordinator
    get grouping_preview_course_path(@course), params: { student_count: 1 }

    assert_response :success
    assert_select 'p.text-red-600', text: 'No legal group size combination exists for this number of students.'
    assert_no_match 'students &rarr;', response.body
  end

  test 'a student cannot preview the grouping distribution' do
    sign_in @student
    get grouping_preview_course_path(@course), params: { student_count: 10 }

    assert_redirected_to dashboard_path
    assert_equal 'You are not authorized to view this page.', flash[:alert]
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
