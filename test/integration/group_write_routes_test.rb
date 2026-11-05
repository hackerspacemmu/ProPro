require 'test_helper'

class GroupWriteRoutesTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true,
                                        group_min: 2, group_max: 4, student_list_finalised: false)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @leader = create(:user)
    create(:enrolment, :student, user: @leader, course: @course)
    @member = create(:user)
    create(:enrolment, :student, user: @member, course: @course)
    @other_student = create(:user)
    create(:enrolment, :student, user: @other_student, course: @course)
    @outsider = create(:user)

    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
    create(:project_group_member, project_group: @group, user: @member)
  end

  test 'a coordinator can create a group for a chosen student' do
    sign_in @coordinator

    assert_difference 'ProjectGroup.count', 1 do
      post course_groups_path(@course), params: { user_id: @other_student.id }
    end

    assert_redirected_to course_group_formation_path(@course)
    assert_equal @other_student.id, ProjectGroup.order(:created_at).last.leader_id
  end

  test 'a student create ignores user_id and leads their own group' do
    sign_in @other_student

    assert_difference 'ProjectGroup.count', 1 do
      post course_groups_path(@course), params: { user_id: @leader.id }
    end

    assert_redirected_to course_group_formation_path(@course)
    assert_equal @other_student.id, ProjectGroup.order(:created_at).last.leader_id
  end

  test 'an outsider cannot create a group' do
    sign_in @outsider

    assert_no_difference 'ProjectGroup.count' do
      post course_groups_path(@course), params: { user_id: @other_student.id }
    end

    assert_redirected_to dashboard_path
  end

  test 'the leader can edit and lock the group' do
    sign_in @leader

    get edit_course_group_path(@course, @group)
    assert_response :success

    patch course_group_path(@course, @group), params: { project_group: { locked: true } }
    assert_redirected_to course_group_formation_path(@course)
    assert @group.reload.locked?
  end

  test 'another student cannot edit or lock the group' do
    sign_in @other_student

    get edit_course_group_path(@course, @group)
    assert_redirected_to dashboard_path

    patch course_group_path(@course, @group), params: { project_group: { locked: true } }
    assert_redirected_to dashboard_path
  end

  test 'the leader can dissolve an unconfirmed group' do
    sign_in @leader

    assert_difference 'ProjectGroup.count', -1 do
      delete course_group_path(@course, @group)
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'another student cannot dissolve the group' do
    sign_in @other_student

    assert_no_difference 'ProjectGroup.count' do
      delete course_group_path(@course, @group)
    end

    assert_redirected_to dashboard_path
  end

  test 'the leader can confirm and revert the group' do
    sign_in @leader

    post course_group_confirmation_path(@course, @group)
    assert_redirected_to course_group_formation_path(@course)

    delete course_group_confirmation_path(@course, @group)
    assert_redirected_to course_group_formation_path(@course)
  end

  test 'another student cannot confirm or revert the group' do
    sign_in @other_student

    post course_group_confirmation_path(@course, @group)
    assert_redirected_to dashboard_path

    delete course_group_confirmation_path(@course, @group)
    assert_redirected_to dashboard_path
  end

  test 'the leader can generate an invite link' do
    sign_in @leader

    post course_group_invite_link_path(@course, @group)

    assert_redirected_to course_group_formation_path(@course)
    assert @group.project_group_invite_links.exists?(sender: @leader)
  end

  test 'another student cannot generate an invite link' do
    sign_in @other_student

    post course_group_invite_link_path(@course, @group)

    assert_redirected_to dashboard_path
  end

  test 'a student can join an open group' do
    sign_in @other_student

    assert_difference '@group.project_group_members.count', 1 do
      post course_group_members_path(@course, @group)
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'a staff member can add a student to a group' do
    sign_in @coordinator

    assert_difference '@group.project_group_members.count', 1 do
      post course_group_members_path(@course, @group), params: { user_id: @other_student.id }
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'a student cannot add a student by sending user_id' do
    sign_in @other_student

    assert_no_difference '@group.project_group_members.count' do
      post course_group_members_path(@course, @group), params: { user_id: @member.id }
    end

    assert_redirected_to dashboard_path
  end

  test 'a member can leave the group' do
    membership = @group.project_group_members.find_by(user: @member)
    sign_in @member

    assert_difference '@group.project_group_members.count', -1 do
      delete course_group_member_path(@course, @group, membership)
    end
  end

  test 'an outsider cannot remove a group member' do
    membership = @group.project_group_members.find_by(user: @member)
    sign_in @outsider

    assert_no_difference '@group.project_group_members.count' do
      delete course_group_member_path(@course, @group, membership)
    end

    assert_redirected_to dashboard_path
  end

  test 'a student can request to join a locked group' do
    @group.update!(locked: true)
    sign_in @other_student

    assert_difference 'ProjectGroupInvite.count', 1 do
      post course_group_join_requests_path(@course, @group)
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'an outsider cannot request to join a group' do
    sign_in @outsider

    assert_no_difference 'ProjectGroupInvite.count' do
      post course_group_join_requests_path(@course, @group)
    end

    assert_redirected_to dashboard_path
  end

  test 'the leader can accept a join request' do
    invite = create(:project_group_invite, project_group: @group, sender: @other_student,
                                           recipient: @leader, kind: :direct_request)
    sign_in @leader

    patch course_group_join_request_path(@course, @group, invite), params: { status: 'accepted' }

    assert_redirected_to course_group_formation_path(@course)
    assert invite.reload.accepted?
  end

  test 'another student cannot accept a join request' do
    invite = create(:project_group_invite, project_group: @group, sender: @other_student,
                                           recipient: @leader, kind: :direct_request)
    sign_in @member

    patch course_group_join_request_path(@course, @group, invite), params: { status: 'accepted' }

    assert_redirected_to dashboard_path
    assert invite.reload.pending?
  end

  test 'a join request rejects an invalid status and a wrong-kind invite' do
    request = create(:project_group_invite, project_group: @group, sender: @other_student,
                                            recipient: @leader, kind: :direct_request)
    invitation = create(:project_group_invite, project_group: @group, sender: @leader,
                                               recipient: @other_student, kind: :direct_invite)
    sign_in @leader

    patch course_group_join_request_path(@course, @group, request), params: { status: 'bogus' }
    assert_redirected_to course_group_formation_path(@course)
    assert_equal 'Invalid invite response.', flash[:alert]

    patch course_group_join_request_path(@course, @group, invitation), params: { status: 'accepted' }
    assert_response :not_found
  end

  test 'the leader can directly invite a student' do
    sign_in @leader

    assert_difference 'ProjectGroupInvite.count', 1 do
      post course_group_invitations_path(@course, @group), params: { user_id: @other_student.id }
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'a non-leader cannot directly invite a student' do
    sign_in @member

    assert_no_difference 'ProjectGroupInvite.count' do
      post course_group_invitations_path(@course, @group), params: { user_id: @other_student.id }
    end

    assert_redirected_to dashboard_path
  end

  test 'the invited student can accept a direct invitation' do
    invite = create(:project_group_invite, project_group: @group, sender: @leader,
                                           recipient: @other_student, kind: :direct_invite)
    sign_in @other_student

    patch course_group_invitation_path(@course, @group, invite), params: { status: 'accepted' }

    assert_redirected_to course_group_formation_path(@course)
    assert invite.reload.accepted?
  end

  test 'another student cannot accept a direct invitation' do
    invite = create(:project_group_invite, project_group: @group, sender: @leader,
                                           recipient: @other_student, kind: :direct_invite)
    sign_in @member

    patch course_group_invitation_path(@course, @group, invite), params: { status: 'accepted' }

    assert_redirected_to dashboard_path
    assert invite.reload.pending?
  end

  test 'an invited student can redeem an invite link' do
    link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    sign_in @other_student

    post invite_link_redemption_path(link.token)

    assert_redirected_to course_group_formation_path(@course)
    assert @group.project_group_members.exists?(user: @other_student)
  end

  test 'an outsider cannot redeem an invite link' do
    link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    sign_in @outsider

    assert_no_difference '@group.project_group_members.count' do
      post invite_link_redemption_path(link.token)
    end

    assert_redirected_to dashboard_path
  end

  test 'the leader cannot reopen a group that has a project' do
    @group.update!(confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: @course)
    Project.create!(course: @course, owner: @group, supervisor_enrolment: supervisor)
    sign_in @leader

    delete course_group_confirmation_path(@course, @group)

    assert_redirected_to dashboard_path
    assert @group.reload.confirmed?
  end

  test 'a coordinator cannot reopen a group that has a project' do
    @group.update!(confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: @course)
    Project.create!(course: @course, owner: @group, supervisor_enrolment: supervisor)
    sign_in @coordinator

    delete course_group_confirmation_path(@course, @group)

    assert_redirected_to dashboard_path
    assert @group.reload.confirmed?
  end

  test 'dissolve_confirmed no longer lets a student delete a group with a proposal' do
    project_group = @group
    project_group.update!(confirmed: true)
    project = create(:project, course: @course, owner: project_group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: create(:enrolment, :lecturer, course: @course))
    project_group.update_columns(confirmed: false)
    membership = project_group.project_group_members.find_by!(user: @member)
    sign_in @member

    %w[dissolve_confirmed confirm].each do |flag|
      assert_no_difference ['ProjectGroup.count', 'Project.count', 'ProjectGroupMember.count'] do
        delete course_group_member_path(@course, project_group, membership), params: { flag => true }
      end

      assert_redirected_to course_group_formation_path(@course)
      follow_redirect!
      assert_match(/proposal|coordinator can remove/i, response.body)
    end

    assert Project.exists?(project.id)
  end

  test 'a coordinator with an earlier lecturer enrolment can delete a confirmed group' do
    dual_role = create(:user)
    create(:enrolment, :lecturer, user: dual_role, course: @course)
    create(:enrolment, :coordinator, user: dual_role, course: @course)
    @group.update!(confirmed: true)
    sign_in dual_role

    assert_difference 'ProjectGroup.count', -1 do
      delete course_group_path(@course, @group)
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'a coordinator deleting a group with a proposal warns, then deletes on confirmation' do
    @group.update!(confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: @course)
    project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: supervisor)
    create(:project_instance, project: project, supervisor_enrolment: supervisor, title: 'Group Proposal')
    sign_in @coordinator

    assert_no_difference ['ProjectGroup.count', 'Project.count'] do
      delete course_group_path(@course, @group)
    end

    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type
    assert_match 'Delete group and project', response.body

    assert_difference ['ProjectGroup.count', 'Project.count'], -1 do
      delete course_group_path(@course, @group), params: { confirm: true }
    end

    assert_redirected_to course_group_formation_path(@course)
    assert_not Project.exists?(project.id)
  end

  test 'a non-coordinator cannot confirm a project-group deletion' do
    @group.update!(confirmed: true)
    project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: create(:enrolment, :lecturer, course: @course))
    sign_in @leader

    assert_no_difference ['ProjectGroup.count', 'Project.count'] do
      delete course_group_path(@course, @group), params: { confirm: true }
    end

    assert_redirected_to dashboard_path
    assert Project.exists?(project.id)
  end

  test 'removing the last member from the group edit page returns to formation' do
    group = create(:project_group, course: @course, leader_id: @other_student.id)
    membership = create(:project_group_member, project_group: group, user: @other_student)
    sign_in @coordinator

    delete course_group_member_path(@course, group, membership),
           headers: { 'HTTP_REFERER' => edit_course_group_path(@course, group) }

    assert_redirected_to course_group_formation_path(@course)
    follow_redirect!
    assert_response :success
    assert_not ProjectGroup.exists?(group.id)
  end

  test 'an imported group cannot be reopened from the formation page' do
    @group.update!(confirmed: true, origin: :import)
    sign_in @leader

    delete course_group_confirmation_path(@course, @group)

    assert_redirected_to dashboard_path
    assert_equal 'You are not authorized to view this page.', flash[:alert]
    assert @group.reload.confirmed?
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
