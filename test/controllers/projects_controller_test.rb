require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course   = create(:course)
    @student  = create(:user)
    create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, :staff, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @other_lecturer     = create(:user, :staff, name: 'Bob Ray')
    @other_lecturer_enr = create(:enrolment, :lecturer, user: @other_lecturer, course: @course)

    @title_field = @course.project_template.project_template_fields.first
  end

  test 'an approved project keeps its supervisor when another one is requested' do
    # The owner may edit an approved project only when the template has a
    # free-edit field; this one gets the request past ProjectPolicy#update?
    # so it reaches the supervisor guard.
    create(:project_template_field, project_template: @course.project_template,
                                    label: 'Progress Notes', field_type: :textarea,
                                    applicable_to: :both, free_edit: true)
    project = build_project

    sign_in @student
    patch course_project_path(@course, project), params: {
      based_on_topic: "own_proposal_#{@other_lecturer_enr.id}",
      fields: { @title_field.id.to_s => 'Original Title' }
    }

    assert_redirected_to course_project_path(@course, project)
    assert flash[:alert].present?
    assert_equal @lecturer_enr, project.reload.supervisor_enrolment
    assert_equal @lecturer, project.supervisor
  end

  test 'creating a group project clears the group pending invites and requests' do
    course = create(:course, grouped: true, group_min: 2, group_max: 4,
                             grouping_enabled: true, student_list_finalised: false)
    leader = create(:user)
    create(:enrolment, :student, user: leader, course: course)
    group = create(:project_group, course: course, confirmed: true, leader_id: leader.id)
    create(:project_group_member, project_group: group, user: leader)
    lecturer = create(:enrolment, :lecturer, course: course)
    field = course.project_template.project_template_fields.find_by!(is_project_title: true)
    requester = create(:user)
    create(:enrolment, :student, user: requester, course: course)
    invite = create(:project_group_invite, project_group: group, sender: leader, recipient: requester,
                                           kind: :direct_invite, status: :pending)
    request = create(:project_group_invite, project_group: group, sender: requester, recipient: leader,
                                            kind: :direct_request, status: :pending)

    sign_in leader
    post course_projects_path(course), params: {
      based_on_topic: "own_proposal_#{lecturer.id}",
      fields: { field.id.to_s => 'Group Project' }
    }

    assert Project.exists?(owner: group)
    assert_not ProjectGroupInvite.exists?(invite.id)
    assert_not ProjectGroupInvite.exists?(request.id)
  end

  test 'creating an own proposal redirects and records the chosen supervisor' do
    title_field = @course.project_template.project_template_fields.find_by!(is_project_title: true)

    sign_in @student
    post course_projects_path(@course), params: {
      based_on_topic: "own_proposal_#{@lecturer_enr.id}",
      fields: { title_field.id.to_s => 'Own Proposal Title' }
    }

    project = Project.find_by!(course: @course, owner: @student)
    instance = project.project_instances.last

    assert_redirected_to course_project_path(@course, project)
    assert_equal @lecturer_enr, instance.supervisor_enrolment
    assert_nil instance.source_topic_id
  end

  test 'creating a proposal based on a topic redirects and records the source topic' do
    topic = create(:topic, course: @course, owner: @lecturer)
    title_field = @course.project_template.project_template_fields.find_by!(is_project_title: true)

    sign_in @student
    post course_projects_path(@course), params: {
      based_on_topic: topic.id.to_s,
      fields: { title_field.id.to_s => 'Topic Proposal Title' }
    }

    project = Project.find_by!(course: @course, owner: @student)
    instance = project.project_instances.last

    assert_redirected_to course_project_path(@course, project)
    assert_equal @lecturer_enr, instance.supervisor_enrolment
    assert_equal topic.id, instance.source_topic_id
  end

  test 'new redirects to course overview when student in a grouped course has no group' do
    course = create(:course, grouped: true, grouping_enabled: true)
    student = create(:user)
    create(:enrolment, :student, user: student, course: course)

    sign_in student
    get new_course_project_path(course)

    assert_redirected_to course_path(course)
    assert_equal 'Join or create a group before you can put together a project proposal.', flash[:alert]
  end

  test 'new redirects to course overview when student group is not confirmed' do
    course = create(:course, grouped: true, grouping_enabled: true)
    student = create(:user)
    create(:enrolment, :student, user: student, course: course)
    group = create(:project_group, course: course, confirmed: false, leader_id: student.id)
    create(:project_group_member, project_group: group, user: student)

    sign_in student
    get new_course_project_path(course)

    assert_redirected_to course_path(course)
    assert_equal 'Your group must be confirmed before creating a proposal.', flash[:alert]
  end

  test 'create blocks proposal when student group is not confirmed' do
    course = create(:course, grouped: true, grouping_enabled: true)
    student = create(:user)
    create(:enrolment, :student, user: student, course: course)
    group = create(:project_group, course: course, confirmed: false, leader_id: student.id)
    create(:project_group_member, project_group: group, user: student)
    lecturer = create(:enrolment, :lecturer, course: course)
    field = course.project_template.project_template_fields.find_by!(is_project_title: true)

    sign_in student
    post course_projects_path(course), params: {
      based_on_topic: "own_proposal_#{lecturer.id}",
      fields: { field.id.to_s => 'Illegal Proposal' }
    }

    assert_not Project.exists?(owner: group)
    assert_equal 'Your group must be confirmed before creating a proposal.', flash[:alert]
  end

  private

  def build_project
    project = create(:project, course: @course, owner: @student,
                               supervisor_enrolment: @lecturer_enr, status: :approved)
    instance = create(:project_instance, project: project, supervisor_enrolment: @lecturer_enr,
                                         created_by: @student, version: 1, status: :approved,
                                         title: 'Original Title')
    instance.project_instance_fields.create!(project_template_field_id: @title_field.id,
                                             value: 'Original Title')
    project
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
