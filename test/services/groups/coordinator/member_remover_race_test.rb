require 'test_helper'

module Groups
  module Coordinator
    class MemberRemoverRaceTest < NonTransactionalTestCase
      setup do
        @course = create(:course, :grouped, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
        @leader = create(:user)
        @member = create(:user)
        [@leader, @member].each { |user| create(:enrolment, :student, course: @course, user: user) }

        @group = create(:project_group, course: @course, leader_id: @leader.id)
        create(:project_group_member, project_group: @group, user: @leader)
        @membership = create(:project_group_member, project_group: @group, user: @member)
      end

      test 'two concurrent removals of the same member remove once and block once' do
        holder_locked = Queue.new
        holder_release = Queue.new
        removers_start = Queue.new
        membership_id = @membership.id
        holder = nil
        removers = []

        holder = Thread.new do
          with_connection do
            ProjectGroup.transaction do
              ProjectGroup.lock.find(@group.id)
              holder_locked << true
              holder_release.pop
            end
          end
        end

        holder_locked.pop

        removers = 2.times.map do
          Thread.new do
            with_connection do
              removers_start.pop
              membership = ProjectGroupMember.find(membership_id)
              MemberRemover.new(membership).remove!
            end
          end
        end

        2.times { removers_start << true }
        wait_for_lock_waits(2)
        holder_release << true

        results = removers.map { |thread| Timeout.timeout(10) { thread.value } }

        assert_equal 1, results.count(&:removed?)
        assert_equal 1, results.count(&:blocked?)
        assert_not ProjectGroupMember.exists?(membership_id)
      ensure
        holder_release << true if holder_release
        [holder, *removers].compact.each { |thread| thread.join(2) || thread.kill }
      end
    end
  end
end
