require 'application_system_test_case'

# Tab strip + high-level slate coverage for courses/show. The old To Review tab
# was removed in the Overview refactor (its content moved into the Overview
# tab), the Settings link is now a coordinator-only icon, and ?tab= is a no-op
# on load (current_tab_index reads only the persisted cookie) — this file no
# longer asserts any of those.
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

  test 'coordinator sees the tab set and settings' do
    login_as @coordinator_user
    visit course_path(@course)

    %w[Overview Topics People].each { |tab| assert_text tab }
    assert_no_text 'To Review'
    assert_no_text 'Groups'
    assert_selector 'a[title="Settings"]'
  end

  test 'lecturer sees the tab set without settings' do
    login_as @lecturer_user
    visit course_path(@course)

    %w[Overview Topics People].each { |tab| assert_text tab }
    assert_no_text 'To Review'
    assert_no_text 'Groups'
    assert_no_selector 'a[title="Settings"]'
  end

  test 'student sees the tab set without settings' do
    login_as @student_user
    visit course_path(@course)

    %w[Overview Topics People].each { |tab| assert_text tab }
    assert_no_text 'To Review'
    assert_no_text 'Groups'
    assert_no_selector 'a[title="Settings"]'
    assert_text 'My Submission'
    assert_link 'Create proposal', href: new_course_project_path(@course)
  end

  test 'overview shows pending proposals to the coordinator' do
    pending_project = create(:project, course: @course, supervisor_enrolment: @coordinator_enrolment, status: :pending)
    create(:project_instance, project: pending_project, supervisor_enrolment: @coordinator_enrolment, created_by: @student_user, status: :pending, title: 'Test Proposal')

    login_as @coordinator_user
    visit course_path(@course)

    assert_text 'Pending Proposals'
    assert_text 'Test Proposal'
  end

  test 'overview shows reviewed proposals to the coordinator' do
    redo_project = create(:project, course: @course, supervisor_enrolment: @coordinator_enrolment, status: :redo)
    create(:project_instance, project: redo_project, supervisor_enrolment: @coordinator_enrolment, created_by: @student_user, status: :redo, title: 'Redo Proposal')

    login_as @coordinator_user
    visit course_path(@course)

    assert_text 'Reviewed Proposals'
    assert_text 'Redo Proposal'
  end

  test 'overview supervised projects shows only approved projects' do
    approved = create(:project, course: @course, supervisor_enrolment: @lecturer_enrolment, status: :approved)
    create(:project_instance, project: approved, supervisor_enrolment: @lecturer_enrolment, created_by: @student_user, status: :approved, title: 'Approved Project')

    login_as @lecturer_user
    visit course_path(@course)

    assert_text 'Approved Project'
  end

  test 'settings link uses correct path' do
    login_as @coordinator_user
    visit course_path(@course)

    find('a[title="Settings"]').click
    assert_current_path settings_course_path(@course)
  end

  test 'project details card shows course description' do
    @course.update!(course_description: 'Test course description')
    login_as @student_user
    visit course_path(@course)

    assert_text 'Project Details'
    assert_text 'Test course description'
  end

  test 'overview tab is selected by default' do
    login_as @coordinator_user
    visit course_path(@course)

    assert_selector 'button[aria-selected="true"]', text: 'Overview'
  end
end
