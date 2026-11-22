require 'test_helper'

class GroupResultMessagesTest < ActiveSupport::TestCase
  ENTRIES = [
    {
      service: 'GroupConfirmer',
      file: Rails.root.join('app/services/group_confirmer.rb').to_s,
      result_class: GroupConfirmer::Result,
      blocked_kwargs: { confirmed: false },
      reasons: {
        formation_closed: 'Group formation is closed.',
        already_confirmed: 'This group has already been confirmed.',
        size_illegal: 'This group cannot be confirmed at its current size.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Group confirmed.', -> { GroupConfirmer::Result.new(confirmed: true, blocked_reason: nil) }]
      ]
    },
    {
      service: 'GroupCreator',
      file: Rails.root.join('app/services/group_creator.rb').to_s,
      result_class: GroupCreator::Result,
      blocked_kwargs: { created: false, group: nil },
      reasons: {
        not_grouped: 'This course does not use groups.',
        formation_closed: 'Group formation is closed.',
        already_grouped: 'Already in a group for this course.'
      },
      rows: [
        ['Group Tmp001 created.',
         -> { GroupCreator::Result.new(created: true, group: Struct.new(:group_name).new('Tmp001'), blocked_reason: nil) }]
      ]
    },
    {
      service: 'GroupDirectInviter',
      file: Rails.root.join('app/services/group_direct_inviter.rb').to_s,
      result_class: GroupDirectInviter::Result,
      blocked_kwargs: { invited: false },
      reasons: {
        imported_group: 'This group was imported, so it cannot take new members.',
        has_project: 'This group already has a proposal, so it cannot take new members.',
        invalid_recipient: 'This user cannot be invited to a group.',
        formation_closed: 'Group formation is closed.',
        group_full: 'This group has reached its maximum size.',
        already_grouped: 'This student already joined another group.',
        already_invited: 'This student already has a pending invite for this group.'
      },
      rows: [
        ['Invite sent.', -> { GroupDirectInviter::Result.new(invited: true, blocked_reason: nil) }]
      ]
    },
    {
      service: 'GroupDirectRequester',
      file: Rails.root.join('app/services/group_direct_requester.rb').to_s,
      result_class: GroupDirectRequester::Result,
      blocked_kwargs: { requested: false },
      reasons: {
        imported_group: 'This group was imported, so you cannot request to join it.',
        has_project: 'This group already has a proposal, so it cannot take new members.',
        not_enrolled: 'You are not enrolled in this course.',
        formation_closed: 'Group formation is closed.',
        already_grouped: 'Already in a group for this course.',
        group_not_confirmed: 'Requests are for confirmed groups. Join this group instead.',
        already_requested: 'Already have a pending request for this group.',
        group_full: 'This group has reached its maximum size.',
        no_leader_assigned: "This group hasn't been assigned a leader yet.",
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Join request sent.', -> { GroupDirectRequester::Result.new(requested: true, blocked_reason: nil) }]
      ]
    },
    {
      service: 'GroupInviteLinkGenerator',
      file: Rails.root.join('app/services/group_invite_link_generator.rb').to_s,
      result_class: GroupInviteLinkGenerator::Result,
      blocked_kwargs: { generated: false, token: nil, expires_at: nil },
      reasons: {
        imported_group: 'This group was imported, so it cannot take new members.',
        has_project: 'This group already has a proposal, so it cannot take new members.',
        formation_closed: 'Group formation is closed.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Invite link generated.',
         -> { GroupInviteLinkGenerator::Result.new(generated: true, blocked_reason: nil, token: nil, expires_at: nil) }]
      ]
    },
    {
      service: 'GroupInviteLinkRedeemer',
      file: Rails.root.join('app/services/group_invite_link_redeemer.rb').to_s,
      result_class: GroupInviteLinkRedeemer::Result,
      blocked_kwargs: { redeemed: false, group: nil },
      reasons: {
        expired: 'This invite link has expired.',
        imported_group: 'This group was imported, so it cannot take new members.',
        not_enrolled: 'You are not enrolled in this course.',
        formation_closed: 'Group formation is closed.',
        has_project: 'This group already has a proposal, so it cannot take new members.',
        group_full: 'This group has reached its maximum size.',
        already_grouped: 'You are already in a group for this course.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ["You've joined Tmp001.",
         -> { GroupInviteLinkRedeemer::Result.new(redeemed: true, blocked_reason: nil, group: Struct.new(:group_name).new('Tmp001')) }]
      ]
    },
    {
      service: 'GroupInviteResponder',
      file: Rails.root.join('app/services/group_invite_responder.rb').to_s,
      result_class: GroupInviteResponder::Result,
      blocked_kwargs: { outcome: :blocked },
      reasons: {
        imported_group: 'This group was imported, so it cannot take new members.',
        not_enrolled: 'This student is no longer enrolled in this course.',
        formation_closed: 'Group formation is closed.',
        already_grouped: 'This student already joined another group.',
        has_project: 'This group already has a proposal, so it cannot take new members.',
        group_full: 'This group has reached its maximum size.',
        already_responded: 'This has already been responded to.',
        expired: 'This request has expired.',
        invite_gone: 'This request is no longer available.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Accepted. Member added to the group.',
         -> { GroupInviteResponder::Result.new(outcome: :accepted, blocked_reason: nil) }],
        ['Group reopened because Joiner joined.',
         -> { GroupInviteResponder::Result.new(outcome: :accepted, blocked_reason: nil, reopened: true, joining_user: Struct.new(:name).new('Joiner')) }],
        ['Declined.', -> { GroupInviteResponder::Result.new(outcome: :declined, blocked_reason: nil) }]
      ]
    },
    {
      service: 'GroupJoiner',
      file: Rails.root.join('app/services/group_joiner.rb').to_s,
      result_class: GroupJoiner::Result,
      blocked_kwargs: { joined: false },
      reasons: {
        imported_group: 'This group was imported, so it cannot take new members.',
        not_enrolled: 'You are not enrolled in this course.',
        formation_closed: 'Group formation is closed.',
        already_grouped: 'Already in a group for this course.',
        group_confirmed: 'Group already confirmed, not accepting members.',
        group_full: 'This group has reached its maximum size.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Joined the group.', -> { GroupJoiner::Result.new(joined: true, blocked_reason: nil) }]
      ]
    },
    {
      service: 'GroupMemberAdder',
      file: Rails.root.join('app/services/group_member_adder.rb').to_s,
      result_class: GroupMemberAdder::Result,
      blocked_kwargs: { added: false },
      reasons: {
        already_grouped: 'This student is already in a group for this course.',
        not_enrolled: 'This student is not enrolled in this course.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Student added to group.', -> { GroupMemberAdder::Result.new(added: true, blocked_reason: nil) }]
      ]
    },
    {
      service: 'GroupReverter',
      file: Rails.root.join('app/services/group_reverter.rb').to_s,
      result_class: GroupReverter::Result,
      blocked_kwargs: { reverted: false },
      reasons: {
        formation_closed: 'Group formation is closed.',
        already_draft: 'This group is already a Not Confirmed Group.',
        imported_group: 'This group was imported, so it cannot be reopened.',
        has_project: 'This group already has a proposal, so it cannot be reopened.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Group status changed to not confirmed.',
         -> { GroupReverter::Result.new(reverted: true, blocked_reason: nil) }]
      ]
    },
    {
      service: 'Groups::Deleter',
      file: Rails.root.join('app/services/groups/deleter.rb').to_s,
      result_class: Groups::Deleter::Result,
      blocked_kwargs: { deleted: false },
      reasons: {
        formation_closed: 'Group formation is closed.',
        has_project: 'This group has a proposal, so only a coordinator can delete it.',
        group_confirmed: 'A confirmed group can only be deleted by a coordinator.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Group deleted.', -> { Groups::Deleter::Result.new(deleted: true) }]
      ]
    },
    {
      service: 'Groups::InviteLinkDisabler',
      file: Rails.root.join('app/services/groups/invite_link_disabler.rb').to_s,
      result_class: Groups::InviteLinkDisabler::Result,
      blocked_kwargs: { disabled: false },
      reasons: {
        formation_closed: 'Group formation is closed.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Invite link disabled.', -> { Groups::InviteLinkDisabler::Result.new(disabled: true) }]
      ]
    },
    {
      service: 'Groups::Kicker',
      file: Rails.root.join('app/services/groups/kicker.rb').to_s,
      result_class: Groups::Kicker::Result,
      blocked_kwargs: { removed: false },
      reasons: {
        already_removed: 'This member has already been removed.',
        not_leader: 'Only the group leader can remove members.',
        self_kick: 'You cannot remove yourself from the group.',
        formation_closed: 'Group formation is closed.',
        imported_group: 'This group was imported, so it cannot be reopened.',
        has_project: 'This group already has a proposal, so it cannot take new members.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Member removed.', -> { Groups::Kicker::Result.new(removed: true) }],
        ['Group reopened because Removed Student was removed.',
         -> { Groups::Kicker::Result.new(removed: true, reopened: true, removed_user: Struct.new(:name).new('Removed Student')) }]
      ]
    },
    {
      service: 'Groups::Leaver',
      file: Rails.root.join('app/services/groups/leaver.rb').to_s,
      result_class: Groups::Leaver::Result,
      blocked_kwargs: { outcome: :blocked },
      reasons: {
        already_removed: 'This member has already been removed.',
        formation_closed: 'Group formation is closed.',
        group_confirmed: 'You cannot leave a confirmed group.',
        has_project: 'This group has a proposal, so only a coordinator can remove members.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['You have left the group.', -> { Groups::Leaver::Result.new(outcome: :removed) }],
        ['You left, and the group was deleted because it had no remaining members.',
         -> { Groups::Leaver::Result.new(outcome: :group_deleted) }]
      ]
    },
    {
      service: 'Groups::Coordinator::Confirmer',
      file: Rails.root.join('app/services/groups/coordinator/confirmer.rb').to_s,
      result_class: Groups::Coordinator::Confirmer::Result,
      blocked_kwargs: { confirmed: false },
      reasons: {
        already_confirmed: 'This group has already been confirmed.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['Tmp001 is now confirmed as G001.',
         -> { Groups::Coordinator::Confirmer::Result.new(confirmed: true, old_name: 'Tmp001', new_name: 'G001') }]
      ]
    },
    {
      service: 'Groups::Coordinator::EnrolmentRemover',
      file: Rails.root.join('app/services/groups/coordinator/enrolment_remover.rb').to_s,
      result_class: Groups::Coordinator::EnrolmentRemover::Result,
      blocked_kwargs: nil,
      reasons: {},
      rows: [
        ["Removing this student will permanently delete the project “Project X”. This can't be undone.",
         -> { Groups::Coordinator::EnrolmentRemover::Result.new(outcome: :needs_confirmation, project_title: 'Project X') }],
        ['Student removed from course.',
         -> { Groups::Coordinator::EnrolmentRemover::Result.new(outcome: :removed) }],
        ['Student removed from course. The group had no remaining members and was deleted.',
         -> { Groups::Coordinator::EnrolmentRemover::Result.new(outcome: :removed, group_deleted: true) }]
      ]
    },
    {
      service: 'Groups::Coordinator::GroupDeleter',
      file: Rails.root.join('app/services/groups/coordinator/group_deleter.rb').to_s,
      result_class: Groups::Coordinator::GroupDeleter::Result,
      blocked_kwargs: { deleted: false },
      reasons: {
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ["Deleting this group will permanently delete the project “Project X”. This can't be undone.",
         -> { Groups::Coordinator::GroupDeleter::Result.new(deleted: false, project_title: 'Project X') }],
        ['Group deleted.', -> { Groups::Coordinator::GroupDeleter::Result.new(deleted: true) }]
      ]
    },
    {
      service: 'Groups::Coordinator::Importer',
      file: Rails.root.join('app/services/groups/coordinator/importer.rb').to_s,
      result_class: Groups::Coordinator::Importer::Result,
      blocked_kwargs: nil,
      reasons: {},
      rows: [
        ["Carol was already in a group and wasn't moved.",
         -> { Groups::Coordinator::Importer::Result.new(blocked_reason: nil, skipped: [{ user: Struct.new(:name).new('Carol'), group_name: 'X' }]).skipped_messages.first }]
      ]
    },
    {
      service: 'Groups::Coordinator::MemberRemover',
      file: Rails.root.join('app/services/groups/coordinator/member_remover.rb').to_s,
      result_class: Groups::Coordinator::MemberRemover::Result,
      blocked_kwargs: { outcome: :blocked },
      reasons: {
        already_removed: 'This member has already been removed.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ["Removing this member will permanently delete the project “Project X”. This can't be undone.",
         -> { Groups::Coordinator::MemberRemover::Result.new(outcome: :needs_confirmation, project_title: 'Project X') }],
        ['Member removed.', -> { Groups::Coordinator::MemberRemover::Result.new(outcome: :removed) }],
        ['Member removed. The group had no remaining members and was deleted.',
         -> { Groups::Coordinator::MemberRemover::Result.new(outcome: :group_deleted) }]
      ]
    },
    {
      service: 'Groups::Coordinator::Reopener',
      file: Rails.root.join('app/services/groups/coordinator/reopener.rb').to_s,
      result_class: Groups::Coordinator::Reopener::Result,
      blocked_kwargs: { reopened: false },
      reasons: {
        already_not_confirmed: 'This group is already not confirmed.',
        imported_group: 'This group was imported, so it cannot be reopened.',
        has_project: 'This group already has a proposal, so it cannot be reopened.',
        group_gone: 'This group no longer exists.'
      },
      rows: [
        ['G001 is reopened as Tmp001.',
         -> { Groups::Coordinator::Reopener::Result.new(reopened: true, old_name: 'G001', new_name: 'Tmp001') }]
      ]
    }
  ].freeze

  test 'every blocked reason maps to its oracle message' do
    ENTRIES.each do |entry|
      entry[:reasons].each do |reason, expected|
        result = entry[:result_class].new(**entry[:blocked_kwargs], blocked_reason: reason)
        message = result.message

        assert_equal expected, message, "#{entry[:service]} :#{reason}"
        assert message.is_a?(String), "#{entry[:service]} :#{reason} must return a String"
        assert_not message.blank?, "#{entry[:service]} :#{reason} must not be blank"
      end
    end
  end

  test 'every success and variant result maps to its oracle message' do
    ENTRIES.each do |entry|
      entry[:rows].each do |expected, builder|
        value = builder.call
        message = value.respond_to?(:message) ? value.message : value

        assert_equal expected, message, entry[:service].to_s
        assert message.is_a?(String), "#{entry[:service]} must return a String"
        assert_not message.blank?, "#{entry[:service]} must not be blank"
      end
    end
  end

  test 'the table covers every blocked reason in the grouping services' do
    ENTRIES.each do |entry|
      reasons = File.read(entry[:file]).scan(/blocked\(:(\w+)\)/).flatten.map(&:to_sym).uniq

      reasons.each do |reason|
        assert entry[:reasons].key?(reason),
               "#{entry[:service]} is missing a message for :#{reason}"
      end
    end
  end

  test 'the table covers every grouping service result file' do
    files = (
      Dir[Rails.root.join('app/services/group*.rb').to_s] +
      Dir[Rails.root.join('app/services/groups/**/*.rb').to_s]
    ).reject { |file| file.end_with?('group_locking.rb') }

    assert_equal files.sort, ENTRIES.map { |entry| entry[:file] }.sort
  end

  test 'calculator errors keep their oracle messages' do
    {
      group_size_limits_not_configured: 'Group size limits are not set for this course.',
      no_students_to_group: 'Enter a student count greater than 0.',
      no_legal_combination_exists: 'No legal group size combination exists for this number of students.'
    }.each do |error, expected|
      result = Queries::GroupSizeConfirmabilityCalculator::Result.new(
        found: false, breakdown: [], group_count: 0, error: error
      )

      assert_equal expected, result.message
    end
  end
end
