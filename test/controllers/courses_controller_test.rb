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
    # Two settings links intentionally coexist in the DOM: the desktop tab-row
    # gear (hidden lg:flex) and the mobile header gear (sm:hidden). They never
    # both show at the same width, but the controller test sees the full DOM.
    assert_select 'a[href=?]', settings_course_path(@course), count: 2
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

  test 'htmx topics request renders supervisor groups for the scoped topic list' do
    course, alice, bob = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)
    create_topic_on(course, bob, 'Bob Approved Topic', :approved)

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_includes response.body, 'id="topics-by-supervisor-container"'
    assert_includes response.body, 'Alice Lecturer'
    assert_includes response.body, 'Bob Lecturer'
    assert_includes response.body, 'Alice Approved Topic'
    assert_includes response.body, 'Bob Approved Topic'
    assert_no_match '(You)', response.body
  end

  test 'coordinator sees all statuses across supervisors in the topics directory' do
    course, alice, bob = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)
    create_topic_on(course, alice, 'Alice Pending Topic', :pending)
    create_topic_on(course, bob, 'Bob Pending Topic', :pending)

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_includes response.body, 'Alice Approved Topic'
    assert_includes response.body, 'Alice Pending Topic'
    assert_includes response.body, 'Bob Pending Topic'
  end

  test 'lecturer sees own topics of any status and others approved only in the topics directory' do
    course, alice, bob = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)
    create_topic_on(course, alice, 'Alice Pending Topic', :pending)
    create_topic_on(course, bob, 'Bob Approved Topic', :approved)
    create_topic_on(course, bob, 'Bob Pending Topic', :pending)

    sign_in alice
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_includes response.body, 'Alice Approved Topic'
    assert_includes response.body, 'Alice Pending Topic'
    assert_includes response.body, 'Bob Approved Topic'
    assert_no_match 'Bob Pending Topic', response.body
  end

  test 'student sees approved topics only in the topics directory' do
    course, alice, bob = build_topic_directory_course
    create(:enrolment, user: @student_user, course: course)
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)
    create_topic_on(course, alice, 'Alice Pending Topic', :pending)
    create_topic_on(course, bob, 'Bob Approved Topic', :approved)
    create_topic_on(course, bob, 'Bob Pending Topic', :pending)

    sign_in @student_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_includes response.body, 'Alice Approved Topic'
    assert_includes response.body, 'Bob Approved Topic'
    assert_no_match 'Alice Pending Topic', response.body
    assert_no_match 'Bob Pending Topic', response.body
  end

  test 'supervisor filter shows only the selected supervisor group' do
    course, alice, bob = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)
    create_topic_on(course, bob, 'Bob Approved Topic', :approved)

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' },
                             params: { section: 'topics', topic_filter: alice.id.to_s }
    assert_response :success
    assert_includes response.body, 'Alice Approved Topic'
    assert_includes response.body, 'Alice Lecturer'
    assert_no_match 'Bob Approved Topic', response.body
    assert_no_match 'Bob Lecturer', response.body
  end

  test 'topics search matches topics by title and by supervisor name, case-insensitively' do
    course, alice, bob = build_topic_directory_course
    create_topic_on(course, alice, 'Machine Learning Basics', :approved)
    create_topic_on(course, bob, 'Neural Networks', :approved)

    sign_in @coordinator_user

    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' },
                             params: { section: 'topics', search_query: 'machine' }
    assert_response :success
    assert_includes response.body, 'Machine Learning Basics'
    assert_no_match 'Neural Networks', response.body

    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' },
                             params: { section: 'topics', search_query: 'bob' }
    assert_response :success
    assert_includes response.body, 'Neural Networks'
    assert_no_match 'Machine Learning Basics', response.body
  end

  test 'zero-topic supervisors still render as groups when unfiltered' do
    course, alice, = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_includes response.body, 'Alice Approved Topic'
    assert_includes response.body, 'Bob Lecturer'
  end

  test 'pinned (You) group renders first for the viewing lecturer' do
    course, alice, bob = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)
    create_topic_on(course, bob, 'Bob Approved Topic', :approved)

    sign_in alice
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_includes response.body, '(You)'
    assert response.body.index('Alice Approved Topic') < response.body.index('Bob Approved Topic')
  end

  test 'available badge: approved-unclaimed row says Available, approved-claimed keeps Approved' do
    course, alice, bob = build_topic_directory_course
    claimed_topic = create_topic_on(course, alice, 'Claimed Topic', :approved)
    create_topic_on(course, alice, 'Free Topic', :approved)
    bob_enrolment = course.enrolments.find_by(user: bob, role: :lecturer)
    project = create(:project, course: course, supervisor_enrolment: bob_enrolment)
    create(:project_instance, project: project, supervisor_enrolment: bob_enrolment, source_topic: claimed_topic, status: :approved)

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_equal 1, response.body.scan('Available').size
    assert_match(/Claimed Topic[\s\S]*?Approved/, response.body)
    assert_match(/Free Topic[\s\S]*?Available/, response.body)
  end

  test 'topics tab renders the search pill, supervisor filter, and collapse-all control' do
    course, alice, = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)

    sign_in @coordinator_user
    get course_path(course)
    assert_response :success
    assert_select 'input#topic-search[hx-target="#topics-by-supervisor-container"][hx-swap="outerHTML"]', count: 1
    assert_select 'select#topic-filter[hx-target="#topics-by-supervisor-container"]', count: 1
    assert_select 'select#topic-filter option', count: 3
    assert_select 'select#topic-filter option[value="all"]', count: 1
    assert_select 'input#topic-search[data-search-shortcut-target]', count: 0
    assert_includes response.body, 'Search supervisors or topics'
    assert_includes response.body, 'Collapse all'
    assert_includes response.body, 'unfold_less'
  end

  test 'supervisor groups render expanded by default in the topics directory' do
    course, alice, = build_topic_directory_course
    create_topic_on(course, alice, 'Alice Approved Topic', :approved)

    sign_in @coordinator_user
    get course_path(course), headers: { 'HTTP_HX_REQUEST' => 'true' }, params: { section: 'topics' }
    assert_response :success
    assert_select '[data-detail-row-id]', count: 1
    assert_select '[data-detail-row-id].hidden', count: 0
  end

  private

  def build_topic_directory_course
    course = create(:course)
    create(:enrolment, :coordinator, user: @coordinator_user, course: course)
    alice = create(:user, :staff, name: 'Alice Lecturer')
    bob = create(:user, :staff, name: 'Bob Lecturer')
    create(:enrolment, :lecturer, user: alice, course: course)
    create(:enrolment, :lecturer, user: bob, course: course)
    [course, alice, bob]
  end

  def create_topic_on(course, owner, title, status)
    topic = create(:topic, course: course, owner: owner)
    topic.update_column(:status, status)
    create(:topic_instance, topic: topic, created_by: owner, title: title, status: status, version: 1)
    topic
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
