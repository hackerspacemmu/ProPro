require 'test_helper'

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @student = create(:user)
    create(:enrolment, user: @student, course: @course)
  end

  test 'renders for a coordinator' do
    sign_in @coordinator
    get course_person_path(@course, @student)
    assert_response :success
    assert_select 'h1#student-name', text: @student.name
  end

  test 'a student from another course 404s' do
    outsider = create(:user)
    create(:enrolment, user: outsider, course: create(:course))

    sign_in @coordinator
    get course_person_path(@course, outsider)
    assert_response :not_found
  end

  test 'an invited (unregistered) student resolves' do
    invited = create(:user, has_registered: false)
    create(:enrolment, user: invited, course: @course)

    sign_in @coordinator
    get course_person_path(@course, invited)
    assert_response :success
    assert_select 'h1#student-name', text: invited.name
  end

  test 'Remove From Course renders only for a coordinator' do
    sign_in @coordinator
    get course_person_path(@course, @student)
    assert_match 'Remove From Course', response.body

    sign_in @student
    get course_person_path(@course, @student)
    assert_no_match 'Remove From Course', response.body
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
