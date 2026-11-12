require 'test_helper'

module Groups
  class KickerTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      @course = create(:course, :grouped, group_formation_enabled: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @member = create(:user)
      @other = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
      @membership = create(:project_group_member, project_group: @group, user: @member)
      create(:project_group_member, project_group: @group, user: @other)
    end

    test 'the leader can remove another member' do
      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.removed?
      assert_not @group.project_group_members.exists?(user: @member)
      assert_equal @leader.id, @group.reload.leader_id
    end

    test 'a non-leader cannot remove a member' do
      result = Kicker.new(@membership, current_user: @other).kick!

      assert result.blocked?
      assert_equal :not_leader, result.blocked_reason
      assert @group.project_group_members.exists?(user: @member)
    end

    test 'the leader cannot remove themselves' do
      membership = @group.project_group_members.find_by!(user: @leader)

      result = Kicker.new(membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :self_kick, result.blocked_reason
    end

    test 'blocks a member who was already removed' do
      @membership.destroy!

      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :already_removed, result.blocked_reason
    end

    test 'the leader removing a member from a confirmed group reopens it' do
      @group.update!(confirmed: true, group_name: 'G001')
      create(:project_group_invite_link, project_group: @group)

      assert_enqueued_jobs 2 do
        result = Kicker.new(@membership, current_user: @leader).kick!

        assert result.removed?
        assert result.reopened?
        assert_equal 'Tmp001', result.new_name
        assert_equal "Group reopened because #{@member.name} was removed.", result.message
      end

      assert_not @group.reload.confirmed?
      assert_equal 'Tmp001', @group.group_name
      assert_not @group.project_group_members.exists?(user: @member)
      assert_not @group.project_group_invite_links.exists?
    end

    test 'a kick from a not-confirmed group sends no reopen notification' do
      assert_enqueued_jobs 0 do
        result = Kicker.new(@membership, current_user: @leader).kick!

        assert result.removed?
        assert_not result.reopened?
      end
    end

    test 'blocks a confirmed group that was imported' do
      @group.update!(confirmed: true, origin: :import)

      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :imported_group, result.blocked_reason
      assert @group.project_group_members.exists?(user: @member)
    end

    test 'blocks a confirmed group that has a project' do
      @group.update!(confirmed: true)
      supervisor = create(:enrolment, :lecturer, course: @course)
      Project.create!(course: @course, owner: @group, supervisor_enrolment: supervisor)

      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :has_project, result.blocked_reason
      assert @group.project_group_members.exists?(user: @member)
    end

    test 'blocks when formation is closed' do
      @course.update!(group_formation_closes_at: 1.hour.ago)

      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :formation_closed, result.blocked_reason
    end
  end
end

module Groups
  class KickerRaceTest < NonTransactionalTestCase
    setup do
      @course = create(:course, :grouped, group_formation_enabled: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @target = create(:user)
      @joiner = create(:user)
      [@leader, @target, @joiner].each do |user|
        create(:enrolment, :student, course: @course, user: user)
      end
      @group = create(:project_group, course: @course, leader_id: @leader.id,
                                      confirmed: true, group_name: 'G001')
      create(:project_group_member, project_group: @group, user: @leader)
      @membership = create(:project_group_member, project_group: @group, user: @target)
      @link = create(:project_group_invite_link, project_group: @group, sender: @leader,
                                                 expires_at: 1.hour.from_now)
    end

    test 'a kick racing a redemption serialises without a deadlock' do
      start = Queue.new
      kick = Thread.new do
        with_connection do
          start.pop
          Kicker.new(ProjectGroupMember.find(@membership.id), current_user: @leader).kick!
        end
      end
      redeem = Thread.new do
        with_connection do
          start.pop
          GroupInviteLinkRedeemer.new(ProjectGroupInviteLink.find(@link.id),
                                      current_user: @joiner).redeem!
        end
      end

      2.times { start << true }
      Timeout.timeout(10) do
        kick.value
        redeem.value
      end

      @group.reload
      assert_not @group.confirmed?
      assert_not @group.project_group_members.exists?(user: @target)
      unless @group.project_group_members.exists?(user: @joiner)
        assert_not ProjectGroupInviteLink.exists?(@link.id),
                   'a refused redemption must be explained by the kick clearing the link'
      end
    ensure
      [kick, redeem].compact.each { |thread| thread.join(1) || thread.kill }
    end
  end
end
