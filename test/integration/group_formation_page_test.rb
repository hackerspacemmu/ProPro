require 'test_helper'

class GroupFormationPageTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true,
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

  test 'coordinator and managing lecturer see Manage on the table' do
    [@coordinator, @lecturer].each do |user|
      sign_in user
      get course_group_formation_path(@course)

      assert_response :success
      assert_match edit_course_group_path(@course, @group), response.body
    end
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

  test 'staff manage frame renders staff actions' do
    sign_in @coordinator
    get edit_course_group_path(@course, @group)

    assert_response :success
    assert_match 'Add student', response.body
    assert_no_match(/Generate invite link/, response.body)
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
