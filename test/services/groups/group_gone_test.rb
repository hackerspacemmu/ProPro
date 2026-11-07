require 'test_helper'

module Groups
  class GroupGoneTest < NonTransactionalTestCase
    setup do
      @course = create(:course, grouped: true, grouping_enabled: true, grouping_open: true,
                                group_min: 2, group_max: 4, student_list_finalised: false)
      @leader = create(:user)
      create(:enrolment, course: @course, user: @leader, role: :student)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)

      @joiner = create(:user)
      create(:enrolment, course: @course, user: @joiner, role: :student)
    end

    test 'joining a group deleted while we wait for its lock is blocked as group_gone' do
      release = Queue.new
      holder = hold_group_lock_then_delete(release)

      joiner = Thread.new do
        with_connection do
          GroupJoiner.new(ProjectGroup.find(@group.id), current_user: @joiner).join!
        end
      end

      wait_for_lock_waits(1)
      release << true

      result = Timeout.timeout(10) { joiner.value }

      assert result.blocked?
      assert_equal :group_gone, result.blocked_reason
      assert_equal 'This group no longer exists.', result.message
    ensure
      release << true if release
      joiner&.join(1)
      joiner&.kill
      holder&.join(1)
      holder&.kill
    end

    private

    def hold_group_lock_then_delete(release)
      held = Queue.new

      thread = Thread.new do
        with_connection do
          ProjectGroup.transaction do
            group = ProjectGroup.lock.find(@group.id)
            held << true
            release.pop

            ProjectGroupMember.where(project_group_id: group.id).delete_all
            ProjectGroupInvite.where(project_group_id: group.id).delete_all
            ProjectGroup.where(id: group.id).delete_all
          end
        end
      end

      held.pop
      thread
    end
  end
end
