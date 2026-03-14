require "application_system_test_case"

class ProjectVersioningTest < ApplicationSystemTestCase
  setup do
    @course   = create(:course)
    @student  = create(:user, is_staff: false)
    @lecturer = create(:user, is_staff: true)

    @student_enrolment  = create(:enrolment, :student, user: @student, course: @course)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @project    = create(:project, course: @course, owner: @student, enrolment: @lecturer_enrolment)
    @instance_1 = create(:project_instance, project: @project, enrolment: @lecturer_enrolment, created_by: @student, version: 1, status: :pending)
    @instance_2 = create(:project_instance, project: @project, enrolment: @lecturer_enrolment, created_by: @student, version: 2, status: :pending)
  end

  test "defaults to latest version on page load" do
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_selector '[data-testid="current-version"]', text: /2 of 2/i
  end

  test "clicking back navigates to previous version" do
    login_as(@student)
    visit course_project_path(@course, @project)

    find('[data-testid="version-back"]').click

    assert_selector '[data-testid="current-version"]', text: /1 of 2/i
  end

  test "clicking next navigates to next version" do
    login_as(@student)
    visit course_project_path(@course, @project, version: 1)

    find('[data-testid="version-next"]').click

    assert_selector '[data-testid="current-version"]', text: /2 of 2/i
  end

  test "back button is disabled on version 1" do
    login_as(@student)
    visit course_project_path(@course, @project, version: 1)

    assert_no_selector '[data-testid="version-back"]'
  end

  test "next button is disabled on latest version" do
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_no_selector '[data-testid="version-next"]'
  end
end