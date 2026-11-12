require 'test_helper'

module Groups
  class ConfirmerRaceTest < NonTransactionalTestCase
    setup do
      @course = create(:course, grouped: true, group_formation_enabled: true,
                                group_min: 2, group_max: 3, student_list_finalised: true)
      students = Array.new(5) do
        create(:user).tap { |user| create(:enrolment, :student, course: @course, user: user) }
      end

      @groups = students.first(4).each_slice(2).map do |leader, member|
        group = create(:project_group, course: @course, leader_id: leader.id)
        create(:project_group_member, project_group: group, user: leader)
        create(:project_group_member, project_group: group, user: member)
        group
      end
    end

    test 'two groups confirming at once are never both confirmed when only one fits' do
      release = Queue.new
      holder = hold_course_lock(release)
      start = Queue.new

      threads = @groups.map do |group|
        Thread.new do
          with_connection do
            start.pop
            GroupConfirmer.new(ProjectGroup.find(group.id)).confirm!
          end
        end
      end

      2.times { start << true }
      wait_for_lock_waits(2)
      release << true

      results = Timeout.timeout(10) { threads.map(&:value) }

      assert_equal 1, results.count(&:confirmed?)
      assert_equal(1, results.count { |result| result.blocked_reason == :size_illegal })
      assert_equal 1, @course.project_groups.where(confirmed: true).count
    ensure
      release << true if release
      (threads || []).each { |thread| thread.join(1) || thread.kill }
      holder&.join(1)
      holder&.kill
    end

    private

    def hold_course_lock(release)
      held = Queue.new

      thread = Thread.new do
        with_connection do
          @course.with_no_key_update_lock do
            held << true
            release.pop
          end
        end
      end

      held.pop
      thread
    end
  end
end
