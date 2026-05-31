require "test_helper"

class ProjectGroupInviteTest < ActiveSupport::TestCase
  def setup
    @course  = create(:course, grouping_enabled: true, student_list_finalised: true,
                               group_min: 2, group_max: 4, grouping_open: true)
    @group   = create(:project_group, course: @course)
    @sender  = create(:user)
    @invite  = build(:project_group_invite, project_group: @group, sender: @sender)
  end

  test "valid invite saves" do
    assert @invite.save
  end

  test "sender can only have one pending request per group" do
    @invite.save!
    duplicate = build(:project_group_invite, project_group: @group, sender: @sender, kind: :request)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:sender_id], "already has a pending request for this group"
  end

  test "sender can re-request after being declined" do
    @invite.update!(status: :declined)
    new_request = build(:project_group_invite, project_group: @group, sender: @sender)
    assert new_request.valid?
  end

  test "sender can request different groups" do
    @invite.save!
    other_group = create(:project_group, course: @course)
    other_request = build(:project_group_invite, project_group: other_group, sender: @sender)
    assert other_request.valid?
  end

  test "pending_for_group scope returns only pending invites for that group" do
    @invite.save!
    declined = create(:project_group_invite, project_group: @group,
                      sender: create(:user), status: :declined)

    results = ProjectGroupInvite.pending_for_group(@group)
    assert_includes results, @invite
    assert_not_includes results, declined
  end

  test "for_course scope returns invites scoped to course" do
    @invite.save!
    other_course = create(:course, grouping_enabled: true, group_min: 2, group_max: 4)
    other_group  = create(:project_group, course: other_course)
    other_invite = create(:project_group_invite, project_group: other_group, sender: create(:user))

    results = ProjectGroupInvite.for_course(@course)
    assert_includes results, @invite
    assert_not_includes results, other_invite
  end
end
