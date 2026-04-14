require 'test_helper'

class EnrollViaCoursecodeTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @course.generate_coursecode! # Ensures a valid code is created

    @student = create(:user, is_staff: false)
  end

  test 'should successfully enroll in course with valid coursecode' do
    @course.update!(coursecode_enabled: true)

    # Sign in the student
    post session_path, params: { email_address: @student.email_address, password: 'password' }
    assert_redirected_to root_path

    # Check initial enrolment state
    assert_not @course.students.include?(@student)

    # Submit valid coursecode
    post invite_path, params: { coursecode: @course.coursecode }

    # The student is redirected to '/' and sees a success message
    assert_redirected_to '/'
    assert_equal 'Successfully joined the course', flash[:notice]

    # Verify that an enrolment was created
    assert @course.students.include?(@student)
  end

  test 'should notify students that they are already enrolled in the course' do
    @course.update!(coursecode_enabled: true)

    # Sign in the student
    post session_path, params: { email_address: @student.email_address, password: 'password' }
    assert_redirected_to root_path

    # Submit valid coursecode (and again)
    post invite_path, params: { coursecode: @course.coursecode }
    post invite_path, params: { coursecode: @course.coursecode }

    # The student is redirected to '/' and sees a success message
    assert_redirected_to '/'
    assert_equal 'You already joined the course', flash[:notice]
  end

  test 'should display error for invalid coursecode' do
    # Sign in the student
    post session_path, params: { email_address: @student.email_address, password: 'password' }
    assert_redirected_to root_path

    # Run POST with an invalid course code
    post invite_path, params: { coursecode: 'INVALIDCODE123' }

    # Student cannot join, is redirected with an error alert
    assert_redirected_to '/'
    assert_equal 'Invalid course code', flash[:alert]

    # Check that they did not join the course
    assert_not @course.students.include?(@student)
  end
end
