require 'test_helper'

class GeneralMailerTest < ActionMailer::TestCase
  test 'a queued group mail is discarded when its invite record is deleted' do
    invite = create(:project_group_invite, kind: :direct_invite)
    GeneralMailer.with(invite: invite).Group_Direct_Invite_Notification.deliver_later
    invite.destroy

    perform_enqueued_jobs

    assert_empty ActionMailer::Base.deliveries
  end
end
