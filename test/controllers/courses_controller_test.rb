require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator_user = create(:user)
    @coordinator_enrolment = create(:enrolment, :coordinator, user: @coordinator_user, course: @course)

    @lecturer_user = create(:user, :staff)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer_user, course: @course)

    @student_user = create(:user)
    @student_enrolment = create(:enrolment, user: @student_user, course: @course)
  end

  test "show renders successfully for coordinator" do
    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_select "button", text: "Project Details"
    assert_select "button", text: "To Review"
    assert_select "button", text: "Supervised Projects"
    assert_select "button", text: "Topic Directory"
    assert_select "button", text: "People"
  end

  test "show renders successfully for lecturer" do
    sign_in @lecturer_user
    get course_path(@course)
    assert_response :success
    assert_select "button", text: "Project Details"
    assert_select "button", text: "To Review"
    assert_select "button", text: "Supervised Projects"
  end

  test "show renders successfully for student" do
    sign_in @student_user
    get course_path(@course)
    assert_response :success
    assert_select "button", text: "Project Details"
    assert_select "button", text: "To Review"
    assert_select "button", text: "Topic Directory"
    assert_select "button", text: "People"
    assert_select "button", text: "Supervised Projects", count: 0
  end

  test "show displays pending proposals in to review tab" do
    sign_in @coordinator_user
    supervisor_enrolment = @coordinator_enrolment
    pending_project = create(:project, course: @course, supervisor_enrolment: supervisor_enrolment, status: :pending)
    create(:project_instance, project: pending_project, supervisor_enrolment: supervisor_enrolment, created_by: @student_user, status: :pending, title: "Test Proposal")

    get course_path(@course)
    assert_response :success
    assert_select "h2", text: "Pending Proposals"
  end

  test "show settings link uses settings_course_path" do
    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_select "a[href=?]", settings_course_path(@course), text: "Settings"
  end

  test "show displays course description in project details" do
    @course.update!(course_description: "My test description")
    sign_in @student_user
    get course_path(@course)
    assert_response :success
    assert_includes response.body, "My test description"
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
