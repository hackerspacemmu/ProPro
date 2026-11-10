require 'test_helper'

class ProjectGroupInviteTest < ActiveSupport::TestCase
  def setup
    @course  = create(:course, grouping_enabled: true, student_list_finalised: true,
                               group_min: 2, group_max: 4)
    @group   = create(:project_group, course: @course)
    @sender  = create(:user)
    @invite  = build(:project_group_invite, project_group: @group, sender: @sender)
  end

  test 'valid invite saves' do
    assert @invite.save
  end

  test 'sender can only have one pending request per group' do
    @invite.save!
    duplicate = build(:project_group_invite, project_group: @group, sender: @sender, kind: :direct_request)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:sender_id], 'already has a pending request for this group'
  end

  test 'sender can re-request after being declined' do
    @invite.update!(status: :declined)
    new_request = build(:project_group_invite, project_group: @group, sender: @sender)
    assert new_request.valid?
  end

  test 'sender can request different groups' do
    @invite.save!
    other_group = create(:project_group, course: @course)
    other_request = build(:project_group_invite, project_group: other_group, sender: @sender)
    assert other_request.valid?
  end

  test 'pending_for_group scope returns only pending invites for that group' do
    @invite.save!
    declined = create(:project_group_invite, project_group: @group,
                                             sender: create(:user), status: :declined)

    results = ProjectGroupInvite.pending_for_group(@group)
    assert_includes results, @invite
    assert_not_includes results, declined
  end

  test 'clear_pending_for! deletes the user\'s pending sent and received invites in the course' do
    sent = create(:project_group_invite, project_group: @group, sender: @sender,
                                         recipient: create(:user), kind: :direct_request, status: :pending)
    received = create(:project_group_invite, project_group: @group, sender: create(:user),
                                             recipient: @sender, kind: :direct_invite, status: :pending)

    ProjectGroupInvite.clear_pending_for!(@sender, @course)

    assert_not ProjectGroupInvite.exists?(sent.id)
    assert_not ProjectGroupInvite.exists?(received.id)
  end

  test 'clear_pending_for! leaves handled invites, other users and other courses alone' do
    accepted = create(:project_group_invite, project_group: @group, sender: @sender,
                                             recipient: create(:user), kind: :direct_request, status: :accepted)
    other_user = create(:project_group_invite, project_group: @group, sender: create(:user),
                                               recipient: create(:user), kind: :direct_request, status: :pending)
    other_course = create(:course, grouping_enabled: true, group_min: 2, group_max: 4)
    other_group = create(:project_group, course: other_course)
    other_course_invite = create(:project_group_invite, project_group: other_group, sender: @sender,
                                                        recipient: create(:user), kind: :direct_request,
                                                        status: :pending)

    ProjectGroupInvite.clear_pending_for!(@sender, @course)

    assert ProjectGroupInvite.exists?(accepted.id)
    assert ProjectGroupInvite.exists?(other_user.id)
    assert ProjectGroupInvite.exists?(other_course_invite.id)
  end

  test 'for_course scope returns invites scoped to course' do
    @invite.save!
    other_course = create(:course, grouping_enabled: true, group_min: 2, group_max: 4)
    other_group  = create(:project_group, course: other_course)
    other_invite = create(:project_group_invite, project_group: other_group, sender: create(:user))

    results = ProjectGroupInvite.for_course(@course)
    assert_includes results, @invite
    assert_not_includes results, other_invite
  end
end
