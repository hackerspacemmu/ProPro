require 'test_helper'

module Groups
  module Coordinator
    class MemberRemoverTest < ActiveSupport::TestCase
      setup do
        @course = create(:course, :grouped, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
        @leader = create(:user)
        @member = create(:user)
        @other = create(:user)
        @group = create(:project_group, course: @course, leader_id: @leader.id, confirmed: true)
        @leader_membership = create(:project_group_member, project_group: @group, user: @leader)
        @membership = create(:project_group_member, project_group: @group, user: @member)
        create(:project_group_member, project_group: @group, user: @other)
      end

      test 'removes a member in any state without changing the status' do
        result = MemberRemover.new(@membership).remove!

        assert result.removed?
        assert @group.reload.confirmed?
        assert_not @group.project_group_members.exists?(user: @member)
      end

      test 'replaces a removed leader with the earliest remaining member' do
        @membership.update_columns(created_at: Time.zone.parse('2024-01-01 10:00:00'))
        @group.project_group_members.find_by!(user: @other)
              .update_columns(created_at: Time.zone.parse('2024-01-02 10:00:00'))

        result = MemberRemover.new(@leader_membership).remove!

        assert result.removed?
        assert_equal @member.id, @group.reload.leader_id
      end

      test 'the last member of a group without a proposal is removed with the group' do
        @group.project_group_members.where.not(user_id: @member.id).destroy_all

        result = MemberRemover.new(@membership).remove!

        assert result.group_deleted?
        assert_not ProjectGroup.exists?(@group.id)
      end

      test 'the last member of a group with a proposal needs confirmation' do
        @group.project_group_members.where.not(user_id: @member.id).destroy_all
        supervisor = create(:enrolment, :lecturer, course: @course)
        project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                                   supervisor_enrolment: supervisor)
        create(:project_instance, project: project, supervisor_enrolment: supervisor, title: 'Group Proposal')

        result = MemberRemover.new(@membership).remove!

        assert result.needs_confirmation?
        assert_equal 'Group Proposal', result.project_title
        assert ProjectGroup.exists?(@group.id)
        assert Project.exists?(project.id)
        assert ProjectGroupMember.exists?(@membership.id)
      end

      test 'confirmed removal deletes the group and proposal' do
        @group.project_group_members.where.not(user_id: @member.id).destroy_all
        project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                                   supervisor_enrolment: create(:enrolment, :lecturer, course: @course))

        result = MemberRemover.new(@membership, confirm: true).remove!

        assert result.group_deleted?
        assert_not ProjectGroup.exists?(@group.id)
        assert_not Project.exists?(project.id)
      end

      test 'blocks a member who was already removed' do
        @membership.destroy!

        result = MemberRemover.new(@membership).remove!

        assert result.blocked?
        assert_equal :already_removed, result.blocked_reason
      end
    end
  end
end
