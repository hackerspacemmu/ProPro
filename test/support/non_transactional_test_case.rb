# Shared setup for tests that need real concurrent connections. Transactional
# tests share one connection, so row locks never conflict between threads.
module TestSupport
  module NonTransactional
    extend ActiveSupport::Concern

    included do
      self.use_transactional_tests = false
      self.fixture_table_names = []

      setup do
        DatabaseCleaner.strategy = :truncation
        DatabaseCleaner.start
      end

      teardown do
        DatabaseCleaner.clean
      end
    end

    def with_connection(&) = ActiveRecord::Base.connection_pool.with_connection(&)

    def wait_for_lock_wait(count = 1) = wait_for_lock_waits(count)

    def wait_for_lock_waits(count)
      Timeout.timeout(5) do
        loop do
          waiting = ActiveRecord::Base.uncached do
            ActiveRecord::Base.connection.select_value('SELECT count(*) FROM pg_locks WHERE NOT granted').to_i
          end
          return if waiting >= count

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

class NonTransactionalTestCase < ActiveSupport::TestCase
  include TestSupport::NonTransactional
end
