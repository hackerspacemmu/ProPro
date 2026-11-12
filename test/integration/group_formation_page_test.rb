require 'test_helper'

class GroupFormationPageTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, group_formation_enabled: true,
                                        group_min: 2, group_max: 4, student_list_finalised: false)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @leader = create(:user, name: 'Group Leader')
    create(:enrolment, user: @leader, course: @course)
    @member = create(:user, name: 'Searchable Member')
    create(:enrolment, user: @member, course: @course)
    @student = create(:user)
    create(:enrolment, user: @student, course: @course)

    @group = create(:project_group, course: @course, leader_id: @leader.id, group_name: 'Alpha Group')
    create(:project_group_member, project_group: @group, user: @leader)
    create(:project_group_member, project_group: @group, user: @member)
  end

  test 'student sees the formation page and no staff actions' do
    sign_in @student
    get course_group_formation_path(@course)

    assert_response :success
    assert_match 'Group formation', response.body
    assert_match 'Alpha Group', response.body
    assert_no_match(/Grouping settings/, response.body)
    assert_no_match(/Manage group/, response.body)
  end

  test 'both grouping pages explain undersized groups in both modes' do
    sign_in @coordinator

    [false, true].each do |automatic|
      @course.update!(group_min: 3, student_list_finalised: automatic, group_formation_closes_at: nil)
      get course_group_formation_path(@course)

      assert_response :success
      assert_select '[data-group-size-warning][role="img"]', count: 1
      assert_select '[data-group-size-warning]', text: /Warning:/, count: 0

      get edit_course_group_path(@course, @group)
      assert_response :success
      assert_select '[data-group-size-warning] span:last-child', text: 'Warning: Alpha Group has 2 members; the allowed size is 3–4 members.'

      @course.update!(group_formation_closes_at: 1.hour.ago)
      get course_groups_path(@course)

      assert_response :success
      assert_select '[data-group-size-warning][role="img"]', count: 1
      assert_select '[data-group-size-warning]', text: /Warning:/, count: 0
    end
  end

  test 'both grouping pages explain oversized groups' do
    sign_in @coordinator
    3.times do
      user = create(:user)
      create(:enrolment, course: @course, user: user)
      create(:project_group_member, project_group: @group, user: user)
    end

    get course_group_formation_path(@course)

    assert_response :success
    assert_select '[data-group-size-warning][role="img"]', count: 1
    assert_select '[data-group-size-warning]', text: /Warning:/, count: 0

    @course.update!(group_formation_closes_at: 1.hour.ago)
    get course_groups_path(@course)

    assert_response :success
    assert_select '[data-group-size-warning][role="img"]', count: 1
    assert_select '[data-group-size-warning]', text: /Warning:/, count: 0
  end

  test 'equal limits show the required size and a legal group has no warning' do
    sign_in @coordinator
    @course.update!(group_min: 3, group_max: 3)
    get course_group_formation_path(@course)
    assert_select '[data-group-size-warning][role="img"]', count: 1
    assert_select '[data-group-size-warning]', text: /Warning:/, count: 0

    create(:project_group_member, project_group: @group, user: @student)
    [course_groups_path(@course), course_group_formation_path(@course)].each do |path|
      get path

      assert_response :success
      assert_select '[data-group-size-warning]', count: 0
    end
  end

  test 'a coordinator sees Manage on the table' do
    sign_in @coordinator
    get course_group_formation_path(@course)

    assert_response :success
    assert_match edit_course_group_path(@course, @group), response.body
  end

  test 'a lecturer does not see Manage on the table' do
    sign_in @lecturer
    get course_group_formation_path(@course)

    assert_response :success
    assert_no_match edit_course_group_path(@course, @group), response.body
  end

  test 'htmx search matches member names and swaps only the table' do
    sign_in @student
    get course_group_formation_path(@course),
        params: { search_query: 'Searchable Member' },
        headers: { 'HX-Request' => 'true' }

    assert_response :success
    assert_match 'Alpha Group', response.body
    assert_match 'formation-groups', response.body
    assert_match 'aria-expanded="true"', response.body
    assert_no_match(/<h1/, response.body)
  end

  test 'htmx search does not match the project title' do
    titled_group = create(:project_group, course: @course, leader_id: @student.id,
                                          group_name: 'Title Group', confirmed: true)
    create(:project_group_member, project_group: titled_group, user: @student)
    project = create(:project, course: @course, owner: titled_group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: @course.enrolments.find_by(user: @lecturer))
    create(:project_instance, project: project, supervisor_enrolment: project.supervisor_enrolment,
                              created_by: @student, title: 'Secret Project Title')

    sign_in @student
    get course_group_formation_path(@course),
        params: { search_query: 'Secret Project Title' },
        headers: { 'HX-Request' => 'true' }

    assert_response :success
    assert_no_match(/Title Group/, response.body)
    assert_match 'No groups match your current filters.', response.body
  end

  test 'htmx status filter separates draft and confirmed groups' do
    confirmed = create(:project_group, course: @course, leader_id: @student.id,
                                       group_name: 'Confirmed Group', confirmed: true)
    create(:project_group_member, project_group: confirmed, user: @student)

    sign_in @lecturer
    get course_group_formation_path(@course),
        params: { status_filter: 'confirmed' },
        headers: { 'HX-Request' => 'true' }

    assert_response :success
    assert_match 'Confirmed Group', response.body
    assert_no_match(/Alpha Group/, response.body)
  end

  test 'leader manage frame renders leader actions' do
    sign_in @leader
    get edit_course_group_path(@course, @group)

    assert_response :success
    assert_match 'MEMBERS', response.body
    assert_match 'Generate invite link', response.body
    assert_no_match(/Add student/, response.body)
  end

  test 'leader manage frame has no approval switch' do
    sign_in @leader
    get edit_course_group_path(@course, @group)

    assert_response :success
    assert_no_match(/Require approval to join/, response.body)
  end

  test 'the groups table shows Join and never Request to join' do
    sign_in @student
    get course_group_formation_path(@course)

    assert_response :success
    assert_match 'Join', response.body
    assert_no_match(/Request to join/, response.body)
  end

  test 'staff manage frame renders staff actions' do
    sign_in @coordinator
    get edit_course_group_path(@course, @group)

    assert_response :success
    assert_match 'Add student', response.body
    assert_no_match(/Generate invite link/, response.body)
  end

  test 'coordinator confirm-anyway dialog states the broken minimum' do
    @course.update!(group_min: 3)
    small = create(:project_group, course: @course, group_name: 'Tmp001', leader_id: @student.id)
    create(:project_group_member, project_group: small, user: @student)

    sign_in @coordinator
    get edit_course_group_path(@course, small)

    assert_response :success
    assert_match 'This group has 1 member; the minimum is 3.', response.body
  end

  test 'coordinator confirm-anyway dialog states the broken maximum' do
    @course.update!(group_min: 1, group_max: 1)

    sign_in @coordinator
    get edit_course_group_path(@course, @group)

    assert_response :success
    assert_match 'This group has 2 members; the maximum is 1.', response.body
    assert_no_match(/the minimum is/, response.body)
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end

  test 'a student leaving a not-confirmed group removes their own-group panel and table row' do
    student = @student
    group = @group
    membership = create(:project_group_member, project_group: group, user: student)
    sign_in student

    get course_group_formation_path(@course)
    assert_response :success
    assert_match 'data-testid="my-group-panel-grouped"', response.body

    delete course_group_member_path(@course, group, membership)

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_no_match 'data-testid="my-group-panel-grouped"', response.body
    # groups table should not list the user as a member
    assert_select '#formation-groups' do
      assert_select '.min-w-0.break-words.pt-1.text-sm.leading-5.text-on-surface', text: student.name, count: 0
    end
  end

  test 'coordinator removal does not change group status' do
    student = @student
    group = @group
    membership = create(:project_group_member, project_group: group, user: student)
    sign_in @coordinator

    delete course_group_member_path(@course, group, membership)

    assert_response :redirect
    follow_redirect!
    assert_response :success
    group.reload
    assert_equal false, group.confirmed?
  end

  test 'a student cannot leave a group that owns a proposal' do
    student = @student
    group = @group
    membership = create(:project_group_member, project_group: group, user: student)
    group.update!(confirmed: true)
    create(:project, course: @course, owner: group, owner_type: 'ProjectGroup',
                     supervisor_enrolment: create(:enrolment, :lecturer, course: @course))
    group.update_columns(confirmed: false)
    sign_in student

    delete course_group_member_path(@course, group, membership)

    assert_redirected_to course_group_formation_path(@course)
    follow_redirect!
    assert_response :success
    assert_match(/proposal|coordinator can remove/i, response.body)
    assert group.project_group_members.exists?(user: student)
  end
end
