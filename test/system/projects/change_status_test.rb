require "application_system_test_case"

class ChangeStatusTest < ApplicationSystemTestCase
  setup do
    @course      = create(:course)
    @student     = create(:user, is_staff: false)
    @lecturer    = create(:user, is_staff: true)
    @other_student  = create(:user, is_staff: false)

    @student_enrolment  = create(:enrolment, user: @student, course: @course, role: :student)
    @lecturer_enrolment = create(:enrolment, user: @lecturer, course: @course, role: :lecturer)
    @other_student_enrolment = create(:enrolment, user: @other_student, course: @course, role: :student)

    @project = create(:project, course: @course, owner: @student, enrolment: @lecturer_enrolment)
    @instance = create(:project_instance, project: @project, enrolment: @lecturer_enrolment, created_by: @student, version: 1, status: :pending)
  end

  test "supervisor can change project status happy path" do
    login_as(@lecturer)
    visit course_project_path(@course, @project)

    select "Approved", from: "status"
    find('[data-testid="change-status-submit"]').click

    assert_selector '[data-testid="flash-notice"]'
    assert_selector '[data-testid="status-select"]', text: /approved/i  # /i is for case sensitive
  end

  test "student cannot change project status sad path" do
    login_as(@other_student)
    visit course_project_path(@course, @project)

    assert_no_selector '[data-testid="status-select"]'
    assert_no_selector '[data-testid="change-status-submit"]'
  end
end