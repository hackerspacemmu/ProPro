require 'test_helper'

class GroupMemberAdderTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 3, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    @coordinator = create(:user)
    create(:enrolment, course: @course, user: @coordinator, role: :coordinator)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  test 'coordinator adds a student directly, bypassing draft-size legality' do
    # group_min is 3; adding one student brings this group to size 1 — illegal for
    # confirm, but add! doesn't care, only already_grouped?/group_full? gate it.
    result = GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!

    assert result.added?
    assert @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'blocked when student is already grouped elsewhere in the course' do
    other_group = create(:project_group, course: @course, leader_id: @student.id)
    create(:project_group_member, project_group: other_group, user: @student)

    result = GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'blocked when group is already at group_max' do
    2.times do
      filler = create(:user)
      create(:enrolment, course: @course, user: filler, role: :student)
      create(:project_group_member, project_group: @group, user: filler)
    end
    # group_max: 3, currently at 3 (leader + 2 fillers)

    result = GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  # ── Critical: already_grouped?/group_full? run BEFORE @group.with_lock ────────
  # Nothing re-verifies capacity once inside the lock, so a check performed against
  # stale state (e.g. read just before a concurrent add filled the last slot) lets
  # add! push the group over group_max. Demonstrated deterministically below by
  # stubbing group_full? to return the stale (false) answer a racing caller could
  # have seen, rather than relying on real thread timing (which can't reliably
  # reproduce a check-then-lock race in a fast, deterministic test).

  test 'a stale group_full? read lets add! push the group over its group_max' do
    2.times do
      filler = create(:user)
      create(:enrolment, course: @course, user: filler, role: :student)
      create(:project_group_member, project_group: @group, user: filler)
    end
    assert_equal @course.group_max, @group.project_group_members.count, 'group starts exactly at capacity'

    adder = GroupMemberAdder.new(@group, user: @student, current_user: @coordinator)
    adder.define_singleton_method(:group_full?) { |_course| false } # the stale read a race would produce

    result = adder.add!

    assert result.added?, 'nothing inside with_lock re-checks capacity — this is the bug'
    assert_operator @group.project_group_members.reload.count, :>, @course.group_max
  end

  # ── Edge: no check that @user is actually enrolled as a student in the course ──

  test 'CURRENT BEHAVIOR: coordinator can add a user with no enrolment in the course at all' do
    outsider = create(:user) # deliberately not enrolled anywhere

    result = GroupMemberAdder.new(@group, user: outsider, current_user: @coordinator).add!

    assert result.added?, 'confirm intentional — no enrolment/role check exists in this service today'
    assert @group.project_group_members.exists?(user_id: outsider.id)
  end
end
