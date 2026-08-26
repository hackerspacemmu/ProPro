require 'application_system_test_case'

class CourseTabsTest < ApplicationSystemTestCase
  setup do
    @course = create(:course)

    @coordinator_user = create(:user)
    @coordinator_enrolment = create(:enrolment, :coordinator, user: @coordinator_user, course: @course)

    @lecturer_user = create(:user, :staff)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer_user, course: @course)

    @student_user = create(:user)
    create(:enrolment, user: @student_user, course: @course)
  end

  test "coordinator sees all five tabs" do
    login_as @coordinator_user
    visit course_path(@course)

    assert_text "Project Details"
    assert_text "To Review"
    assert_text "Supervised Projects"
    assert_text "Topic Directory"
    assert_text "People"
    assert_text "Settings"
  end

  test "lecturer sees all five tabs" do
    login_as @lecturer_user
    visit course_path(@course)

    assert_text "Project Details"
    assert_text "To Review"
    assert_text "Supervised Projects"
    assert_text "Topic Directory"
    assert_text "People"
    assert_text "Settings"
  end

  test "student sees four tabs no supervised projects" do
    login_as @student_user
    visit course_path(@course)

    assert_text "Project Details"
    assert_text "To Review"
    assert_text "Topic Directory"
    assert_text "People"
    assert_text "Settings"
    assert_no_text "Supervised Projects"
  end

  test "to review tab shows pending proposals" do
    pending_project = create(:project, course: @course, supervisor_enrolment: @coordinator_enrolment, status: :pending)
    create(:project_instance, project: pending_project, supervisor_enrolment: @coordinator_enrolment, created_by: @student_user, status: :pending, title: "Test Proposal")

    login_as @coordinator_user
    visit course_path(@course)

    click_button "To Review"
    assert_text "Pending Proposals"
    assert_text "Test Proposal"
  end

  test "to review tab shows reviewed proposals" do
    redo_project = create(:project, course: @course, supervisor_enrolment: @coordinator_enrolment, status: :redo)
    create(:project_instance, project: redo_project, supervisor_enrolment: @coordinator_enrolment, created_by: @student_user, status: :redo, title: "Redo Proposal")

    login_as @coordinator_user
    visit course_path(@course)

    click_button "To Review"
    assert_text "Reviewed Proposals"
    assert_text "Redo Proposal"
  end

  test "supervised projects tab shows only approved projects" do
    approved = create(:project, course: @course, supervisor_enrolment: @lecturer_enrolment, status: :approved)
    create(:project_instance, project: approved, supervisor_enrolment: @lecturer_enrolment, created_by: @student_user, status: :approved, title: "Approved Project")

    login_as @lecturer_user
    visit course_path(@course)

    click_button "Supervised Projects"
    assert_text "Approved Project"
  end

  test "settings link uses correct path" do
    login_as @coordinator_user
    visit course_path(@course)

    click_link "Settings"
    assert_current_path settings_course_path(@course)
  end

  test "project details tab shows course description" do
    @course.update!(course_description: "Test course description")
    login_as @student_user
    visit course_path(@course)

    assert_text "Test course description"
  end
end
