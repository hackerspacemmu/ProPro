require 'test_helper'

class ProjectGroupStudentActionsTest < ActiveSupport::TestCase
  def setup
    @course = create(:course,
                     grouping_enabled: true,
                     student_list_finalised: false,
                     group_min: 2,
                     group_max: 4,
                     grouping_open: true)
    @alice = create(:user)
    @bob   = create(:user)
    @carol = create(:user)

    @group = create(:project_group, course: @course, leader_id: @alice.id)
    create(:project_group_member, project_group: @group, user: @alice,
                                  created_at: 1.hour.ago)
    create(:project_group_member, project_group: @group, user: @bob,
                                  created_at: 30.minutes.ago)
  end

  # ── confirm! ──────────────────────────────────────────────────────────────

  test 'confirm! confirms a legal group' do
    # group has alice + bob (2 members), min is 2
    assert @group.confirm!
    assert @group.reload.confirmed?
  end

  test 'confirm! returns false when can_confirm? is false' do
    solo = create(:project_group, course: @course, leader_id: @carol.id)
    create(:project_group_member, project_group: solo, user: @carol)
    # only 1 member, min is 2
    assert_not solo.confirm!
    assert_not solo.reload.confirmed?
  end

  test 'confirm! does not persist when guard fails' do
    solo = create(:project_group, course: @course, leader_id: @carol.id)
    create(:project_group_member, project_group: solo, user: @carol)
    solo.confirm!
    assert_not solo.reload.confirmed?
  end

  # ── assign_next_leader! ───────────────────────────────────────────────────

  test 'assign_next_leader! promotes earliest-joined member' do
    # alice joined first (1.hour.ago), bob joined second
    # if alice leaves, bob should become leader
    @group.remove_member!(@alice)
    assert_equal @bob.id, @group.reload.leader_id
  end

  test 'assign_next_leader! dissolves group when no members remain' do
    # remove everyone
    @group.project_group_members.order(created_at: :desc).each do |m|
      user = m.user
      # last member triggers dissolve via remove_member!
      if @group.project_group_members.count == 1
        # capture id before dissolve
        gid = @group.id
        begin
          @group.remove_member!(user)
        rescue StandardError
          nil
        end
        assert_not ProjectGroup.exists?(gid)
        return
      else
        @group.remove_member!(user)
      end
    end
  end

  # ── remove_member! ────────────────────────────────────────────────────────

  test 'remove_member! removes the member record' do
    @group.remove_member!(@bob)
    assert_not @group.project_group_members.exists?(user_id: @bob.id)
  end

  test 'remove_member! reverts confirmed group when it falls below min' do
    @group.confirm!
    assert @group.reload.confirmed?

    # removing bob leaves 1 member (alice), below min of 2
    @group.remove_member!(@bob)
    assert_not @group.reload.confirmed?
  end

  test 'remove_member! raises if user is not a member' do
    stranger = create(:user)
    assert_raises(ActiveRecord::RecordNotFound) do
      @group.remove_member!(stranger)
    end
  end

  # ── dissolve! ─────────────────────────────────────────────────────────────

  test 'dissolve! destroys the group' do
    gid = @group.id
    @group.dissolve!
    assert_not ProjectGroup.exists?(gid)
  end

  test 'dissolve! destroys pending invites' do
    invite = create(:project_group_invite, project_group: @group, sender: @carol)
    iid = invite.id
    @group.dissolve!
    assert_not ProjectGroupInvite.exists?(iid)
  end

  # ── pending_requests ──────────────────────────────────────────────────────

  test 'pending_requests returns only pending request invites' do
    pending  = create(:project_group_invite, project_group: @group, sender: @carol, status: :pending)
    declined = create(:project_group_invite, project_group: @group, sender: create(:user), status: :declined)

    assert_includes     @group.pending_requests, pending
    assert_not_includes @group.pending_requests, declined
  end

  # ── leader? helper ────────────────────────────────────────────────────────

  test 'leader? returns true for group leader' do
    assert @group.leader?(@alice)
    assert_not @group.leader?(@bob)
  end
end
