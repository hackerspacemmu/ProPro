require 'test_helper'

module Groups
  module Coordinator
    class ImporterTest < ActiveSupport::TestCase
      setup do
        @course = create(:course, :grouped, grouping_enabled: false)
        @alice = create(:user)
        @bob = create(:user)
        @carol = create(:user)
      end

      test 'creates a confirmed group with the first member as leader and the imported name' do
        result = Importer.new(@course).import!('Team A' => [@alice, @bob])

        group = @course.project_groups.find_by!(group_name: 'Team A')
        assert_not result.blocked?
        assert group.confirmed?
        assert group.origin_import?
        assert_equal @alice.id, group.leader_id
        assert_equal [@alice.id, @bob.id].sort, group.project_group_members.pluck(:user_id).sort
        assert_equal [@course.id], group.project_group_members.distinct.pluck(:course_id)
      end

      test 'confirming never renames an imported group' do
        Importer.new(@course).import!('Team A' => [@alice, @bob, @carol])

        group = @course.project_groups.find_by!(group_name: 'Team A')
        GroupConfirmer.new(group).confirm!

        assert_equal 'Team A', group.reload.group_name
      end

      test 'locks the course without a key update' do
        statements = capture_sql { Importer.new(@course).import!('Team A' => [@alice]) }

        assert statements.any? { |sql| sql.include?('FROM "courses"') && sql.include?('FOR NO KEY UPDATE') },
               "expected a SELECT ... FOR NO KEY UPDATE on courses, got:\n#{statements.join("\n")}"
      end

      test 'works with the grouping window closed' do
        assert_not @course.grouping_window_open?

        assert_not Importer.new(@course).import!('Team A' => [@alice]).blocked?
      end

      test 'blocks when the course is not grouped' do
        solo = create(:course, grouped: false)

        result = Importer.new(solo).import!('Team A' => [@alice])

        assert result.blocked?
        assert_equal :not_grouped, result.blocked_reason
        assert_equal 0, solo.project_groups.count
      end

      test 'a project can be created for an imported group' do
        Importer.new(@course).import!('Team A' => [@alice])
        group = @course.project_groups.find_by!(group_name: 'Team A')
        supervisor = create(:enrolment, :lecturer, course: @course)

        project = Project.new(course: @course, owner: group, supervisor_enrolment: supervisor)

        assert project.valid?, project.errors.full_messages.to_sentence
      end

      test 'reusing a group by name keeps its status and leader' do
        group = create(:project_group, course: @course, group_name: 'Team A', confirmed: false, leader_id: @alice.id)
        create(:project_group_member, project_group: group, user: @alice)

        Importer.new(@course).import!('Team A' => [@alice, @bob])

        group.reload
        assert_not group.confirmed?
        assert group.origin_formation?
        assert_equal @alice.id, group.leader_id
        assert_equal 2, group.project_group_members.count
        assert_equal 1, @course.project_groups.where(group_name: 'Team A').count
      end

      test 'a reused group without a leader gets its earliest member as leader' do
        group = create(:project_group, course: @course, group_name: 'Team A', confirmed: false, leader_id: nil)
        create(:project_group_member, project_group: group, user: @alice)

        Importer.new(@course).import!('Team A' => [@alice, @bob])

        assert_equal @alice.id, group.reload.leader_id
      end

      test 'a student already in another group is not moved and is reported' do
        other = create(:project_group, course: @course, group_name: 'Team B', leader_id: @carol.id)
        create(:project_group_member, project_group: other, user: @carol)

        result = Importer.new(@course).import!('Team A' => [@alice, @carol])

        assert_equal other.id, @course.project_group_members.find_by!(user_id: @carol.id).project_group_id
        assert_equal([@carol], result.skipped.map { |entry| entry[:user] })
        assert_equal ["#{@carol.name} was already in a group and wasn't moved."], result.skipped_messages
      end

      test 'a skipped student leaves the leader of their own group untouched' do
        other = create(:project_group, course: @course, group_name: 'Team B', leader_id: @carol.id)
        create(:project_group_member, project_group: other, user: @carol)

        Importer.new(@course).import!('Team A' => [@carol])

        assert_equal @carol.id, other.reload.leader_id
        assert_equal 1, other.project_group_members.count
      end

      test 'a new group whose members are all skipped is not created' do
        other = create(:project_group, course: @course, group_name: 'Team B', leader_id: @carol.id)
        create(:project_group_member, project_group: other, user: @carol)

        result = Importer.new(@course).import!('Team A' => [@carol])

        assert_nil @course.project_groups.find_by(group_name: 'Team A')
        assert_equal 1, result.skipped.size
      end

      test 'clears pending invites for every imported student, including skipped ones' do
        other = create(:project_group, course: @course, group_name: 'Team B', leader_id: @carol.id)
        create(:project_group_member, project_group: other, user: @carol)
        placed_invite = create(:project_group_invite, project_group: other, sender: @alice,
                                                      recipient: @carol, kind: :direct_request)
        skipped_invite = create(:project_group_invite, project_group: other, sender: @carol,
                                                       recipient: @alice, kind: :direct_invite)

        Importer.new(@course).import!('Team A' => [@alice, @carol])

        assert_not ProjectGroupInvite.exists?(placed_invite.id)
        assert_not ProjectGroupInvite.exists?(skipped_invite.id)
      end

      test 'importing the same CSV twice changes nothing' do
        Importer.new(@course).import!('Team A' => [@alice, @bob])

        assert_no_difference ['ProjectGroup.count', 'ProjectGroupMember.count'] do
          result = Importer.new(@course).import!('Team A' => [@alice, @bob])
          assert_not result.skipped?
        end
      end

      private

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
end
