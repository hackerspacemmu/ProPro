require 'test_helper'

class GroupWriteRoutesTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, group_formation_enabled: true,
                                        group_min: 2, group_max: 4, prevent_leftover_students: false)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: @lecturer, course: @course)

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

  test 'a lecturer cannot create a group for a chosen student' do
    sign_in @lecturer

    assert_no_difference 'ProjectGroup.count' do
      post course_groups_path(@course), params: { user_id: @other_student.id }
    end

    assert_redirected_to dashboard_path
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

  test 'the leader can open the Manage page' do
    sign_in @leader

    get edit_course_group_path(@course, @group)
    assert_response :success

    patch course_group_path(@course, @group)
    assert_response :not_found
  end

  test 'the Manage page hides expired join requests' do
    fresh = create(:user)
    stale = create(:user)
    [fresh, stale].each { |user| create(:enrolment, :student, user: user, course: @course) }
    create(:project_group_invite, project_group: @group, sender: fresh, recipient: @leader,
                                  kind: :direct_request, status: :pending)
    create(:project_group_invite, project_group: @group, sender: stale, recipient: @leader,
                                  kind: :direct_request, status: :pending, created_at: 25.hours.ago)

    sign_in @leader
    get edit_course_group_path(@course, @group)

    html = Nokogiri::HTML(response.body)
    section = html.css('section').find { |node| node.at_css('h3')&.text == 'Join requests' }
    assert section, 'expected the Join requests section'
    assert_includes section.text, fresh.name
    assert_not_includes section.text, stale.name
  end

  test 'the leader can open the Manage page for a confirmed group while formation is open' do
    @group.update!(confirmed: true)
    sign_in @leader

    get edit_course_group_path(@course, @group)
    assert_response :success
  end

  test 'the leader cannot open the Manage page for a confirmed group when formation is closed' do
    @group.update!(confirmed: true)
    @course.update!(group_formation_closes_at: 1.hour.ago)
    sign_in @leader

    get edit_course_group_path(@course, @group)
    assert_redirected_to dashboard_path
  end

  test 'a lecturer cannot open the Manage page' do
    sign_in @lecturer

    get edit_course_group_path(@course, @group)
    assert_redirected_to dashboard_path
  end

  test 'a coordinator can open the Manage page' do
    sign_in @coordinator

    get edit_course_group_path(@course, @group)
    assert_response :success
  end

  test 'another student cannot open the Manage page' do
    sign_in @other_student

    get edit_course_group_path(@course, @group)
    assert_redirected_to dashboard_path

    patch course_group_path(@course, @group)
    assert_response :not_found
  end

  test 'the leader can delete a not-confirmed group' do
    sign_in @leader

    assert_difference 'ProjectGroup.count', -1 do
      delete course_group_path(@course, @group)
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'another student cannot delete the group' do
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

  test 'a lecturer cannot add a student to a group' do
    sign_in @lecturer

    assert_no_difference '@group.project_group_members.count' do
      post course_group_members_path(@course, @group), params: { user_id: @other_student.id }
    end

    assert_redirected_to dashboard_path
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

  test 'nobody can post a join request while requests are closed' do
    sign_in @other_student

    assert_no_difference 'ProjectGroupInvite.count' do
      post course_group_join_requests_path(@course, @group)
    end

    assert_redirected_to dashboard_path
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

  test 'a student can post a join request to a confirmed group' do
    @group.update!(confirmed: true)
    sign_in @other_student

    assert_difference 'ProjectGroupInvite.count', 1 do
      post course_group_join_requests_path(@course, @group)
    end

    assert_redirected_to course_group_formation_path(@course)
  end

  test 'the leader accepting a request on a confirmed group reopens it' do
    @group.update!(confirmed: true, group_name: 'G001')
    invite = create(:project_group_invite, project_group: @group, sender: @other_student,
                                           recipient: @leader, kind: :direct_request)
    sign_in @leader

    patch course_group_join_request_path(@course, @group, invite), params: { status: 'accepted' }

    assert_redirected_to course_group_formation_path(@course)
    assert invite.reload.accepted?
    assert_not @group.reload.confirmed?
    assert_equal 'Tmp001', @group.group_name
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

  test 'the leader can remove a member from a confirmed group, reopening it' do
    @group.update!(confirmed: true, group_name: 'G001')
    membership = @group.project_group_members.find_by!(user: @member)
    sign_in @leader

    delete course_group_member_path(@course, @group, membership)

    assert_redirected_to course_group_formation_path(@course)
    assert_not @group.reload.confirmed?
    assert_equal 'Tmp001', @group.group_name
    assert_not @group.project_group_members.exists?(user: @member)
  end

  test 'the leader cannot remove a member from a confirmed group when formation is closed' do
    @group.update!(confirmed: true)
    @course.update!(group_formation_closes_at: 1.hour.ago)
    membership = @group.project_group_members.find_by!(user: @member)
    sign_in @leader

    assert_no_difference '@group.project_group_members.count' do
      delete course_group_member_path(@course, @group, membership)
    end

    assert_redirected_to dashboard_path
  end

  test 'the leader can disable the group invite link' do
    link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    sign_in @leader

    delete course_group_invite_link_path(@course, @group)

    assert_redirected_to course_group_formation_path(@course)
    assert_not ProjectGroupInviteLink.exists?(link.id)
  end

  test 'a member and another group leader cannot disable the invite link' do
    link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    other_group = create(:project_group, course: @course, leader_id: @other_student.id)
    create(:project_group_member, project_group: other_group, user: @other_student)

    sign_in @member
    delete course_group_invite_link_path(@course, @group)

    assert_redirected_to dashboard_path
    assert ProjectGroupInviteLink.exists?(link.id)

    sign_in @other_student
    delete course_group_invite_link_path(@course, @group)

    assert_redirected_to dashboard_path
    assert ProjectGroupInviteLink.exists?(link.id)
  end

  test 'a disabled invite link cannot be redeemed' do
    link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    token = link.token
    sign_in @leader
    delete course_group_invite_link_path(@course, @group)

    sign_in @other_student
    assert_no_difference '@group.project_group_members.count' do
      post invite_link_redemption_path(token)
    end

    assert_redirected_to invite_link_path(token)
  end

  test 'a deleted invite link shows the invalid page instead of 404ing' do
    link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    token = link.token
    link.destroy!
    sign_in @other_student

    get invite_link_path(token)

    assert_response :success
    assert_includes response.body, 'This invite link is invalid or has expired.'
  end

  test 'redeeming a deleted invite link shows the invalid page instead of 404ing' do
    link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    token = link.token
    link.destroy!
    sign_in @other_student

    post invite_link_redemption_path(token)

    assert_redirected_to invite_link_path(token)
    follow_redirect!
    assert_response :success
    assert_includes response.body, 'This invite link is invalid or has expired.'
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

  test 'the legacy delete flag no longer lets a student delete a group with a proposal' do
    project_group = @group
    project_group.update!(confirmed: true)
    project = create(:project, course: @course, owner: project_group, owner_type: 'ProjectGroup',
                               supervisor_enrolment: create(:enrolment, :lecturer, course: @course))
    project_group.update_columns(confirmed: false)
    membership = project_group.project_group_members.find_by!(user: @member)
    sign_in @member

    %w[legacy_delete_flag confirm].each do |flag|
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

  test 'every group route 404s on an ungrouped course' do
    ungrouped = create(:course)
    create(:enrolment, :coordinator, user: @coordinator, course: ungrouped)
    group = create(:project_group, course: ungrouped, leader_id: @leader.id)
    membership = create(:project_group_member, project_group: group, user: @leader)
    join_request = create(:project_group_invite, project_group: group, sender: @member,
                                                 recipient: @leader, kind: :direct_request,
                                                 status: :pending)
    invitation = create(:project_group_invite, project_group: group, sender: @leader,
                                               recipient: @member, kind: :direct_invite,
                                               status: :pending)
    sign_in @coordinator

    requests = [
      -> { get course_group_formation_path(ungrouped) },
      -> { get course_groups_path(ungrouped) },
      -> { get course_group_path(ungrouped, group) },
      -> { get edit_course_group_path(ungrouped, group) },
      -> { post course_groups_path(ungrouped), params: { user_id: @member.id } },
      -> { delete course_group_path(ungrouped, group) },
      -> { post course_group_confirmation_path(ungrouped, group) },
      -> { delete course_group_confirmation_path(ungrouped, group) },
      -> { post course_group_invite_link_path(ungrouped, group) },
      -> { post course_group_members_path(ungrouped, group) },
      -> { delete course_group_member_path(ungrouped, group, membership) },
      -> { post course_group_join_requests_path(ungrouped, group) },
      -> { patch course_group_join_request_path(ungrouped, group, join_request), params: { status: 'accepted' } },
      -> { post course_group_invitations_path(ungrouped, group) },
      -> { patch course_group_invitation_path(ungrouped, group, invitation), params: { status: 'accepted' } }
    ]

    requests.each do |request|
      request.call
      assert_response :not_found
    end
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
