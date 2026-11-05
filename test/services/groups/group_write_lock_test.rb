require 'test_helper'

module Groups
  class GroupWriteLockTest < ActiveSupport::TestCase
    self.use_transactional_tests = false
    self.fixture_table_names = []

    setup do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.start

      @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @member = create(:user)
      @joiner = create(:user)
      [@leader, @member, @joiner].each { |user| create(:enrolment, :student, course: @course, user: user) }

      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
      @membership = create(:project_group_member, project_group: @group, user: @member)
    end

    teardown do
      DatabaseCleaner.clean
    end

    test 'a coordinator write and a concurrent join do not deadlock on the course lock' do
      group_locked = Queue.new
      join_now = Queue.new
      joined = nil

      joiner_thread = Thread.new do
        with_connection do
          ProjectGroup.transaction do
            ProjectGroup.lock.find(@group.id)
            group_locked << true
            join_now.pop

            joined = GroupJoiner.new(ProjectGroup.find(@group.id), current_user: @joiner).join!
          end
        end
      end

      group_locked.pop

      remover_thread = Thread.new do
        with_connection do
          membership = ProjectGroupMember.find(@membership.id)
          Coordinator::MemberRemover.new(membership).remove!
        end
      end

      wait_for_lock_wait
      join_now << true

      removed = Timeout.timeout(10) { remover_thread.value }
      Timeout.timeout(10) { joiner_thread.value }

      assert removed.removed?
      assert joined.joined?
      assert @group.reload.project_group_members.exists?(user: @joiner)
      assert_not @group.project_group_members.exists?(user: @member)
    ensure
      join_now << true if join_now
      [joiner_thread, remover_thread].compact.each { |thread| thread.join(2) || thread.kill }
    end

    test 'group-write services lock the group row' do
      assert_locks_group { with_group { |_group, _leader, membership| Leaver.new(membership).leave! } }
      assert_locks_group { with_group { |_group, leader, membership| Kicker.new(membership, current_user: leader).kick! } }
      assert_locks_group { with_group { |group, _leader, _membership| Deleter.new(group).delete! } }
    end

    test 'coordinator group writes lock the course before the group' do
      assert_locks_course_then_group { with_group { |_group, _leader, membership| Coordinator::MemberRemover.new(membership).remove! } }
      assert_locks_course_then_group { with_group { |group, _leader, _membership| Coordinator::GroupDeleter.new(group).delete! } }
    end

    test 'group-creating services lock the course without a key update' do
      assert_locks_course do
        with_course { |course, user| GroupCreator.new(course, leader: user, current_user: user).create! }
      end
      assert_locks_course do
        with_course { |course, _user| Coordinator::Importer.new(course).import!({}) }
      end
    end

    private

    def with_connection(&) = ActiveRecord::Base.connection_pool.with_connection(&)

    def with_group
      course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      leader = create(:user)
      member = create(:user)
      group = create(:project_group, course: course, leader_id: leader.id)
      create(:project_group_member, project_group: group, user: leader)
      membership = create(:project_group_member, project_group: group, user: member)
      yield group, leader, membership
    end

    def with_course
      course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      user = create(:user)
      create(:enrolment, :student, course: course, user: user)
      yield course, user
    end

    def wait_for_lock_wait
      Timeout.timeout(5) do
        loop do
          waiting = ActiveRecord::Base.uncached do
            ActiveRecord::Base.connection.select_value('SELECT count(*) FROM pg_locks WHERE NOT granted').to_i
          end
          return if waiting.positive?

          sleep 0.01
        end
      end
    end

    def assert_locks_group(&)
      statements = capture_sql(&)

      assert statements.any? { |sql| sql.include?('FROM "project_groups"') && sql.include?('FOR UPDATE') },
             "expected a SELECT ... FOR UPDATE on project_groups, got:\n#{statements.join("\n")}"
    end

    def assert_locks_course(&)
      statements = capture_sql(&)

      assert statements.any? { |sql| sql.include?('FROM "courses"') && sql.include?('FOR NO KEY UPDATE') },
             "expected a SELECT ... FOR NO KEY UPDATE on courses, got:\n#{statements.join("\n")}"
    end

    def assert_locks_course_then_group(&)
      statements = capture_sql(&)
      course_lock = statements.index { |sql| sql.include?('FROM "courses"') && sql.include?('FOR NO KEY UPDATE') }
      group_lock = statements.index { |sql| sql.include?('FROM "project_groups"') && sql.include?('FOR UPDATE') }

      assert course_lock, "expected a SELECT ... FOR NO KEY UPDATE on courses, got:\n#{statements.join("\n")}"
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
