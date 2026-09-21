require 'test_helper'

class EnrolmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @student = create(:user, has_registered: false)
    @enrolment = create(:enrolment, user: @student, course: @course)
  end

  test 'coordinator can destroy a student enrolment in their own course' do
    sign_in @coordinator

    assert_difference('@course.enrolments.count', -1) do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end

    assert_redirected_to course_path(@course)
  end

  test 'an unauthenticated/non-coordinator user cannot destroy an enrolment' do
    attacker = create(:user)
    sign_in attacker

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end
  end

  test "coordinator of a different course cannot destroy this course's enrolment" do
    other_course = create(:course)
    other_coordinator = create(:user)
    create(:enrolment, :coordinator, user: other_coordinator, course: other_course)

    sign_in other_coordinator

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end
  end

  test 'client-submitted coordinator_id is ignored for authorization' do
    attacker = create(:user)
    sign_in attacker

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course, coordinator_id: @coordinator.id)
    end
  end

  test 'enrolment from another course cannot be deleted by course-scoped id' do
    other_course = create(:course)
    other_student = create(:user)
    other_enrolment = create(:enrolment, user: other_student, course: other_course)

    sign_in @coordinator

    delete enrolment_path(id: other_enrolment, course_id: @course)

    assert other_course.enrolments.reload.exists?(id: other_enrolment.id)
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
