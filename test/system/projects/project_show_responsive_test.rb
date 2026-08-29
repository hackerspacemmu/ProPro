require 'application_system_test_case'

class ProjectShowResponsiveTest < ApplicationSystemTestCase
  setup do
    @course      = create(:course)
    @student     = create(:user, is_staff: false)
    @student_enr = create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, is_staff: true, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)
    create(:enrolment, :lecturer, course: @course)
    create(:enrolment, :coordinator, course: @course)

    @project  = create(:project, course: @course, owner: @student,
                                 supervisor_enrolment: @lecturer_enr)
    @instance = create(:project_instance, project: @project, supervisor_enrolment: @lecturer_enr,
                                          created_by: @student, version: 1, status: :pending,
                                          title: 'My Proposal')
  end

  test 'show page exposes the comments drawer trigger, panel, and backdrop' do
    @instance.comments.create!(user: @student, text: 'A comment from the group')
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_selector 'button[data-comments-drawer-target="trigger"]'
    assert_selector "[data-comments-drawer-target='panel']"
    assert_selector "[data-comments-drawer-target='backdrop']"
    assert_text 'A comment from the group'
  end

  test 'show page renders the review actions and version switcher' do
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_selector 'h2', text: 'Review Project'
    assert_selector "select[data-controller='version-select']"
    assert_selector "select[data-controller='version-select'] option", text: /1 of 1/
  end

  test 'supervisor sees the Approve split-button on the latest version' do
    login_as(@lecturer)
    visit course_project_path(@course, @project)

    assert_selector 'button', text: 'Approve'
    assert_selector 'button', text: 'Request Changes'
  end

  test 'show page wires the sidebar drawer targets and toggle' do
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_selector '#app-sidebar[data-sidebar-target="container"]'
    assert_selector "[data-sidebar-target='backdrop']"
    assert_selector 'button[data-sidebar-target="toggleButton"][aria-expanded="false"]'
  end
end
