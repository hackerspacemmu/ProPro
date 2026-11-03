require 'test_helper'

class StudentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @supervisor = create(:user, :staff, name: 'Sam Supervisor')
    @supervisor_enrolment = create(:enrolment, :lecturer, user: @supervisor, course: @course)

    @student = create(:user, name: 'Aisha Student')
    create(:enrolment, user: @student, course: @course)

    @project = create(:project,
                      course: @course,
                      owner: @student,
                      owner_type: 'User',
                      supervisor_enrolment: @supervisor_enrolment,
                      status: :pending)
    create(:project_instance,
           project: @project,
           supervisor_enrolment: @supervisor_enrolment,
           created_by: @student,
           title: 'Accessible Campus Navigation',
           status: :approved)
  end

  test 'shows each solo student with project title, status, and supervisor' do
    sign_in @coordinator
    get course_students_path(@course)

    assert_response :success
    assert_select 'nav[data-testid="content-tabs"] a[aria-current="page"]', text: 'Students'
    assert_select 'th', text: /Student/
    assert_select 'th', text: /Project Title/
    assert_select 'th', text: /Status/
    assert_select 'th', text: /Supervisor/
    assert_select 'kbd', text: '/', count: 0
    assert_select 'a[href=?]', course_person_path(@course, @student), text: @student.name
    assert_select 'a[href=?]', course_project_path(@course, @project), text: 'Accessible Campus Navigation'
    assert_select 'span', text: 'Approved'
    assert_includes response.body, @supervisor.name
  end

  test 'shows students without proposals as not submitted' do
    student_without_project = create(:user, name: 'No Proposal Yet')
    create(:enrolment, user: student_without_project, course: @course)

    sign_in @coordinator
    get course_students_path(@course)

    assert_response :success
    assert_includes response.body, 'No Proposal Yet'
    assert_select 'span', text: 'Not Submitted'
  end

  test 'htmx search can match a project title' do
    other_student = create(:user, name: 'Different Student')
    create(:enrolment, user: other_student, course: @course)

    sign_in @coordinator
    get course_students_path(@course),
        headers: { 'HTTP_HX_REQUEST' => 'true' },
        params: { search_query: 'campus navigation' }

    assert_response :success
    assert_includes response.body, @student.name
    assert_no_match 'Different Student', response.body
  end

  test 'htmx status filter returns only matching students' do
    student_without_project = create(:user, name: 'No Proposal Yet')
    create(:enrolment, user: student_without_project, course: @course)

    sign_in @coordinator
    get course_students_path(@course),
        headers: { 'HTTP_HX_REQUEST' => 'true' },
        params: { status_filter: 'approved' }

    assert_response :success
    assert_includes response.body, @student.name
    assert_no_match 'No Proposal Yet', response.body
  end

  test 'grouped courses do not expose the solo Students route' do
    grouped_course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator, course: grouped_course)

    sign_in @coordinator
    get course_students_path(grouped_course)

    assert_response :not_found
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
