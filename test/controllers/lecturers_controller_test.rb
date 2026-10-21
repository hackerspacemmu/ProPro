require 'test_helper'

class LecturersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator_user = create(:user)
    create(:enrolment, :coordinator, user: @coordinator_user, course: @course)

    @lecturer_user = create(:user, :staff)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer_user, course: @course)

    @student_user = create(:user)
    create(:enrolment, user: @student_user, course: @course)
  end

  test 'show renders the flat project/proposal rows for a lecturer' do
    supervised = create(:project, course: @course, owner: @student_user, owner_type: 'User',
                                  supervisor_enrolment: @lecturer_enrolment, status: :approved)
    create(:project_instance, project: supervised, supervisor_enrolment: @lecturer_enrolment,
                              status: :approved, title: 'My Student Project')

    incoming = create(:project, course: @course, owner: @student_user, owner_type: 'User',
                                supervisor_enrolment: @lecturer_enrolment, status: :pending)
    create(:project_instance, project: incoming, supervisor_enrolment: @lecturer_enrolment,
                              status: :pending, title: 'Incoming Proposal')

    sign_in @coordinator_user
    get course_lecturer_path(@course, @lecturer_user)
    assert_response :success
    assert_select 'h2', text: 'Supervised Projects'
    assert_select 'h2', text: 'Pending Proposals'
    assert_match 'My Student Project', response.body
    assert_match 'Incoming Proposal', response.body
  end

  test 'show renders the empty states when a lecturer supervises nothing' do
    other_lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: other_lecturer, course: @course)

    sign_in @coordinator_user
    get course_lecturer_path(@course, other_lecturer)
    assert_response :success
    assert_match 'Approved projects supervised by this lecturer will appear here.', response.body
    assert_match 'Proposals that are pending review will appear here.', response.body
    assert_match 'Proposals that were returned or rejected will appear here.', response.body
  end

  test 'show renders only the Topics section for a student when lecturer_access is off' do
    restricted = create(:course, lecturer_access: false)

    lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: lecturer, course: restricted)
    student = create(:user)
    create(:enrolment, user: student, course: restricted)
    create(:enrolment, :coordinator, user: @coordinator_user, course: restricted)
    topic = create(:topic, course: restricted, owner: lecturer, status: :approved)
    create(:topic_instance, topic: topic, status: :approved, title: 'Available Topic')

    sign_in student
    get course_lecturer_path(restricted, lecturer)
    assert_response :success
    assert_select 'h2', text: 'Topics'
    assert_select 'h2', text: 'Supervised Projects', count: 0
    assert_no_match 'Pending Proposals</h2>', response.body
  end

  test 'show hides the capacity strip for solo-supervisor courses' do
    solo = create(:course)
    solo_lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: solo_lecturer, course: solo)

    sign_in @coordinator_user
    get course_lecturer_path(solo, solo_lecturer)
    assert_response :success
    assert_no_match 'Supervisor Capacity', response.body
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
