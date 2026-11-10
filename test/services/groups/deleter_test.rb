require 'test_helper'

module Groups
  class DeleterTest < ActiveSupport::TestCase
    setup do
      @course = create(:course, :grouped, grouping_enabled: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
    end

    test 'deletes a not-confirmed group while formation is open' do
      result = Deleter.new(@group).delete!

      assert result.deleted?
      assert_not ProjectGroup.exists?(@group.id)
    end

    test 'blocks when the group is confirmed' do
      @group.update!(confirmed: true)

      result = Deleter.new(@group).delete!

      assert result.blocked?
      assert_equal :group_confirmed, result.blocked_reason
      assert ProjectGroup.exists?(@group.id)
    end

    test 'blocks when formation is closed' do
      @course.update!(grouping_closes_at: 1.hour.ago)

      result = Deleter.new(@group).delete!

      assert result.blocked?
      assert_equal :window_closed, result.blocked_reason
    end

    test 'blocks when the group owns a proposal' do
      @group.update_columns(confirmed: true)
      project = create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                                 supervisor_enrolment: create(:enrolment, :lecturer, course: @course))
      @group.update_columns(confirmed: false)

      result = Deleter.new(@group).delete!

      assert result.blocked?
      assert_equal :has_project, result.blocked_reason
      assert ProjectGroup.exists?(@group.id)
      assert Project.exists?(project.id)
    end
  end
end
