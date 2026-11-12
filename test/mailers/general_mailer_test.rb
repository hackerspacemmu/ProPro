require 'test_helper'

class GeneralMailerTest < ActionMailer::TestCase
  test 'a queued group mail is discarded when its invite record is deleted' do
    invite = create(:project_group_invite, kind: :direct_invite)
    GeneralMailer.with(invite: invite).Group_Direct_Invite_Notification.deliver_later
    invite.destroy

    perform_enqueued_jobs

    assert_empty ActionMailer::Base.deliveries
  end

  test 'the reopened notification names the joiner and the reopened group' do
    course = create(:course, group_formation_enabled: true)
    group = create(:project_group, course: course, group_name: 'Tmp001')
    joiner = create(:user, name: 'Ada Lovelace')
    recipient = create(:user)

    mail = GeneralMailer.with(group: group, joiner: joiner, recipient: recipient)
                        .Group_Reopened_Notification.deliver_now

    assert_equal [recipient.email_address], mail.to
    assert_includes mail.subject, 'Group reopened because Ada Lovelace joined'
    assert_includes mail.text_part.body.to_s, 'Group reopened because Ada Lovelace joined.'
    assert_includes mail.text_part.body.to_s, 'Tmp001'
    assert_includes mail.html_part.body.to_s, 'Group reopened because'
  end

  test 'the reopened notification can name the removed member' do
    course = create(:course, group_formation_enabled: true)
    group = create(:project_group, course: course, group_name: 'Tmp001')
    removed = create(:user, name: 'Ada Lovelace')
    recipient = create(:user)

    mail = GeneralMailer.with(group: group, removed_user: removed, recipient: recipient)
                        .Group_Reopened_Notification.deliver_now

    assert_equal [recipient.email_address], mail.to
    assert_includes mail.subject, 'Group reopened because Ada Lovelace was removed'
    assert_includes mail.text_part.body.to_s, 'Group reopened because Ada Lovelace was removed.'
    assert_includes mail.html_part.body.to_s, 'was removed'
  end

  test 'the direct request notification delivers with its subject' do
    leader = create(:user)
    group = create(:project_group, group_name: 'Alpha Group', leader_id: leader.id)
    invite = create(:project_group_invite, project_group: group, kind: :direct_request)

    mail = GeneralMailer.with(invite: invite).Group_Direct_Request_Notification.deliver_now

    assert_equal [leader.email_address], mail.to
    assert_equal 'New join request for Alpha Group', mail.subject
  end

  test 'the direct request accepted mail delivers with its subject' do
    group = create(:project_group, group_name: 'Alpha Group')
    invite = create(:project_group_invite, project_group: group, kind: :direct_request)

    mail = GeneralMailer.with(invite: invite).Group_Direct_Request_Accepted.deliver_now

    assert_equal [invite.sender.email_address], mail.to
    assert_equal 'Your request to join Alpha Group was accepted', mail.subject
  end

  test 'the direct request declined mail delivers with its subject' do
    group = create(:project_group, group_name: 'Alpha Group')
    invite = create(:project_group_invite, project_group: group, kind: :direct_request)

    mail = GeneralMailer.with(invite: invite).Group_Direct_Request_Declined.deliver_now

    assert_equal [invite.sender.email_address], mail.to
    assert_equal 'Your request to join Alpha Group was declined', mail.subject
  end

  test 'the direct invite notification delivers with its subject' do
    group = create(:project_group, group_name: 'Alpha Group')
    invite = create(:project_group_invite, project_group: group, kind: :direct_invite)

    mail = GeneralMailer.with(invite: invite).Group_Direct_Invite_Notification.deliver_now

    assert_equal [invite.recipient.email_address], mail.to
    assert_equal "You've been invited to join Alpha Group", mail.subject
  end

  test 'the direct invite accepted mail delivers with its subject' do
    group = create(:project_group, group_name: 'Alpha Group')
    invite = create(:project_group_invite, project_group: group, kind: :direct_invite)

    mail = GeneralMailer.with(invite: invite).Group_Direct_Invite_Accepted.deliver_now

    assert_equal [invite.sender.email_address], mail.to
    assert_equal "#{invite.recipient.name} accepted your invite to Alpha Group", mail.subject
  end

  test 'the direct invite declined mail delivers with its subject' do
    group = create(:project_group, group_name: 'Alpha Group')
    invite = create(:project_group_invite, project_group: group, kind: :direct_invite)

    mail = GeneralMailer.with(invite: invite).Group_Direct_Invite_Declined.deliver_now

    assert_equal [invite.sender.email_address], mail.to
    assert_equal "#{invite.recipient.name} declined your invite to Alpha Group", mail.subject
  end
end
