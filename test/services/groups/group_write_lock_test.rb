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

    test 'the group-write services lock the group row' do
      assert_locks_group { ApprovalToggler.new(@group, locked: true).set! }
      assert_locks_group { Coordinator::ApprovalToggler.new(@group, locked: true).set! }
      assert_locks_group { Deleter.new(@group).delete! }
    end

    test 'coordinator group writes lock the course before the group' do
      assert_locks_course_then_group { Coordinator::MemberRemover.new(@membership).remove! }
      assert_locks_course_then_group { Coordinator::GroupDeleter.new(@group).delete! }
    end

    private

    def assert_locks_group(&)
      statements = capture_sql(&)

      assert statements.any? { |sql| sql.include?('FROM "project_groups"') && sql.include?('FOR UPDATE') },
             "expected a SELECT ... FOR UPDATE on project_groups, got:\n#{statements.join("\n")}"
    end

    def assert_locks_course_then_group(&)
      statements = capture_sql(&)
      course_lock = statements.index { |sql| sql.include?('FROM "courses"') && sql.include?('FOR UPDATE') }
      group_lock = statements.index { |sql| sql.include?('FROM "project_groups"') && sql.include?('FOR UPDATE') }

      assert course_lock, "expected a SELECT ... FOR UPDATE on courses, got:\n#{statements.join("\n")}"
      assert group_lock, "expected a SELECT ... FOR UPDATE on project_groups, got:\n#{statements.join("\n")}"
      assert_operator course_lock, :<, group_lock,
                      "expected the course lock before the group lock, got:\n#{statements.join("\n")}"
    end

    def capture_sql(&)
      statements = []

      callback = lambda do |*args|
        payload = args.last
        statements << payload[:sql] unless payload[:name] == 'SCHEMA'
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
      statements
    end
  end
end
