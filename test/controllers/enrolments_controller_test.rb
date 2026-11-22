require 'test_helper'

class EnrolmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @student = create(:user, has_registered: false)
    @enrolment = create(:enrolment, user: @student, course: @course)
  end

  test 'coordinator can destroy a student enrolment in their own course' do
    sign_in @coordinator

    assert_difference('@course.enrolments.count', -1) do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end

    assert_redirected_to course_path(@course)
  end

  test 'an unauthenticated/non-coordinator user cannot destroy an enrolment' do
    attacker = create(:user)
    sign_in attacker

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end
  end

  test "coordinator of a different course cannot destroy this course's enrolment" do
    other_course = create(:course)
    other_coordinator = create(:user)
    create(:enrolment, :coordinator, user: other_coordinator, course: other_course)

    sign_in other_coordinator

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end
  end

  test 'client-submitted coordinator_id is ignored for authorization' do
    attacker = create(:user)
    sign_in attacker

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course, coordinator_id: @coordinator.id)
    end
  end

  test 'enrolment from another course cannot be deleted by course-scoped id' do
    other_course = create(:course)
    other_student = create(:user)
    other_enrolment = create(:enrolment, user: other_student, course: other_course)

    sign_in @coordinator

    delete enrolment_path(id: other_enrolment, course_id: @course)

    assert other_course.enrolments.reload.exists?(id: other_enrolment.id)
  end

  test 'removing the last member of a group with a proposal warns before deleting anything' do
    course = create(:course, :grouped)
    coordinator = create(:user)
    create(:enrolment, :coordinator, user: coordinator, course: course)
    student = create(:user)
    enrolment = create(:enrolment, user: student, course: course)
    group = create(:project_group, course: course, leader_id: student.id, confirmed: true)
    create(:project_group_member, project_group: group, user: student)
    supervisor = create(:enrolment, :lecturer, course: course)
    project = create(:project, course: course, owner: group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: supervisor)
    create(:project_instance, project: project, supervisor_enrolment: supervisor, title: 'Group Proposal')

    sign_in coordinator

    counts = -> { [course.enrolments.count, ProjectGroupMember.count, ProjectGroup.count, Project.count] }
    before = counts.call

    delete enrolment_path(id: enrolment, course_id: course)

    assert_equal before, counts.call
    assert_redirected_to confirm_removal_enrolment_path(enrolment, course_id: course)
  end

  test 'confirmed removal deletes the student, group and proposal' do
    course = create(:course, :grouped)
    coordinator = create(:user)
    create(:enrolment, :coordinator, user: coordinator, course: course)
    student = create(:user)
    enrolment = create(:enrolment, user: student, course: course)
    group = create(:project_group, course: course, leader_id: student.id, confirmed: true)
    create(:project_group_member, project_group: group, user: student)
    supervisor = create(:enrolment, :lecturer, course: course)
    project = create(:project, course: course, owner: group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: supervisor)
    create(:project_instance, project: project, supervisor_enrolment: supervisor, title: 'Group Proposal')

    sign_in coordinator

    delete enrolment_path(id: enrolment, course_id: course, confirm: 'true')

    assert_redirected_to course_path(course)
    assert_not Enrolment.exists?(enrolment.id)
    assert_not ProjectGroup.exists?(group.id)
    assert_not Project.exists?(project.id)
  end

  test 'removing a leader promotes the earliest member and clears pending invites' do
    course = create(:course, :grouped)
    coordinator = create(:user)
    create(:enrolment, :coordinator, user: coordinator, course: course)

    leader = create(:user)
    earliest = create(:user)
    latest = create(:user)
    [leader, earliest, latest].each { |user| create(:enrolment, user: user, course: course) }

    group = create(:project_group, course: course, leader_id: leader.id)
    leader_member = create(:project_group_member, project_group: group, user: leader)
    earliest_member = create(:project_group_member, project_group: group, user: earliest)
    latest_member = create(:project_group_member, project_group: group, user: latest)
    earliest_member.update!(created_at: 2.days.ago)
    latest_member.update!(created_at: 1.day.ago)

    sent = create(:project_group_invite, project_group: group, sender: leader, recipient: latest)
    received = create(:project_group_invite, project_group: group, sender: latest, recipient: leader)

    sign_in coordinator

    delete enrolment_path(id: leader_member.user.enrolments.find_by!(course: course), course_id: course)

    assert_redirected_to course_path(course)
    assert ProjectGroup.exists?(group.id)
    assert_equal earliest.id, group.reload.leader_id
    assert_not ProjectGroupInvite.exists?(sent.id)
    assert_not ProjectGroupInvite.exists?(received.id)
  end

  test 'confirmation page names the proposal that would be deleted' do
    course = create(:course, :grouped)
    coordinator = create(:user)
    create(:enrolment, :coordinator, user: coordinator, course: course)
    student = create(:user)
    enrolment = create(:enrolment, user: student, course: course)
    group = create(:project_group, course: course, leader_id: student.id, confirmed: true)
    create(:project_group_member, project_group: group, user: student)
    supervisor = create(:enrolment, :lecturer, course: course)
    project = create(:project, course: course, owner: group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: supervisor)
    create(:project_instance, project: project, supervisor_enrolment: supervisor, title: 'Group Proposal')

    sign_in coordinator

    get confirm_removal_enrolment_path(enrolment, course_id: course)

    assert_response :success
    assert_select 'h1', text: /Remove student from course/
    assert_select 'body', text: /Group Proposal/
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
