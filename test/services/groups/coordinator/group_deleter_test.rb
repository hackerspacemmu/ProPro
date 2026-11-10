require 'test_helper'

module Groups
  module Coordinator
    class GroupDeleterTest < ActiveSupport::TestCase
      setup do
        @course = create(:course, :grouped, grouping_enabled: true, grouping_closes_at: 1.hour.ago, group_min: 2, group_max: 4)
        @leader = create(:user)
        @group = create(:project_group, course: @course, leader_id: @leader.id, confirmed: true)
        create(:project_group_member, project_group: @group, user: @leader)
        @supervisor = create(:enrolment, :lecturer, course: @course)
      end

      test 'deletes a group without a proposal immediately' do
        result = GroupDeleter.new(@group).delete!

        assert result.deleted?
        assert_not ProjectGroup.exists?(@group.id)
      end

      test 'a group with a proposal only needs confirmation when it has one' do
        project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                                   supervisor_enrolment: @supervisor)
        create(:project_instance, project: project, supervisor_enrolment: @supervisor, title: 'Group Proposal')

        result = GroupDeleter.new(@group).delete!

        assert result.needs_confirmation?
        assert_equal 'Group Proposal', result.project_title
        assert ProjectGroup.exists?(@group.id)
        assert Project.exists?(project.id)
      end

      test 'deletes a confirmed group and its proposal after confirmation' do
        project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                                   supervisor_enrolment: @supervisor)

        result = GroupDeleter.new(@group, confirm: true).delete!

        assert result.deleted?
        assert_not ProjectGroup.exists?(@group.id)
        assert_not Project.exists?(project.id)
      end
    end
  end
end
