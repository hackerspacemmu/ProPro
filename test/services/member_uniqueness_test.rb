require 'test_helper'

# Two requests can pass the exists? checks together. The unique index then refuses the
# second insert, and each service reports it as already_grouped.
class MemberUniquenessTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, grouped: true, grouping_enabled: true,
                              group_min: 2, group_max: 4, student_list_finalised: false)
    @leader = create(:user)
    @student = create(:user)
    @coordinator = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    create(:enrolment, course: @course, user: @student, role: :student)
    create(:enrolment, course: @course, user: @coordinator, role: :coordinator)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'joiner reports already_grouped' do
    result = ProjectGroupMember.stub(:add, false) { GroupJoiner.new(@group, current_user: @student).join! }

    assert_equal :already_grouped, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'adder reports already_grouped' do
    result = ProjectGroupMember.stub(:add, false) do
      GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!
    end

    assert_equal :already_grouped, result.blocked_reason
  end

  test 'creator reports already_grouped and leaves no group behind' do
    result = ProjectGroupMember.stub(:add, false) do
      GroupCreator.new(@course, leader: @student, current_user: @student).create!
    end

    assert_equal :already_grouped, result.blocked_reason
    assert_equal 0, @course.project_groups.where(leader_id: @student.id).count
  end
end
