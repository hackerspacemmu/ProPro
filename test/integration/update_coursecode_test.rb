require 'test_helper'

class UpdateCoursecodeTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @lecturer = create(:user, :staff)
    create(:enrolment, :coordinator, user: @lecturer, course: @course)
  end

  test 'should generate and display a course code via update_coursecode API' do
    # Sign in the lecturer (coordinator)
    post session_path, params: { email_address: @lecturer.email_address, password: 'password' }
    assert_redirected_to root_path

    # Initial state
    assert_nil @course.coursecode

    # Call the API explicitly
    post update_coursecode_course_path(@course), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    # The request should succeed and return turbo stream content
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type

    # The coursecode must be generated and saved to the course via the API call
    @course.reload
    assert_not_nil @course.coursecode

    # Check if there's a generated course code on the UI via the turbo stream response
    # It replaces the 'course_code_form' which contains the new course code string.
    assert_match @course.coursecode, response.body
  end
end
