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

    assert_nil @course.coursecode

    # The UI only renders the code/regenerate controls while joining via code
    # is enabled, so enable before generating.
    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: true } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    post update_coursecode_course_path(@course), params: { generate: true }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

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

  test 'should toggle the coursecode_enabled field in courses' do
    # Sign in the lecturer (coordinator)
    post session_path, params: { email_address: @lecturer.email_address, password: 'password' }
    assert_redirected_to root_path

    assert_nil @course.coursecode
    assert_equal @course.coursecode_enabled, false

    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: true } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    # The request should succeed and return turbo stream content
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type

    # The coursecode_enabled must be set to true
    @course.reload
    assert_equal @course.coursecode_enabled, true
  end

  test 'turning joining off wipes the stored coursecode' do
    post session_path, params: { email_address: @lecturer.email_address, password: 'password' }
    assert_redirected_to root_path

    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: true } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    post update_coursecode_course_path(@course), params: { generate: true }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_not_nil @course.reload.coursecode

    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: false } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :success
    @course.reload
    assert_not @course.coursecode_enabled
    assert_nil @course.coursecode
  end
end
