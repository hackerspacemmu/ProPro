require 'application_system_test_case'

class ProjectVersioningTest < ApplicationSystemTestCase
  setup do
    @course   = create(:course)
    @student  = create(:user)
    @lecturer = create(:user)

    @student_enrolment  = create(:enrolment, :student, user: @student, course: @course)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @project    = create(:project, course: @course, owner: @student, supervisor_enrolment: @lecturer_enrolment)
    @instance_1 = create(:project_instance, project: @project, supervisor_enrolment: @lecturer_enrolment, created_by: @student, version: 1, status: :pending)
    @instance_2 = create(:project_instance, project: @project, supervisor_enrolment: @lecturer_enrolment, created_by: @student, version: 2, status: :pending)
  end

  test 'defaults to latest version on page load' do
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_selector 'select', text: /2 of 2/
  end

  test 'selecting version 1 navigates to previous version' do
    login_as(@student)
    visit course_project_path(@course, @project)

    first(:select).find('option', text: '1 of 2').select_option

    assert_selector 'select', text: /1 of 2/
  end

  test 'selecting version 2 navigates to next version' do
    login_as(@student)
    visit course_project_path(@course, @project, version: 1)

    first(:select).find('option', text: '2 of 2').select_option

    assert_selector 'select', text: /2 of 2/
  end

  test 'latest version shows current label' do
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_selector 'select', text: /Current/
  end
end
