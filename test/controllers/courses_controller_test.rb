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

  test 'show renders successfully for coordinator' do
    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_select 'button', text: 'Overview'
    assert_select 'button', text: 'Topics'
    assert_select 'button', text: 'People'
    assert_select 'button', text: 'Groups'
  end

  test 'show renders successfully for lecturer' do
    sign_in @lecturer_user
    get course_path(@course)
    assert_response :success
    assert_select 'button', text: 'Overview'
    assert_select 'button', text: 'Topics'
  end

  test 'show renders successfully for student' do
    sign_in @student_user
    get course_path(@course)
    assert_response :success
    assert_select 'button', text: 'Overview'
    assert_select 'button', text: 'Topics'
    assert_select 'button', text: 'People'
  end

  test 'show displays pending proposals in overview tab' do
    sign_in @coordinator_user
    supervisor_enrolment = @coordinator_enrolment
    pending_project = create(:project, course: @course, supervisor_enrolment: supervisor_enrolment, status: :pending)
    create(:project_instance, project: pending_project, supervisor_enrolment: supervisor_enrolment, created_by: @student_user, status: :pending, title: 'Test Proposal')

    get course_path(@course)
    assert_response :success
    assert_select 'h2', text: 'Pending Proposals'
  end

  test 'show settings link uses settings_course_path' do
    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_select 'a[href=?]', settings_course_path(@course), count: 1
  end

  test 'show displays course description in project details' do
    @course.update!(course_description: 'My test description')
    sign_in @student_user
    get course_path(@course)
    assert_response :success
    assert_includes response.body, 'My test description'
  end

  test 'show renders People and Groups tabs with matching panel set' do
    sign_in @student_user
    get course_path(@course)
    assert_response :success

    assert_select "button[data-tabs-target='tab']", count: 4
    assert_select "div[data-tabs-target='panel']", count: 4
    assert_select 'button', text: 'Groups'
    assert_select 'section', text: /Students/
  end

  test 'show renders supervisor capacity only for non-solo courses' do
    course = create(:course)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    lecturer_a = create(:user, :staff)
    lecturer_b = create(:user, :staff)
    create(:enrolment, :lecturer, user: lecturer_a, course: course)
    create(:enrolment, :lecturer, user: lecturer_b, course: course)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_match %r{0/5}, response.body
  end

  test 'show omits the capacity bar for an excluded lecturer (effective cap zero)' do
    course = create(:course)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    lecturer_a = create(:user, :staff)
    lecturer_b = create(:user, :staff)
    create(:enrolment, :lecturer, user: lecturer_a, course: course)
    create(:enrolment, :lecturer, user: lecturer_b, course: course)
    course.enrolments.find_by(user: lecturer_a).update!(supervisor_capacity_excluded: true)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_no_match %r{0/0}, response.body
  end

  test 'capacity bar fill uses an inline width style, not a dynamic tailwind class' do
    course = create(:course)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    lecturer_a = create(:user, :staff)
    lecturer_b = create(:user, :staff)
    create(:enrolment, :lecturer, user: lecturer_a, course: course)
    create(:enrolment, :lecturer, user: lecturer_b, course: course)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_includes response.body, 'style="width: 0.0% ; background-color: #137333"'
    assert_no_match(/w-\[<%= ratio/, response.body)
  end

  test 'groups tab renders the supervisor filter select for non-solo courses' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    create(:enrolment, :lecturer, user: create(:user, :staff), course: course)
    create(:enrolment, :lecturer, user: create(:user, :staff), course: course)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_select 'select#lecturer-filter[name="lecturer_filter"]', count: 1
    assert_includes response.body, 'All Supervisors'
  end

  test 'groups tab omits the supervisor filter for solo-supervisor courses' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    create(:enrolment, :lecturer, user: create(:user, :staff), course: course)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_select 'select#lecturer-filter', count: 0
  end

  test 'htmx groups request filters by lecturer' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    target_lecturer = create(:user, :staff)
    target_enrolment = create(:enrolment, :lecturer, user: target_lecturer, course: course)
    other_lecturer = create(:user, :staff)
    other_enrolment = create(:enrolment, :lecturer, user: other_lecturer, course: course)

    target_group = create(:project_group, course: course, confirmed: true, group_name: 'Target Group')
    other_group = create(:project_group, course: course, confirmed: true, group_name: 'Other Group')
    create(:project, course: course, owner: target_group, owner_type: 'ProjectGroup', supervisor_enrolment: target_enrolment)
    create(:project, course: course, owner: other_group, owner_type: 'ProjectGroup', supervisor_enrolment: other_enrolment)

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' },
                             params: { section: 'groups', lecturer_filter: target_lecturer.id.to_s }
    assert_response :success
    assert_includes response.body, 'Target Group'
    assert_no_match 'Other Group', response.body
  end

  test 'groups tab shows confirmed groups only' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    create(:project_group, course: course, confirmed: true, group_name: 'Visible Group')
    create(:project_group, course: course, confirmed: false, group_name: 'Hidden Draft Group')

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_match 'Visible Group', response.body
    assert_no_match 'Hidden Draft Group', response.body
  end

  test 'htmx students search reuses filtered_student_list' do
    sign_in @coordinator_user
    get course_path(@course), headers: { 'HTTP_HX_REQUEST' => 'true' },
                              params: { section: 'students', search_query: @student_user.name[0..3] }
    assert_response :success
    assert_includes response.body, 'id="students-table-container"'
    assert_match ERB::Util.html_escape(@student_user.name), response.body
  end

  test 'htmx groups section renders confirmed groups only' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    create(:project_group, course: course, confirmed: true, group_name: 'Visible Group')
    create(:project_group, course: course, confirmed: false, group_name: 'Hidden Draft Group')

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'groups' }
    assert_response :success
    assert_match 'Visible Group', response.body
    assert_no_match 'Hidden Draft Group', response.body
  end

  test 'groups table shows the active sort icon on the default group-name column' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    create(:project_group, course: course, confirmed: true, group_name: 'Alpha')

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_select 'th .material-symbols-outlined:not(.opacity-0)', text: 'arrow_downward', count: 1
  end

  test 'group name links to the group profile page' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    group = create(:project_group, course: course, confirmed: true, group_name: 'Link Me')

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_select 'a[href=?]', participant_profile_course_path(course, group.id, 'group'), text: 'Link Me'
  end

  test 'students table uses a material checkbox (single selector) and no row overflow menu' do
    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_select "input[type='checkbox'][name='students_table_selection']", count: 1
    assert_select "input[type='radio']", count: 0
    assert_no_match 'Remove from course', response.body
  end

  test 'student group cell links to the group profile page' do
    course = create(:course, :grouped)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    group = create(:project_group, course: course, confirmed: true, group_name: 'Student Group')
    create(:project_group_member, user: @student_user, project_group: group)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_select 'a[href=?]', participant_profile_course_path(course, group.id, 'group')
  end

  test 'lecturers link to the profile page and show pending left of capacity' do
    course = create(:course)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    lecturer_a = create(:user, :staff)
    lecturer_a_enrolment = create(:enrolment, :lecturer, user: lecturer_a, course: course)
    create(:enrolment, :lecturer, user: create(:user, :staff), course: course)

    project = create(:project, course: course, supervisor_enrolment: lecturer_a_enrolment, status: :pending)
    create(:project_instance, project: project, supervisor_enrolment: lecturer_a_enrolment, status: :pending)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_select 'a[href=?]', participant_profile_course_path(course, lecturer_a.id, 'student')
    assert_match '1 pending', response.body
  end

  test 'invited students get main-branch Pending chip + resend-invite envelope' do
    invited_user = create(:user, has_registered: false)
    create(:enrolment, user: invited_user, course: @course)

    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_includes response.body, 'bg-yellow-100 text-yellow-800'
    assert_match %r{action="/user/\d+/resend_invite"}, response.body
  end

  test 'email action is the GeneralMailer invite resend, never a mailto' do
    invited_user = create(:user, has_registered: false)
    create(:enrolment, user: invited_user, course: @course)

    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_select '[data-students-select-target="emailItem"].hidden', count: 1
    assert_includes response.body, 'Resend invitation email'
    assert_no_match 'Email student', response.body
    assert_no_match 'mailto:', response.body
  end

  test 'students get no actions dropdown (read-only table)' do
    sign_in @student_user
    get course_path(@course)
    assert_response :success
    assert_no_match 'data-students-select-target="actions"', response.body
    assert_no_match 'Resend invitation email', response.body
  end

  test 'lecturers get no actions dropdown (read-only table)' do
    sign_in @lecturer_user
    get course_path(@course)
    assert_response :success
    assert_no_match 'data-students-select-target="actions"', response.body
    assert_no_match 'Resend invitation email', response.body
  end

  test 'htmx table triggers swap the container via outerHTML (no nested containers)' do
    sign_in @coordinator_user
    get course_path(@course)
    assert_response :success
    assert_select 'input#students-search[hx-target="#students-table-container"][hx-swap="outerHTML"]', count: 1
    assert_select 'input#groups-search[hx-target="#groups-table-container"][hx-swap="outerHTML"]', count: 1
  end

  test 'legacy fullpage participants route is removed' do
    get "/courses/#{@course.id}/participants"
    assert_response :not_found
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
