require 'test_helper'

class GroupInviteLinkGeneratorTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 4, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'leader generates a link — created with a 16-byte token and 24h expiry' do
    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.generated?
    assert result.token.present?
    assert_equal 16, Base64.urlsafe_decode64(result.token).bytesize
    assert_in_delta 24.hours.from_now, result.expires_at, 5.seconds

    link = @group.project_group_invite_links.find_by(sender: @leader)
    assert_equal result.token, link.token
  end

  test 'regenerating destroys this sender\'s old link and creates a new one' do
    first = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!
    second = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert_not_equal first.token, second.token
    assert_equal 1, @group.project_group_invite_links.where(sender: @leader).count
    assert_not ProjectGroupInviteLink.exists?(token: first.token)
  end

  test 'generating a link replaces every link for the group' do
    other_member = create(:user)
    create(:enrolment, course: @course, user: other_member, role: :student)
    create(:project_group_member, project_group: @group, user: other_member)
    other_link = GroupInviteLinkGenerator.new(@group, current_user: other_member).generate!

    GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert_not ProjectGroupInviteLink.exists?(token: other_link.token)
    assert_equal 1, @group.project_group_invite_links.count
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  # ── Edge: leadership transfer doesn't revoke the ex-leader's existing link ────

  test 'a link generated before a leadership transfer stays fully valid after the transfer' do
    old_leader_link = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    new_leader = create(:user)
    create(:enrolment, course: @course, user: new_leader, role: :student)
    create(:project_group_member, project_group: @group, user: new_leader)
    @group.update!(leader_id: new_leader.id) # simulates leader succession

    assert ProjectGroupInviteLink.exists?(token: old_leader_link.token)
    link = ProjectGroupInviteLink.find_by(token: old_leader_link.token)
    assert_not link.expires_at.past?
  end
end

class GroupInviteLinkGeneratorRaceTest < NonTransactionalTestCase
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 4, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'the window closing while the generator waits blocks it' do
    release = Queue.new
    holder = hold_group_lock(release)
    thread = generator_thread

    wait_for_lock_wait
    @course.update_column(:grouping_open, false)
    release << true

    result = Timeout.timeout(10) { thread.value }

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
    assert_equal 0, @group.project_group_invite_links.count
  ensure
    release << true if release
    thread&.join(1)
    thread&.kill
    holder&.join(1)
    holder&.kill
  end

  test 'the group becoming confirmed while the generator waits blocks it' do
    release = Queue.new
    mutation = Queue.new
    holder = hold_group_lock(release) do
      mutation.pop
      @group.update_column(:confirmed, true)
    end
    thread = generator_thread

    wait_for_lock_wait
    mutation << true
    release << true

    result = Timeout.timeout(10) { thread.value }

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
    assert_equal 0, @group.project_group_invite_links.count
  ensure
    release << true if release
    thread&.join(1)
    thread&.kill
    holder&.join(1)
    holder&.kill
  end

  private

  def generator_thread
    Thread.new do
      with_connection do
        GroupInviteLinkGenerator.new(ProjectGroup.find(@group.id), current_user: @leader).generate!
      end
    end
  end

  def hold_group_lock(release)
    held = Queue.new

    thread = Thread.new do
      with_connection do
        ProjectGroup.transaction do
          ProjectGroup.lock.find(@group.id)
          held << true
          yield if block_given?
          release.pop
        end
      end
    end

    held.pop
    thread
  end
end
