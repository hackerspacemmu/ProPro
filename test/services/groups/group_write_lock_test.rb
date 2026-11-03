require 'test_helper'

module Groups
  # These tests need committed rows on separate connections, because a row lock
  # in a transaction that never commits cannot be observed by another thread.
  class GroupWriteLockTest < ActiveSupport::TestCase
    self.use_transactional_tests = false
    self.fixture_table_names = []

    setup do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.start

      @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @member = create(:user)
      @other = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
      @membership = create(:project_group_member, project_group: @group, user: @member)
      create(:project_group_member, project_group: @group, user: @other)
    end

    teardown do
      DatabaseCleaner.clean
    end

    test 'the formation group-write services lock the group row' do
      assert_locks_group { LeaderPromoter.new(@group, target_user_id: @member.id).promote! }
      assert_locks_group { ApprovalToggler.new(@group, locked: true).set! }
      assert_locks_group { Deleter.new(@group).delete! }
    end

    test 'leader promotion racing a removal never leaves a leader who is not a member' do
      pause_for_find = Queue.new
      resume_promotion = Queue.new
      removal_happened = Queue.new

      install_race_callbacks(pause_for_find, resume_promotion, removal_happened)

      promotion = Thread.new do
        Thread.current[:race_pause_member_id] = @membership.id
        LeaderPromoter.new(@group, target_user_id: @member.id).promote!
      end

      assert pause_for_find.pop(timeout: 2), 'Leader promotion never read the target member'

      removal = Thread.new do
        Thread.current[:race_removal_member_id] = @membership.id
        Coordinator::MemberRemover.new(@membership).remove!
      end

      # The remover finishes at once without the group lock. With the lock it is
      # waiting behind the pause, so resume the promotion and let it proceed.
      removal_happened.pop(timeout: 0.5)
      resume_promotion << true

      promotion.value
      removal.value

      @group.reload
      assert @group.project_group_members.exists?(user_id: @group.leader_id),
             'the group leader must still be a member'
    ensure
      remove_race_callbacks
    end

    private

    def assert_locks_group(&)
      statements = []

      callback = lambda do |*args|
        payload = args.last
        statements << payload[:sql] unless payload[:name] == 'SCHEMA'
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)

      assert statements.any? { |sql| sql.include?('FROM "project_groups"') && sql.include?('FOR UPDATE') },
             "expected a SELECT ... FOR UPDATE on project_groups, got:\n#{statements.join("\n")}"
    end

    def install_race_callbacks(pause_for_find, resume_promotion, removal_happened)
      ProjectGroupMember.class_eval do
        define_method(:pause_for_group_write_race) do
          return unless Thread.current[:race_pause_member_id] == id

          pause_for_find << true
          resume_promotion.pop
        end

        define_method(:signal_group_write_race_removal) do
          removal_happened << true if Thread.current[:race_removal_member_id] == id
        end

        after_find :pause_for_group_write_race
        after_destroy :signal_group_write_race_removal
      end
    end

    def remove_race_callbacks
      ProjectGroupMember.skip_callback(:find, :after, :pause_for_group_write_race)
      ProjectGroupMember.skip_callback(:destroy, :after, :signal_group_write_race_removal)
    end
  end
end
