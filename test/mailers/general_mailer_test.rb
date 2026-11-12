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
end
