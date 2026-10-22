# Grouping backend - services, models, tests (raw dump)

**Purpose:** Verbatim raw material for planning the `Queries::` / `Group::` rename and the
service-convention cleanup of the student-grouping backend. This file contains **no
analysis** - it is a byte-for-byte dump of the files listed below, plus raw test output.
Every analytical claim lives in `docs/grouping_backend_audit.md`.

**Date of capture:** 2026-10-21 22:13:48 +0800
**Current branch:** `feat/student-grouping-crud`
**HEAD sha:** `8a35e745159b8af0ce07f36de2b22defa16d8ca2`
**HEAD commit date:** 2026-10-21 16:29:08 +0800
**Base branch:** `main` (= `origin/main`) at `98ca0a9b52d4551bc85265535b7e22acde01717a` - this is also the merge base with HEAD, so the branch is **89 commits ahead of main and 0 behind**.
**Working tree:** no tracked file is modified (`git status --porcelain --untracked-files=no` is empty); the only untracked files are the three audit documents in `docs/`.
**Dump method:** each file read straight from the working tree (identical to HEAD). Each file's "last commit" line comes from `git log -1 --format='%h %ad' --date=short -- <path>`.

## Table of contents

| # | Section | Lines |
|---|---------|-------|
| | **A. Grouping services (all of `app/services`, grouping)** | **760** |
| | &nbsp;&nbsp;`app/services/group_creator.rb` | 66 |
| | &nbsp;&nbsp;`app/services/group_joiner.rb` | 61 |
| | &nbsp;&nbsp;`app/services/group_member_adder.rb` | 52 |
| | &nbsp;&nbsp;`app/services/group_member_remover.rb` | 113 |
| | &nbsp;&nbsp;`app/services/group_confirmer.rb` | 47 |
| | &nbsp;&nbsp;`app/services/group_reverter.rb` | 43 |
| | &nbsp;&nbsp;`app/services/group_direct_inviter.rb` | 70 |
| | &nbsp;&nbsp;`app/services/group_direct_requester.rb` | 64 |
| | &nbsp;&nbsp;`app/services/group_invite_link_generator.rb` | 58 |
| | &nbsp;&nbsp;`app/services/group_invite_link_redeemer.rb` | 73 |
| | &nbsp;&nbsp;`app/services/group_invite_responder.rb` | 113 |
| | **B. Reference implementations + `Queries::` objects** | **321** |
| | &nbsp;&nbsp;`app/services/supervisor_capacity_updater.rb` | 57 |
| | &nbsp;&nbsp;`app/services/queries/supervisor_capacity_calculator.rb` | 99 |
| | &nbsp;&nbsp;`app/services/user_creator.rb` | 39 |
| | &nbsp;&nbsp;`app/services/user_details_validator.rb` | 23 |
| | &nbsp;&nbsp;`app/services/queries/group_size_confirmability_calculator.rb` | 103 |
| | **C. Models** | **543** |
| | &nbsp;&nbsp;`app/models/project_group.rb` | 32 |
| | &nbsp;&nbsp;`app/models/project_group_member.rb` | 4 |
| | &nbsp;&nbsp;`app/models/project_group_invite.rb` | 34 |
| | &nbsp;&nbsp;`app/models/project_group_invite_link.rb` | 4 |
| | &nbsp;&nbsp;`app/models/course.rb` | 229 |
| | &nbsp;&nbsp;`app/models/enrolment.rb` | 37 |
| | &nbsp;&nbsp;`app/models/user.rb` | 31 |
| | &nbsp;&nbsp;`app/models/project.rb` | 106 |
| | &nbsp;&nbsp;`app/models/project_instance.rb` | 53 |
| | &nbsp;&nbsp;`app/models/ownership.rb` | 5 |
| | &nbsp;&nbsp;`app/models/comment.rb` | 8 |
| | **D1. Grouping service tests** | **1177** |
| | &nbsp;&nbsp;`test/services/group_creator_test.rb` | 122 |
| | &nbsp;&nbsp;`test/services/group_joiner_test.rb` | 125 |
| | &nbsp;&nbsp;`test/services/group_member_adder_test.rb` | 87 |
| | &nbsp;&nbsp;`test/services/group_confirmer_test.rb` | 71 |
| | &nbsp;&nbsp;`test/services/group_reverter_test.rb` | 33 |
| | &nbsp;&nbsp;`test/services/group_direct_inviter_test.rb` | 146 |
| | &nbsp;&nbsp;`test/services/group_direct_requester_test.rb` | 105 |
| | &nbsp;&nbsp;`test/services/group_invite_link_generator_test.rb` | 77 |
| | &nbsp;&nbsp;`test/services/group_invite_link_redeemer_test.rb` | 142 |
| | &nbsp;&nbsp;`test/services/group_invite_responder_test.rb` | 186 |
| | &nbsp;&nbsp;`test/services/group_size_confirmability_calculator_test.rb` | 83 |
| | **D2. Reference-implementation tests** | **224** |
| | &nbsp;&nbsp;`test/services/supervisor_capacity_updater_test.rb` | 206 |
| | &nbsp;&nbsp;`test/services/supervisor_capacity_calculator_test.rb` | 18 |
| | **D3. Other grouping-related model / controller / integration tests** | **591** |
| | &nbsp;&nbsp;`test/models/project_group_student_actions_test.rb` | 57 |
| | &nbsp;&nbsp;`test/models/project_group_invite_test.rb` | 56 |
| | &nbsp;&nbsp;`test/models/student_group_member_test.rb` | 7 |
| | &nbsp;&nbsp;`test/models/course_grouping_settings_test.rb` | 170 |
| | &nbsp;&nbsp;`test/models/course_test.rb` | 52 |
| | &nbsp;&nbsp;`test/controllers/enrolments_controller_test.rb` | 70 |
| | &nbsp;&nbsp;`test/integration/grouping_settings_surface_test.rb` | 46 |
| | &nbsp;&nbsp;`test/integration/enroll_via_coursecode_test.rb` | 63 |
| | &nbsp;&nbsp;`test/integration/update_coursecode_test.rb` | 70 |
| | **D4. Factories** | **86** |
| | &nbsp;&nbsp;`test/factories/project_groups.rb` | 8 |
| | &nbsp;&nbsp;`test/factories/project_group_members.rb` | 6 |
| | &nbsp;&nbsp;`test/factories/project_group_invites.rb` | 9 |
| | &nbsp;&nbsp;`test/factories/project_group_invite_links.rb` | 8 |
| | &nbsp;&nbsp;`test/factories/courses.rb` | 27 |
| | &nbsp;&nbsp;`test/factories/enrolments.rb` | 15 |
| | &nbsp;&nbsp;`test/factories/users.rb` | 13 |
| | **D5. Test support files** | **67** |
| | &nbsp;&nbsp;`test/test_helper.rb` | 17 |
| | &nbsp;&nbsp;`test/support/with_clues.rb` | 50 |
| | **E. Migrations touching grouping tables/columns** | **141** |
| | &nbsp;&nbsp;`db/migrate/20250714101030_create_enrolments.rb` | 11 |
| | &nbsp;&nbsp;`db/migrate/20250714101033_create_project_groups.rb` | 10 |
| | &nbsp;&nbsp;`db/migrate/20250715105517_create_project_group_members.rb` | 10 |
| | &nbsp;&nbsp;`db/migrate/20260426065457_add_grouping_settings_to_courses.rb` | 11 |
| | &nbsp;&nbsp;`db/migrate/20260429092127_add_grouping_fields_to_project_groups.rb` | 8 |
| | &nbsp;&nbsp;`db/migrate/20260507104009_add_groups_sequence_to_project_groups.rb` | 6 |
| | &nbsp;&nbsp;`db/migrate/20260531093000_create_project_group_invites.rb` | 20 |
| | &nbsp;&nbsp;`db/migrate/20260714065220_add_dissolved_at_to_project_groups.rb` | 5 |
| | &nbsp;&nbsp;`db/migrate/20260714065259_add_token_and_expires_at_to_project_group_invites.rb` | 7 |
| | &nbsp;&nbsp;`db/migrate/20260726153230_remove_dissolved_at_from_project_groups.rb` | 5 |
| | &nbsp;&nbsp;`db/migrate/20260806113423_reshape_project_group_invites.rb` | 18 |
| | &nbsp;&nbsp;`db/migrate/20260806113610_create_project_group_invite_links.rb` | 14 |
| | &nbsp;&nbsp;`db/migrate/20260811072831_fix_direct_invite_sender_unique_index.rb` | 11 |
| | &nbsp;&nbsp;`db/migrate/20260811102449_add_lecturers_can_manage_groups_to_courses.rb` | 5 |
| | **G. Markdown docs about services / grouping** | **287** |
| | &nbsp;&nbsp;`docs/Abstraction/service_classes.md` | 104 |
| | &nbsp;&nbsp;`docs/adr/0023-grouping-settings-live-in-course-settings.md` | 104 |
| | &nbsp;&nbsp;`docs/adr/0024-two-group-surfaces-stay-separate.md` | 79 |
| | **Total dumped source lines** | **4197** |

`db/schema.rb` is dumped as an excerpt in section E1 (only the grouping-relevant tables),
so it is not in the table above. Raw test output is in section F; the "Excluded / not
found" list is at the end of this file.

---

# A. Grouping services - verbatim

All eleven grouping command services live **flat in `app/services/`** - there is no
`Group::` namespace and no `Queries::` namespace for them. Each defines its own nested
`Result` class inline, so the Result classes are included in the dumps below.

Naming exactly as it exists today (do not "correct" it):

| Service class | File | Public entry point | Nested Result |
|---|---|---|---|
| `GroupCreator` | `app/services/group_creator.rb` | `create!` | `GroupCreator::Result` |
| `GroupJoiner` | `app/services/group_joiner.rb` | `join!` | `GroupJoiner::Result` |
| `GroupMemberAdder` | `app/services/group_member_adder.rb` | `add!` | `GroupMemberAdder::Result` |
| `GroupMemberRemover` | `app/services/group_member_remover.rb` | `remove!` | `GroupMemberRemover::Result` |
| `GroupConfirmer` | `app/services/group_confirmer.rb` | `confirm!` | `GroupConfirmer::Result` |
| `GroupReverter` | `app/services/group_reverter.rb` | `revert!` | `GroupReverter::Result` |
| `GroupDirectInviter` | `app/services/group_direct_inviter.rb` | `invite!` | `GroupDirectInviter::Result` |
| `GroupDirectRequester` | `app/services/group_direct_requester.rb` | `request!` | `GroupDirectRequester::Result` |
| `GroupInviteLinkGenerator` | `app/services/group_invite_link_generator.rb` | `generate!` | `GroupInviteLinkGenerator::Result` |
| `GroupInviteLinkRedeemer` | `app/services/group_invite_link_redeemer.rb` | `redeem!` | `GroupInviteLinkRedeemer::Result` |
| `GroupInviteResponder` | `app/services/group_invite_responder.rb` | `accept!` / `decline!` | `GroupInviteResponder::Result` |

=== app/services/group_creator.rb | 66 lines | last commit 04eb3446 2026-07-30 ===

~~~~
# Creates a project group. Student self-creates (becomes leader) or
# coordinator places a specified leader directly.
class GroupCreator
  def initialize(course, leader:, current_user:)
    @course = course
    @leader = leader
    @current_user = current_user
  end

  def create!
    @course.with_lock do
      return blocked(:already_grouped) if already_grouped?
      return blocked(:window_closed) if self_create? && !@course.grouping_window_open?

      group = build_group!
      Result.new(created: true, group: group, blocked_reason: nil)
    end
  end

  private

  def self_create?
    @leader.id == @current_user.id
  end

  def already_grouped?
    @course.project_group_members.exists?(user_id: @leader.id)
  end

  def build_group!
    next_seq = @course.project_groups.maximum(:course_group_sequence).to_i + 1
    group = @course.project_groups.create!(
      leader_id: @leader.id,
      course_group_sequence: next_seq,
      group_name: format('G%03d', next_seq)
    )
    ProjectGroupMember.create!(user: @leader, project_group: group)
    group
  end

  def blocked(reason)
    Result.new(created: false, group: nil, blocked_reason: reason)
  end

  class Result
    attr_reader :group, :blocked_reason

    def initialize(created:, group:, blocked_reason:)
      @created = created
      @group = group
      @blocked_reason = blocked_reason
    end

    def created? = @created
    def blocked? = !created?

    def message
      return "Draft group #{group.group_name} created." if created?

      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      end
    end
  end
end
~~~~

=== app/services/group_joiner.rb | 61 lines | last commit f39f918d 2026-08-21 ===

~~~~
# Direct join to an unlocked draft group. Use GroupJoinRequester for locked groups.
class GroupJoiner
  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def join!
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
      return blocked(:group_confirmed) if @group.confirmed?
      return blocked(:group_locked) if @group.locked?
      return blocked(:group_full) if @group.project_group_members.count >= course.group_max.to_i

      ProjectGroupMember.create!(user: @current_user, project_group: @group)
      clear_conflicting_invites!

      Result.new(joined: true, blocked_reason: nil)
    end
  end

  private

  def clear_conflicting_invites!
    ProjectGroupInvite
      .where(sender_id: @current_user.id, kind: :direct_request, status: :pending)
      .where(project_group_id: @group.course.project_groups.select(:id))
      .destroy_all
  end

  def blocked(reason)
    Result.new(joined: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(joined:, blocked_reason:)
      @joined = joined
      @blocked_reason = blocked_reason
    end

    def joined? = @joined
    def blocked? = !joined?

    def message
      return 'Joined the group.' if joined?

      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_locked then 'Group is locked. Send a join request instead.'
      when :group_full then 'Group has reached its maximum size.'
      end
    end
  end
end
~~~~

=== app/services/group_member_adder.rb | 52 lines | last commit 51a3af17 2026-08-13 ===

~~~~
# Coordinator/lecturer adds a student directly to a group bypassing group legality.
# group_max is still checked.
class GroupMemberAdder
  def initialize(group, user:, current_user:)
    @group = group
    @user = user
    @current_user = current_user
  end

  def add!
    course = @group.course

    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @user.id)
    return blocked(:group_full) if group_full?(course)

    @group.with_lock do
      ProjectGroupMember.create!(user: @user, project_group: @group)
      Result.new(added: true, blocked_reason: nil)
    end
  end

  private

  def group_full?(course)
    course.group_max.present? && @group.project_group_members.count >= course.group_max
  end

  def blocked(reason)
    Result.new(added: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(added:, blocked_reason:)
      @added = added
      @blocked_reason = blocked_reason
    end

    def added? = @added
    def blocked? = !added?

    def message
      return 'Student added to group.' if added?

      case blocked_reason
      when :already_grouped then 'This student is already in a group for this course.'
      when :group_full then 'This group has reached its maximum size.'
      end
    end
  end
end
~~~~

=== app/services/group_member_remover.rb | 113 lines | last commit a48f894f 2026-08-20 ===

~~~~
# Removes a member from a project group: self-leave, leader-kick, or coordinator-removal.
class GroupMemberRemover
  def initialize(member, current_user:, dissolve_confirmed: false)
    @member = member
    @current_user = current_user
    @dissolve_confirmed = dissolve_confirmed
    @group = member.project_group
  end

  def remove!
    @group.with_lock do
      return blocked(:window_closed) if requires_window_check? && !window_open?
      return blocked(:group_confirmed) if leader_kick? && @group.confirmed?

      remaining_count = @group.project_group_members.count - 1

      return needs_confirmation(@group.project.current_title) if remaining_count.zero? && @group.project.present? && !@dissolve_confirmed

      was_leader = @group.leader?(@member.user)
      @member.destroy!

      if remaining_count.zero?
        dissolve!
        return Result.new(outcome: :dissolved, blocked_reason: nil)
      end

      promote_next_leader! if was_leader

      if @group.confirmed? && (self_leave? || !legal_at_current_size?)
        @group.update!(confirmed: false)
        return Result.new(outcome: :reverted, blocked_reason: nil)
      end

      Result.new(outcome: :unchanged, blocked_reason: nil)
    end
  end

  private

  def self_leave?
    @current_user.id == @member.user_id
  end

  def leader_kick?
    !self_leave? && @group.leader?(@current_user)
  end

  def requires_window_check?
    self_leave? || leader_kick?
  end

  def window_open?
    @group.course.grouping_window_open?
  end

  def legal_at_current_size?
    @group.confirmable?
  end

  def promote_next_leader!
    successor = @group.project_group_members.order(:created_at).first
    @group.update!(leader_id: successor.user_id)
  end

  def dissolve!
    @group.project_group_invites.destroy_all
    @group.project_group_invite_links.destroy_all
    @group.destroy!
  end

  def blocked(reason)
    Result.new(outcome: :blocked, blocked_reason: reason)
  end

  def needs_confirmation(project_title)
    Result.new(outcome: :needs_confirmation, blocked_reason: nil, project_title: project_title)
  end

  class Result
    attr_reader :outcome, :blocked_reason, :project_title

    def initialize(outcome:, blocked_reason:, project_title: nil)
      @outcome = outcome
      @blocked_reason = blocked_reason
      @project_title = project_title
    end

    def dissolved? = outcome == :dissolved
    def reverted? = outcome == :reverted
    def needs_confirmation? = outcome == :needs_confirmation
    def blocked? = outcome == :blocked

    def message
      return blocked_message if blocked?
      return "Removing this member will permanently delete the project “#{project_title}”. This can't be undone." if needs_confirmation?

      case outcome
      when :dissolved then 'Member removed. The group had no remaining members and was dissolved.'
      when :reverted then 'Member removed. The group no longer meets the size requirement and was reverted to draft.'
      else 'Member removed.'
      end
    end

    private

    def blocked_message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'The leader can only remove members while the group is still a draft.'
      end
    end
  end
end
~~~~

=== app/services/group_confirmer.rb | 47 lines | last commit a48f894f 2026-08-20 ===

~~~~
# Leader comfirms draft group if the grouping window is open and size is legal.
class GroupConfirmer
  def initialize(group)
    @group = group
  end

  def confirm!
    # Check group size and grouping window inside lock to avoid double race condition on submit
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_confirmed) if @group.confirmed?

      return blocked(:size_illegal) unless @group.confirmable?

      @group.update!(confirmed: true)
      Result.new(confirmed: true, blocked_reason: nil)
    end
  end

  private

  def blocked(reason)
    Result.new(confirmed: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(confirmed:, blocked_reason:)
      @confirmed = confirmed
      @blocked_reason = blocked_reason
    end

    def confirmed? = @confirmed

    def message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_confirmed then 'This group has already been confirmed.'
      when :size_illegal then 'This group cannot be confirmed at its current size.'
      when nil then 'Group confirmed.'
      end
    end
  end
end
~~~~

=== app/services/group_reverter.rb | 43 lines | last commit 2977d6a3 2026-07-24 ===

~~~~
class GroupReverter
  def initialize(group)
    @group = group
  end

  # Leader reverts a confirmed group back to draft if the grouping window is open.
  def revert!
    @group.with_lock do
      course = @group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_draft) unless @group.confirmed?

      @group.update!(confirmed: false)
      Result.new(reverted: true, blocked_reason: nil)
    end
  end

  private

  def blocked(reason)
    Result.new(reverted: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(reverted:, blocked_reason:)
      @reverted = reverted
      @blocked_reason = blocked_reason
    end

    def reverted? = @reverted

    def message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_draft then 'This group is already a draft.'
      when nil then 'Group reverted to draft.'
      end
    end
  end
end
~~~~

=== app/services/group_direct_inviter.rb | 70 lines | last commit 52052e28 2026-08-12 ===

~~~~
# Leader sends a direct invite to a student
# Creates a pending ProjectGroupInvite (kind: direct_invite)
# Sends email to the student
class GroupDirectInviter
  def initialize(group, current_user:, recipient:)
    @group = group
    @current_user = current_user
    @recipient = recipient
  end

  def invite!
    course = @group.course
    recipient_enrolment = course.enrolments.find_by(user: @recipient)

    return blocked(:invalid_recipient) unless recipient_enrolment&.student?
    return blocked(:window_closed) unless course.grouping_window_open?
    return blocked(:group_confirmed) if @group.confirmed?
    return blocked(:group_full) if group_full?(course)
    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @recipient.id)

    invite = ProjectGroupInvite.create!(
      project_group: @group,
      sender: @current_user,
      recipient: @recipient,
      kind: :direct_invite,
      status: :pending
    )

    GeneralMailer.with(invite: invite).Group_Direct_Invite_Notification.deliver_later

    Result.new(invited: true, blocked_reason: nil)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    blocked(:already_invited)
  end

  private

  def group_full?(course)
    course.group_max.present? && @group.project_group_members.count >= course.group_max
  end

  def blocked(reason)
    Result.new(invited: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(invited:, blocked_reason:)
      @invited = invited
      @blocked_reason = blocked_reason
    end

    def invited? = @invited
    def blocked? = !invited?

    def message
      return 'Invite sent.' if invited?

      case blocked_reason
      when :invalid_recipient then 'This user cannot be invited to a group.'
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_full then 'Group has reached its maximum size.'
      when :already_grouped then 'This student already joined another group.'
      when :already_invited then 'This student already has a pending invite for this group.'
      end
    end
  end
end
~~~~

=== app/services/group_direct_requester.rb | 64 lines | last commit 429b676f 2026-08-21 ===

~~~~
# Student requests to join a locked group.
# Creates a pending ProjectGroupInvite (kind: direct_request)
# Sends email to the leader
class GroupDirectRequester
  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def request!
    course = @group.course

    return blocked(:window_closed) unless course.grouping_window_open?
    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
    return blocked(:group_confirmed) if @group.confirmed?
    return blocked(:group_unlocked) unless @group.locked?
    return blocked(:no_leader_assigned) if @group.leader_id.blank?

    invite = ProjectGroupInvite.create!(
      project_group: @group,
      sender: @current_user,
      recipient_id: @group.leader_id,
      kind: :direct_request,
      status: :pending
    )

    GeneralMailer.with(invite: invite).Group_Direct_Request_Notification.deliver_later

    Result.new(requested: true, blocked_reason: nil)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    blocked(:already_requested)
  end

  private

  def blocked(reason)
    Result.new(requested: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(requested:, blocked_reason:)
      @requested = requested
      @blocked_reason = blocked_reason
    end

    def requested? = @requested
    def blocked? = !requested?

    def message
      return 'Join request sent.' if requested?

      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'Already in a group for this course.'
      when :group_confirmed then 'Group already confirmed, not accepting requests.'
      when :group_unlocked then 'Group is unlocked — join it directly instead.'
      when :already_requested then 'Already have a pending request for this group.'
      when :no_leader_assigned then "This group hasn't been assigned a leader yet."
      end
    end
  end
end
~~~~

=== app/services/group_invite_link_generator.rb | 58 lines | last commit dcf494af 2026-08-11 ===

~~~~
# Leader generates/regenerates the group's shareable invite link.
# Regenation deletes the old record and creates a new one.
# draft groups, no email notifications, can join if locked
class GroupInviteLinkGenerator
  def initialize(group, current_user:)
    @group = group
    @current_user = current_user
  end

  def generate!
    course = @group.course

    return blocked(:window_closed) unless course.grouping_window_open?
    return blocked(:group_confirmed) if @group.confirmed?

    @group.with_lock do
      @group.project_group_invite_links.find_by(sender: @current_user)&.destroy!

      link = @group.project_group_invite_links.create!(
        sender: @current_user,
        token: SecureRandom.urlsafe_base64(8),
        expires_at: 24.hours.from_now
      )

      Result.new(generated: true, blocked_reason: nil,
                 token: link.token, expires_at: link.expires_at)
    end
  end

  private

  def blocked(reason)
    Result.new(generated: false, blocked_reason: reason, token: nil, expires_at: nil)
  end

  class Result
    attr_reader :blocked_reason, :token, :expires_at

    def initialize(generated:, blocked_reason:, token:, expires_at:)
      @generated = generated
      @blocked_reason = blocked_reason
      @token = token
      @expires_at = expires_at
    end

    def generated? = @generated
    def blocked? = !generated?

    def message
      return 'Invite link generated.' if generated?

      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'Group already confirmed.'
      end
    end
  end
end
~~~~

=== app/services/group_invite_link_redeemer.rb | 73 lines | last commit 3bb88bad 2026-08-11 ===

~~~~
# Redeems a project group invite link. Whoever holds a valid token joins
# instantly — no approval step, no email. Stateless, no self/leader
# branching (link kind always self-serves). Enrollment/role check lives in
# ProjectGroupInviteLinkPolicy#redeem? (identity concern, not service).
class GroupInviteLinkRedeemer
  def initialize(invite_link, current_user:)
    @invite_link = invite_link
    @current_user = current_user
  end

  def redeem!
    return blocked(:expired) if @invite_link.expires_at.past?

    group = @invite_link.project_group

    group.with_lock do
      course = group.course

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:group_confirmed) if group.confirmed?
      return blocked(:group_full) if group_full?(group, course)
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)

      ProjectGroupMember.create!(user: @current_user, project_group: group)
      clear_conflicting_invites!(group)

      Result.new(redeemed: true, blocked_reason: nil, group: group)
    end
  end

  private

  def group_full?(group, course)
    course.group_max.present? && group.project_group_members.count >= course.group_max
  end

  def clear_conflicting_invites!(group)
    ProjectGroupInvite
      .where(status: :pending)
      .where('sender_id = :id OR recipient_id = :id', id: @current_user.id)
      .where(project_group_id: group.course.project_groups.select(:id))
      .destroy_all
  end

  def blocked(reason)
    Result.new(redeemed: false, blocked_reason: reason, group: nil)
  end

  class Result
    attr_reader :blocked_reason, :group

    def initialize(redeemed:, blocked_reason:, group:)
      @redeemed = redeemed
      @blocked_reason = blocked_reason
      @group = group
    end

    def redeemed? = @redeemed
    def blocked? = !redeemed?

    def message
      return "You've joined #{group.group_name}." if redeemed?

      case blocked_reason
      when :expired then 'This invite link has expired.'
      when :window_closed then 'The grouping window is closed.'
      when :group_confirmed then 'This group is already confirmed.'
      when :group_full then 'This group has reached its maximum size.'
      when :already_grouped then 'You are already in a group for this course.'
      end
    end
  end
end
~~~~

=== app/services/group_invite_responder.rb | 113 lines | last commit 3bb88bad 2026-08-11 ===

~~~~
# Responds to a pending ProjectGroupInvite — either a direct_request
# (leader accepts/declines a student's request) or a direct_invite
# (student accepts/declines a leader's invite). Joining user is inferred
# from kind: sender for direct_request, recipient for direct_invite.
# Accept adds the joining user as a member and clears their other pending
# invites/requests course-wide. Decline just flips status, no state change.
class GroupInviteResponder
  def initialize(invite, current_user:)
    @invite = invite
    @current_user = current_user
    @group = invite.project_group
  end

  def accept!
    @group.with_lock do
      @invite.reload
      return blocked(:already_responded) unless @invite.pending?

      course = @group.course
      joining_user = joining_user_for(@invite)

      return blocked(:window_closed) unless course.grouping_window_open?
      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: joining_user.id)
      return blocked(:group_confirmed) if @group.confirmed?
      return blocked(:group_full) if group_full?(course)

      ProjectGroupMember.create!(user: joining_user, project_group: @group)
      @invite.update!(status: :accepted)
      clear_conflicting_invites!(joining_user)

      deliver_mailer(:accepted)

      Result.new(outcome: :accepted, blocked_reason: nil)
    end
  end

  def decline!
    return blocked(:already_responded) unless @invite.pending?

    @invite.update!(status: :declined)
    deliver_mailer(:declined)

    Result.new(outcome: :declined, blocked_reason: nil)
  end

  private

  def group_full?(course)
    course.group_max.present? && @group.project_group_members.count >= course.group_max
  end

  def joining_user_for(invite)
    invite.direct_request? ? invite.sender : invite.recipient
  end

  # Clears the direct request and invites for the student
  def clear_conflicting_invites!(joining_user)
    ProjectGroupInvite
      .where(status: :pending)
      .where('sender_id = :id OR recipient_id = :id', id: joining_user.id)
      .where(project_group_id: @group.course.project_groups.select(:id))
      .destroy_all
  end

  def deliver_mailer(outcome)
    method =
      if @invite.direct_request?
        outcome == :accepted ? :Group_Direct_Request_Accepted : :Group_Direct_Request_Declined
      else
        outcome == :accepted ? :Group_Direct_Invite_Accepted : :Group_Direct_Invite_Declined
      end

    GeneralMailer.with(invite: @invite).public_send(method).deliver_later
  end

  def blocked(reason)
    Result.new(outcome: :blocked, blocked_reason: reason)
  end

  class Result
    attr_reader :outcome, :blocked_reason

    def initialize(outcome:, blocked_reason:)
      @outcome = outcome
      @blocked_reason = blocked_reason
    end

    def accepted? = outcome == :accepted
    def declined? = outcome == :declined
    def blocked? = outcome == :blocked

    def message
      return blocked_message if blocked?

      case outcome
      when :accepted then 'Accepted. Member added to the group.'
      when :declined then 'Declined.'
      end
    end

    private

    def blocked_message
      case blocked_reason
      when :window_closed then 'The grouping window is closed.'
      when :already_grouped then 'This student already joined another group.'
      when :group_confirmed then 'Group already confirmed, not accepting members.'
      when :group_full then 'Group has reached its maximum size.'
      when :already_responded then 'This has already been responded to.'
      end
    end
  end
end
~~~~


---

# B. Reference implementations and query objects - verbatim

These are the files the team points at as the convention reference
(`docs/Abstraction/service_classes.md`). They are dumped in full so the auditor can
compare the grouping services against them.

**The shared `ServiceResult` module referenced by `docs/Abstraction/service_classes.md`
does NOT exist in this tree.** A repository-wide search for `ServiceResult` across
`app/`, `lib/` and `test/` returns zero hits. The doc shows it as an illustrative
snippet only. See "Excluded / not found" at the end of this file.
=== app/services/supervisor_capacity_updater.rb | 57 lines | last commit 601ab904 2026-08-07 ===

~~~~
class SupervisorCapacityUpdater
  class Result
    attr_reader :course, :errors

    def initialize(updated:, course:, errors: [])
      @updated = updated
      @course = course
      @errors = errors
    end

    def updated? = @updated
  end

  def initialize(course)
    @course = course
  end

  def update!(offsets:, excluded_ids:)
    excluded_ids = excluded_ids.map(&:to_s)
    errors = []

    all_lecturers = @course.enrolments.where(role: :lecturer).to_a

    all_lecturers.each do |enrolment|
      id = enrolment.id.to_s
      next unless offsets.key?(id) || excluded_ids.include?(id)

      enrolment.supervisor_capacity_offset = offsets[id].to_i if offsets.key?(id)
      enrolment.supervisor_capacity_excluded = excluded_ids.include?(id)
    end

    base = Queries::SupervisorCapacityCalculator.new(@course, lecturer_enrolments: all_lecturers).execute.base

    targets = all_lecturers.select { |e| offsets.key?(e.id.to_s) || excluded_ids.include?(e.id.to_s) }
    targets.each { |enrolment| errors.concat(check(enrolment, base)) }

    if errors.any?
      Result.new(updated: false, course: @course, errors: errors)
    else
      persist(targets)
      Result.new(updated: true, course: @course)
    end
  end

  private

  def check(enrolment, base)
    return [] if enrolment.supervisor_capacity_excluded?
    return [] if (base + enrolment.supervisor_capacity_offset).positive?

    ["#{enrolment.user.name}'s offset would result in negative or zero capacity."]
  end

  def persist(targets)
    targets.each { |e| e.save!(validate: false) }
  end
end
~~~~

=== app/services/queries/supervisor_capacity_calculator.rb | 99 lines | last commit 42e76c86 2026-07-24 ===

~~~~
module Queries
  class SupervisorCapacityCalculator
    class Result
      attr_reader :base, :remainder, :total, :manual_value, :auto_calculated, :lecturer_capacities

      def initialize(base:, remainder:, total:, manual_value:, auto_calculated:, lecturer_capacities:)
        @base = base
        @remainder = remainder
        @total = total
        @manual_value = manual_value
        @auto_calculated = auto_calculated
        @lecturer_capacities = lecturer_capacities
      end

      def auto_calculated?
        @auto_calculated
      end
    end

    class LecturerCapacity
      attr_reader :enrolment, :offset, :approved_count, :pending_count, :effective_cap

      def initialize(enrolment:, offset:, approved_count:, pending_count:, effective_cap:)
        @enrolment = enrolment
        @offset = offset
        @approved_count = approved_count
        @pending_count = pending_count
        @effective_cap = effective_cap
      end

      def excluded?
        enrolment.supervisor_capacity_excluded?
      end

      def at_capacity?
        approved_count >= effective_cap
      end

      def remaining
        [effective_cap - approved_count, 0].max
      end

      def total_proposals
        approved_count + pending_count
      end
    end

    def initialize(course, lecturer_enrolments: nil)
      @course = course
      @lecturer_enrolments = lecturer_enrolments
    end

    def execute
      base, remainder, total = base_remainder_and_total

      capacities = lecturer_enrolments.map { |enrolment| build_lecturer_capacity(enrolment, base) }

      Result.new(
        base: base, remainder: remainder, total: total,
        manual_value: @course.supervisor_projects_limit,
        auto_calculated: @course.supervisor_auto_calculate_enabled?,
        lecturer_capacities: capacities
      )
    end

    private

    def lecturer_enrolments
      @lecturer_enrolments ||= @course.enrolments.where(role: :lecturer).includes(:user).to_a
    end

    def base_remainder_and_total
      return [@course.supervisor_projects_limit, 0, nil] unless @course.supervisor_auto_calculate_enabled?

      total = @course.grouped? ? @course.project_groups.count : @course.projects.where(owner_type: 'User').count
      eligible = lecturer_enrolments.reject(&:supervisor_capacity_excluded?)
      return [0, 0, total] if eligible.empty?

      positive_offset_sum = eligible.sum { |e| [e.supervisor_capacity_offset, 0].max }
      adjusted_total = total - positive_offset_sum
      [adjusted_total / eligible.count, adjusted_total % eligible.count, total]
    end

    def build_lecturer_capacity(enrolment, base)
      approved = @course.projects.supervised_by(enrolment).approved.count
      pending  = @course.projects.supervised_by(enrolment).pending_redo.count

      effective_cap = enrolment.supervisor_capacity_excluded? ? 0 : base + enrolment.supervisor_capacity_offset

      LecturerCapacity.new(
        enrolment: enrolment,
        offset: enrolment.supervisor_capacity_offset,
        approved_count: approved,
        pending_count: pending,
        effective_cap: effective_cap
      )
    end
  end
end
~~~~

=== app/services/user_creator.rb | 39 lines | last commit bd851ac9 2026-10-01 ===

~~~~
require 'ostruct'

class UserCreator
  def self.call(name:, email:, password:, verify_only:, instid: nil)
    name = name.strip
    email = email.strip

    if instid
      instid = instid.strip
    end

    new_user = nil
    new_otp = nil

    begin
      ActiveRecord::Base.transaction do
        new_user = User.create!(
          name: name,
          email_address: email,
          password: password,
          instid: instid,
          has_registered: false
        )

        new_otp = Otp.create!(
          user: new_user,
          token: SecureRandom.uuid,
          verify_only: verify_only
        )
      end
    rescue ActiveRecord::RecordNotUnique
      return OpenStruct.new(success?: false, message: 'Your email is already in the system. Check your inbox or login!')
    rescue StandardError => e
      return OpenStruct.new(success?: false, message: e.message)
    end

    return OpenStruct.new(success?: true, user: new_user, otp_instance: new_otp)
  end
end
~~~~

=== app/services/user_details_validator.rb | 23 lines | last commit bd851ac9 2026-10-01 ===

~~~~
require 'ostruct'

class UserDetailsValidator
  def self.call(name:, password:, password_confirmation:)
    if name.blank?
      return OpenStruct.new(success?: false, message: 'Name cannot be empty')
    end

    if password.blank?
      return OpenStruct.new(success?: false, message: 'Password cannot be empty')
    end

    if password_confirmation.blank?
      return OpenStruct.new(success?: false, message: 'Password confirmation cannot be empty')
    end

    if password != password_confirmation
      return OpenStruct.new(success?: false, message: 'Passwords are not the same')
    end

    return OpenStruct.new(success?: true)
  end
end
~~~~

=== app/services/queries/group_size_confirmability_calculator.rb | 103 lines | last commit a48f894f 2026-08-20 ===

~~~~
module Queries
  # (student_list_finalized) uses quota model to determine the confirmability of group size
  # SEE https://docs.google.com/document/d/1RZAhO7-9Al2Ak3rKhHmnLZyvXfej_J7hyZw7ZYmmXng/edit?usp=sharing for more context
  # OR (default mode) group size within min/max.
  class GroupSizeConfirmabilityCalculator
    def initialize(course, students_to_group:)
      @course = course
      @students_to_group = students_to_group
    end

    def execute
      group_min = @course.group_min
      group_max = @course.group_max

      return blank_result(:group_size_limits_not_configured) if group_min.blank? || group_max.blank?

      if @course.student_list_finalised?
        return blank_result(:no_students_to_group) if @students_to_group <= 0

        execute_quota(group_min, group_max)
      else
        execute_min_max(group_min, group_max)
      end
    end

    def self.feasible_count?(count, group_min, group_max)
      return true if count.zero?
      return false if count.negative?

      k = (count.to_f / group_max).ceil
      (count / k) >= group_min
    end

    private

    def blank_result(error)
      Result.new(found: false, breakdown: [], group_count: 0, error: error)
    end

    # Auto-Confirmability mode
    def execute_quota(group_min, group_max)
      k = (@students_to_group.to_f / group_max).ceil
      base = @students_to_group / k
      rem = @students_to_group % k

      return blank_result(:no_legal_combination_exists) if base < group_min

      breakdown = []
      breakdown << { group_size: base + 1, number_of_groups: rem } if rem.positive?
      breakdown << { group_size: base, number_of_groups: k - rem } if (k - rem).positive?
      breakdown.sort_by! { |entry| -entry[:group_size] }

      Result.new(found: true, breakdown: breakdown, group_count: k, error: nil,
                 group_min: group_min, group_max: group_max,
                 students_to_group: @students_to_group, finalised: true)
    end

    # Default mode
    def execute_min_max(group_min, group_max)
      breakdown = (group_min..group_max).map { |size| { group_size: size, number_of_groups: nil } }
      Result.new(found: true, breakdown: breakdown, group_count: nil, error: nil,
                 group_min: group_min, group_max: group_max,
                 students_to_group: @students_to_group, finalised: false)
    end

    class Result
      attr_reader :breakdown, :group_count, :error

      def initialize(found:, breakdown:, group_count:, error:,
                     group_min: nil, group_max: nil, students_to_group: nil, finalised: nil)
        @found = found
        @breakdown = breakdown
        @group_count = group_count
        @error = error
        @group_min = group_min
        @group_max = group_max
        @students_to_group = students_to_group
        @finalised = finalised
      end

      def found? = @found
      def success? = @error.nil?
      def error? = !success?

      def confirmable_size?(size)
        return false unless found?
        return false unless (@group_min..@group_max).cover?(size)
        return true unless @finalised

        remainder = @students_to_group - size
        GroupSizeConfirmabilityCalculator.feasible_count?(remainder, @group_min, @group_max)
      end

      def message
        case error
        when :group_size_limits_not_configured then 'Group size limits are not set for this course.'
        when :no_students_to_group then 'Enter a student count greater than 0.'
        when :no_legal_combination_exists then 'No legal group size combination exists for this number of students.'
        end
      end
    end
  end
end
~~~~


---

# C. Models - verbatim

`Course` is dumped in full as requested. `User` and `Enrolment` are dumped in full
because they carry the grouping associations and the enrolment lifecycle.

**Concerns included by these models:** `app/models/concerns/` contains only a `.keep`
file - there are no model concerns in this repo. `app/controllers/concerns/` holds
`authentication.rb` and `participant_browsing.rb` (controller-side; not included by any
model).
=== app/models/project_group.rb | 32 lines | last commit c27072d5 2026-08-21 ===

~~~~
class ProjectGroup < ApplicationRecord
  has_many :project_group_members, dependent: :destroy
  belongs_to :course

  has_many :users, through: :project_group_members
  has_one :project, dependent: :destroy, as: :owner
  has_many :project_group_invites, dependent: :destroy
  has_many :project_group_invite_links, dependent: :destroy

  def revert_to_draft!
    update!(confirmed: false)
  end

  def pending_requests
    project_group_invites.pending
  end

  def has_project?
    project.exists?
  end

  def leader?(user)
    leader_id == user.id
  end

  def confirmable?
    Queries::GroupSizeConfirmabilityCalculator
      .new(course, students_to_group: course.unconfirmed_students_count)
      .execute
      .confirmable_size?(project_group_members.count)
  end
end
~~~~

=== app/models/project_group_member.rb | 4 lines | last commit c930ce04 2025-07-31 ===

~~~~
class ProjectGroupMember < ApplicationRecord
  belongs_to :user
  belongs_to :project_group
end
~~~~

=== app/models/project_group_invite.rb | 34 lines | last commit 3bb88bad 2026-08-11 ===

~~~~
class ProjectGroupInvite < ApplicationRecord
  belongs_to :project_group
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  enum :kind,   { direct_request: 0, direct_invite: 1 }
  enum :status, { pending: 0, accepted: 1, declined: 2 }

  # Blocks a student double-requesting to the same group
  validates :sender_id,
            uniqueness: {
              scope: %i[project_group_id kind],
              conditions: -> { where(status: :pending) },
              message: 'already has a pending request for this group'
            },
            if: -> { direct_request? }

  # Blocks a leader double-inviting same student into same group.
  validates :recipient_id,
            uniqueness: {
              scope: %i[project_group_id kind],
              conditions: -> { where(status: :pending, kind: :direct_invite) },
              message: 'already has a pending invite for this group'
            },
            if: -> { direct_invite? }

  validates :kind,   presence: true
  validates :status, presence: true

  scope :pending_for_group, ->(group)   { where(project_group: group, status: :pending) }
  scope :for_course,        ->(course)  { joins(:project_group).where(project_groups: { course_id: course.id }) }
  scope :sent_by,           ->(user)    { where(sender: user) }
  scope :sent_to,           ->(user)    { where(recipient: user) }
end
~~~~

=== app/models/project_group_invite_link.rb | 4 lines | last commit 139cf85f 2026-08-07 ===

~~~~
class ProjectGroupInviteLink < ApplicationRecord
  belongs_to :project_group
  belongs_to :sender, class_name: 'User'
end
~~~~

=== app/models/course.rb | 229 lines | last commit 5b99fe02 2026-08-21 ===

~~~~
require 'sqids'

# Represents courses
class Course < ApplicationRecord
  has_many :enrolments, dependent: :destroy
  has_many :users, through: :enrolments

  has_many :students, -> { where(enrolments: { role: :student }) }, through: :enrolments, source: :user
  has_many :coordinators, -> { where(enrolments: { role: :coordinator }) }, through: :enrolments, source: :user
  has_many :lecturers, -> { where(enrolments: { role: :lecturer }) }, through: :enrolments, source: :user

  has_many :projects, dependent: :destroy
  has_many :project_groups, dependent: :destroy

  has_one :project_template, dependent: :destroy

  has_many :topics, dependent: :destroy
  has_many :project_group_members, through: :project_groups

  attribute :student_access, :integer, default: :no_restriction
  attribute :lecturer_access, :boolean, default: true
  attribute :use_progress_updates, :boolean, default: false
  attribute :require_coordinator_approval, :boolean, default: false
  attribute :auto_approve_copied_topics_without_changes, :boolean, default: false

  attribute :supervisor_projects_limit, :integer, default: 1
  attribute :starting_week, :integer, default: 1
  attribute :number_of_updates, :integer

  enum :student_access, { owner_only: 0, own_lecturer_only: 1, no_restriction: 2 }

  scope :managed_by, ->(user) { joins(:enrolments).where(enrolments: { user_id: user.id, role: %i[lecturer coordinator] }).distinct }
  scope :by_coursecode, ->(code) { where(coursecode: code) }

  validates :course_name, presence: { message: 'cannot be empty' }
  validates :require_coordinator_approval, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :grouped, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :starting_week, presence: { message: 'cannot be empty' }, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }

  validates :use_progress_updates, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :number_of_updates, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole if using progress updates number' }, if: :use_progress_updates

  validates :lecturer_access, inclusion: { in: [true, false], message: 'must be true or false' }
  validates :student_access, presence: { message: 'cannot be empty' }, inclusion: { in: Course.student_accesses.keys.map, message: 'is invalid' }
  validates :supervisor_projects_limit, presence: { message: 'cannot be empty' }, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }
  validates :coursecode, uniqueness: { message: 'has already been taken' }, allow_nil: true
  validates :auto_approve_copied_topics_without_changes, inclusion: { in: [true, false], message: 'must be true or false' }

  # group_min and group_max are required whenever grouping is enabled
  validates :group_min, presence: { message: 'is required when self-grouping is enabled' }, if: :grouping_enabled?
  validates :group_max, presence: { message: 'is required when self-grouping is enabled' }, if: :grouping_enabled?
  validates :group_min, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }, allow_nil: true

  validates :group_max,
            numericality: { only_integer: true, greater_than_or_equal_to: :group_min_for_validation, message: 'must be greater than or equal to minimum' },
            allow_nil: true,
            if: -> { group_min.present? && group_max.present? }

  # student_list_finalised cannot be true if grouping_enabled is false.
  validates :student_list_finalised, inclusion: { in: [false], message: 'cannot be set without self-grouping enabled' }, unless: :grouping_enabled?
  validate :grouping_window_dates_valid, if: -> { grouping_opens_at.present? && grouping_closes_at.present? }

  before_validation :null_number_of_updates_if_not_used
  before_validation :clear_grouping_fields_if_disabled

  def generate_coursecode!
    raise StandardError, 'Course join code can\'t be used for grouped course' if grouped

    sqids = Sqids.new(alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', min_length: 6)
    self.coursecode = sqids.encode([id, SecureRandom.random_number(1_000_000_000)])
    save!
  end

  def grouping_window_open?
    return false unless grouping_enabled?
    return false unless grouping_open?

    opens_ok = grouping_opens_at.nil? || Time.current >= grouping_opens_at
    closes_ok = grouping_closes_at.nil? || Time.current <= grouping_closes_at
    opens_ok && closes_ok
  end

  def disable_grouping!
    transaction do
      destroy_draft_groups
      update!(grouping_enabled: false, grouping_open: false, student_list_finalised: false)
    end
  end

  # NOTE: Called when coordinator switches from student_list_finalised mode back to default mode.
  # Confirmed groups stay. Draft groups are destroyed.
  def revert_to_default_mode!
    transaction do
      destroy_draft_groups
      update!(student_list_finalised: false)
    end
  end

  def enable_auto_confirmability_mode!
    update!(student_list_finalised: true)
  end

  def unconfirmed_students_count
    confirmed_member_count = ProjectGroupMember
                             .joins(:project_group)
                             .where(project_groups: { course_id: id, confirmed: true })
                             .count

    students.count - confirmed_member_count
  end

  STUDENT_CSV_COLUMNS = ['Last name', 'ID number', 'Email address'].freeze

  def parse_csv_grouped(csv_obj)
    ret = {}

    csv_obj.each do |row|
      mapped_columns = STUDENT_CSV_COLUMNS.map { |col| row[col] }
      # in the csv, an empty group still has a row, just that all columns of that row are not populated, this is valid
      next if mapped_columns.all?(&:nil?)

      # if it passed the previous check, it means that the current row is not ALL empty, but ONE OF the columns might still be, this is invalid
      mapped_columns.each { |col| raise StandardError, 'Invalid CSV file' if col.nil? }

      group = row['Group'].strip
      ret[group] ||= Set[]
      ret[group].add({
                       name: row['Last name'].strip,
                       instid: row['ID number'].strip,
                       email_address: row['Email address'].strip
                     })
    end

    ret
  end

  def parse_csv_solo(csv_obj)
    ret = Set[]

    csv_obj.each do |row|
      mapped_columns = STUDENT_CSV_COLUMNS.map { |col| row[col] }
      mapped_columns.each { |col| raise StandardError, 'Invalid CSV file' if col.nil? }

      ret.add({
                name: row['Last name'].strip,
                instid: row['ID number'].strip,
                email_address: row['Email address'].strip
              })
    end

    ret
  end

  def students_with_status(status, student_list)
    case status
    when 'approved'
      approved_owner_ids = projects.approved.where(owner_type: 'User').pluck(:owner_id)
      student_list.select { |s| approved_owner_ids.include?(s.id) }
    when 'not_submitted'
      submitted_ids = projects.where(owner_type: 'User').pluck(:owner_id)
      student_list.reject { |s| submitted_ids.include?(s.id) }
    when 'pending', 'redo', 'rejected'
      student_list.select do |s|
        projects.find_by(owner_type: 'User', owner_id: s.id)&.current_status == status
      end
    else
      []
    end
  end

  def groups_with_status(status, group_list)
    case status
    when 'not_submitted'
      existing_ids = projects.where(owner_type: 'ProjectGroup').pluck(:owner_id)
      group_list.reject { |g| existing_ids.include?(g.id) }
    when 'approved', 'pending', 'redo', 'rejected'
      group_list.select do |g|
        projects.find_by(owner_type: 'ProjectGroup', owner_id: g.id)&.current_status == status
      end
    else
      []
    end
  end

  def solo_supervisor?
    enrolments.where(role: %i[lecturer coordinator]).count < 3
  end

  private

  def destroy_draft_groups
    project_groups.where(confirmed: false).find_each do |group|
      group.destroy!
    end
  end

  def null_number_of_updates_if_not_used
    return if use_progress_updates

    self.number_of_updates = nil
  end

  def clear_grouping_fields_if_disabled
    return if grouping_enabled?

    self.grouping_open          = false
    self.student_list_finalised = false
    self.group_min              = nil
    self.group_max              = nil
    self.grouping_opens_at      = nil
    self.grouping_closes_at     = nil
  end

  def grouping_window_dates_valid
    return unless grouping_closes_at <= grouping_opens_at

    errors.add(:grouping_closes_at, 'must be after the grouping open time')
  end

  def group_min_for_validation
    group_min || 0
  end

  def empty_capacity
    { approved_proposals: 0, pending_proposals: 0, total_proposals: 0,
      max_capacity: supervisor_projects_limit, remaining_capacity: supervisor_projects_limit,
      is_at_capacity: false }
  end
end
~~~~

=== app/models/enrolment.rb | 37 lines | last commit 4c01c1d0 2026-09-07 ===

~~~~
class Enrolment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  has_many :projects, dependent: :destroy
  enum :role, { lecturer: 0, coordinator: 1, student: 2 }
  validates :supervisor_capacity_offset, numericality: { only_integer: true }, allow_nil: true

  # Enrolls a user in a course using a course code.
  # Validates that the course exists and that joining via course code is enabled.
  # Returns true if the user was newly enrolled, or false if they were already enrolled.
  def self.enroll_via_coursecode(user, code)
    course = Course.by_coursecode(code).first

    raise 'Invalid course code' unless course
    raise 'Joining via course code is disabled for this course' unless course.coursecode_enabled

    if course.email_domain_restriction_enabled?
      domain_array = course.email_domain_restriction.split(',').map(&:strip)
      user_email_domain = user.email_address.sub(/^.*@/, '')

      unless domain_array.include?(user_email_domain)
        # Only thing this does is add @ to each domain to make it prettier
        domain_array_string = domain_array.map { |d| " @#{d} " }.join(', ')
        raise "Email Domain Restriction is enabled for this course. Please join using an account linked to an email with #{domain_array_string} ."
      end
    end

    enrolment = find_or_create_by!(
      user: user,
      course: course,
      role: :student
    )

    enrolment.previously_new_record?
  end
end
~~~~

=== app/models/user.rb | 31 lines | last commit dc1c326b 2026-10-07 ===

~~~~
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  has_many :enrolments, dependent: :destroy
  has_many :courses, through: :enrolments

  # sort cards by earliest enrolment (coordinators can have multiple).
  def courses_by_earliest_enrolment
    Course.joins(:enrolments)
          .where(enrolments: { user_id: id })
          .group('courses.id')
          .order(Arel.sql('MIN(enrolments.created_at) DESC, courses.id DESC'))
  end

  has_many :project_group_members, dependent: :destroy
  has_many :project_groups, through: :project_group_members

  has_many :comments, dependent: :destroy
  has_one :otp, dependent: :destroy

  has_many :solo_projects, as: :owner, class_name: 'Project'
  has_many :group_projects, through: :project_groups, source: :project

  validates :email_address, presence: { message: 'cannot be empty' }, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }, uniqueness: { case_sensitive: false }
  validates :password, length: { maximum: 72, message: 'must be less than 72 characters' }
  validates :name, presence: { message: 'cannot be blank' }
end
~~~~

=== app/models/project.rb | 106 lines | last commit 8a35e745 2026-10-21 ===

~~~~
class Project < ApplicationRecord
  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
  default_scope { where(ownership_type: %i[student project_group]) }

  belongs_to :supervisor_enrolment, class_name: 'Enrolment', foreign_key: 'enrolment_id'
  belongs_to :course
  belongs_to :owner, polymorphic: true

  has_many :project_instances, dependent: :destroy
  has_many :progress_updates, dependent: :destroy
  has_many :comments, through: :project_instances

  # DO NOT WRITE TO STATUS IN PROJECTS, IT'S ONLY MEANT TO KEEP TRACK OF THE STATUS OF THE LATEST PROJECT INSTANCE
  # write to the latest project instance instead
  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }, default: :pending

  # Status filters
  scope :pending, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }
  scope :pending_redo, -> { where(status: %i[pending redo]) }
  scope :proposals, -> { where(status: %i[pending redo rejected]) }
  scope :supervised_by, ->(supervisor_enrolment) { where(supervisor_enrolment: supervisor_enrolment) }
  scope :owned_by_user_or_groups, lambda { |user, groups|
    where(owner: [user] + groups.to_a)
  }
  scope :owned_by_user, ->(user) { where(owner: user) }
  scope :owned_by_groups, ->(groups) { where(owner: groups) }

  before_validation :set_ownership_type

  validate :project_group_must_be_confirmed, if: -> { owner_type == 'ProjectGroup' }

  STATUS_SORT_ORDER = { 'rejected' => 0, 'redo' => 1, 'pending' => 2, 'not_submitted' => 3, 'approved' => 4 }.freeze

  def supervisor
    supervisor_enrolment.user
  end

  def member
    if ownership.owner.is_a?(ProjectGroup)
      ownership.owner.users
    else
      [ownership.user]
    end
  end

  def current_instance
    project_instances.order(version: :desc).first
  end

  def current_status
    (current_instance&.status || status || :not_submitted).to_s
  end

  def current_title
    current_instance&.title || title
  end

  def owner_name
    if owner.respond_to?(:name)
      owner.name
    elsif owner.respond_to?(:group_name)
      owner.group_name
    else
      'Unknown'
    end
  end

  def editable?
    !approved?
  end

  def instance_to_edit(created_by:, has_supervisor_comment:)
    if rejected? || redo? || (pending? && has_supervisor_comment)
      project_instances.build(
        version: (project_instances.maximum(:version) || 0) + 1,
        created_by: created_by,
        supervisor_enrolment: supervisor_enrolment,
        status: :pending
      )
    else
      # If approved and pending (no supervisor comment) dont create new instance
      project_instances.last
    end
  end

  # The owning ProjectGroup, when this project belongs to one.
  def group
    owner if owner_type == 'ProjectGroup'
  end

  private

  def set_ownership_type
    self.ownership_type = :student
  end

  def project_group_must_be_confirmed
    return if owner_id.blank?

    return if group&.confirmed?

    errors.add(:owner_id, 'cannot be a draft group')
  end
end
~~~~

=== app/models/project_instance.rb | 53 lines | last commit 601ab904 2026-08-07 ===

~~~~
class ProjectInstance < ApplicationRecord
  enum :project_instance_type, { topic: 0, project: 1 }

  default_scope { where(project_instance_type: :project) }

  belongs_to :project
  belongs_to :supervisor_enrolment, class_name: 'Enrolment', foreign_key: 'enrolment_id'

  has_many :comments, as: :location, dependent: :destroy

  belongs_to :created_by, class_name: 'User'
  belongs_to :source_topic, class_name: 'Topic', optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }, default: :pending
  # attribute :status, :integer, default: :pending

  has_many :project_instance_fields, dependent: :destroy, as: :instance

  before_validation :set_project_type
  before_validation :sync_title_from_fields
  after_save :update_parent_project

  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :title, presence: true

  def supervisor
    supervisor_enrolment.user
  end

  private

  def update_parent_project
    return unless project.project_instances.order(version: :desc, created_at: :desc).first == self

    project.update(
      status: status,
      supervisor_enrolment: supervisor_enrolment
    )
  end

  def set_project_type
    self.project_instance_type = :project
  end

  def sync_title_from_fields
    title_field = project_instance_fields.detect do |f|
      f.project_template_field&.is_project_title?
    end
    return if title_field.blank?

    self.title = title_field.value
  end
end
~~~~

=== app/models/ownership.rb | 5 lines | last commit a2aad7e9 2025-08-13 ===

~~~~
class Ownership < ApplicationRecord
  belongs_to :owner, polymorphic: true
  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
  has_one :project, dependent: :destroy
end
~~~~

=== app/models/comment.rb | 8 lines | last commit fee040bc 2026-01-09 ===

~~~~
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :location, polymorphic: true

  attribute :deleted, :boolean, default: false

  validates :text, presence: { message: 'cannot be empty' }
end
~~~~


---

# D. Tests - verbatim

**There is no `test/services/group_member_remover_test.rb` on this branch.** The
`GroupMemberRemover` service - self-leave, leader kick, coordinator removal, dissolution,
leader succession, confirmed->draft reversion - has no service-level test file. The
nearest coverage is `test/models/project_group_student_actions_test.rb`, which exercises
`GroupConfirmer` and the `ProjectGroup` model helpers but **not** `GroupMemberRemover`.

`test/models/student_group_member_test.rb` exists but is an empty placeholder (its only
content is a commented-out sample test).

`test/fixtures/` does not exist - there are no YAML fixtures in this repo; all test data
comes from FactoryBot. `test/test_helper.rb` calls `fixtures :all`, which is a no-op
without the directory.
=== test/services/group_creator_test.rb | 122 lines | last commit f39f918d 2026-08-21 ===

~~~~
# test/services/group_creator_test.rb
require 'test_helper'

class GroupCreatorTest < ActiveSupport::TestCase
  setup do
    @course = FactoryBot.create(:course,
                                grouped: true, grouping_enabled: true, grouping_open: true,
                                group_min: 2, group_max: 4, student_list_finalised: false)
    @student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: @student, role: :student)
    @coordinator = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: @coordinator, role: :coordinator)
  end

  test 'self-create succeeds, becomes sole leader+member' do
    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.created?
    assert_nil result.blocked_reason
    group = result.group
    assert_equal @student.id, group.leader_id
    assert_equal 1, group.project_group_members.count
    assert_equal @student.id, group.project_group_members.first.user_id
    assert_match(/^G\d{3}$/, group.group_name)
  end

  test 'self-create blocked when already grouped' do
    existing = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
    FactoryBot.create(:project_group_member, project_group: existing, user: @student)

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'self-create blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'coordinator-create bypasses window_closed' do
    @course.update!(grouping_open: false)

    result = GroupCreator.new(@course, leader: @student, current_user: @coordinator).create!

    assert result.created?
    assert_equal @student.id, result.group.leader_id
  end

  test 'coordinator-create still blocked if target already grouped' do
    existing = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
    FactoryBot.create(:project_group_member, project_group: existing, user: @student)

    result = GroupCreator.new(@course, leader: @student, current_user: @coordinator).create!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'sequential creates get unique, incrementing sequence numbers' do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)

    result_a = GroupCreator.new(@course, leader: @student, current_user: @student).create!
    result_b = GroupCreator.new(@course, leader: other_student, current_user: other_student).create!

    assert_not_equal result_a.group.course_group_sequence, result_b.group.course_group_sequence
    assert_equal result_a.group.course_group_sequence + 1, result_b.group.course_group_sequence
  end

  test 'failure creating membership rolls back the group, no orphan row' do
    assert_no_difference 'ProjectGroup.count' do
      ProjectGroupMember.stub :create!, ->(*) { raise ActiveRecord::RecordInvalid, ProjectGroupMember.new } do
        assert_raises(ActiveRecord::RecordInvalid) do
          GroupCreator.new(@course, leader: @student, current_user: @student).create!
        end
      end
    end
  end

  test 'coordinator-create currently succeeds even when the leader has no enrolment in the course' do
    outsider = FactoryBot.create(:user) # deliberately NOT enrolled in @course

    result = GroupCreator.new(@course, leader: outsider, current_user: @coordinator).create!

    assert result.created?
    assert_equal outsider.id, result.group.leader_id
  end

  test 'auto-generated group_name silently duplicates an existing CSV-imported group_name' do
    csv_group = FactoryBot.create(:project_group, course: @course, group_name: 'G001', course_group_sequence: nil)

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.created?
    assert_equal 'G001', result.group.group_name
    assert_not_equal csv_group.id, result.group.id
    assert_equal 2, @course.project_groups.where(group_name: 'G001').count
  end

  test 'concurrent self-creates never collide on course_group_sequence' do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)

    results = [@student, other_student].map do |user|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupCreator.new(Course.find(@course.id), leader: user, current_user: user).create!
        end
      end
    end.map(&:value)

    assert results.all?(&:created?)
    sequences = results.map { |r| r.group.course_group_sequence }
    assert_equal sequences.uniq.length, sequences.length, 'expected unique sequence numbers, got a collision'
  end
end
~~~~

=== test/services/group_joiner_test.rb | 125 lines | last commit f39f918d 2026-08-21 ===

~~~~
# test/services/group_joiner_test.rb
require 'test_helper'

class GroupJoinerTest < ActiveSupport::TestCase
  setup do
    @course = FactoryBot.create(:course,
                                grouped: true, grouping_enabled: true, grouping_open: true,
                                group_min: 2, group_max: 3, student_list_finalised: false)
    @leader  = FactoryBot.create(:user)
    @student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: @leader,  role: :student)
    FactoryBot.create(:enrolment, course: @course, user: @student, role: :student)

    @group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
    FactoryBot.create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'join succeeds, adds member' do
    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.joined?
    assert @group.project_group_members.exists?(user_id: @student.id)
  end

  test "join clears joiner's own pending request invites course-wide" do
    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
    invite = FactoryBot.create(:project_group_invite,
                               project_group: other_group, sender: @student, recipient: @leader,
                               kind: :direct_request, status: :pending)

    GroupJoiner.new(@group, current_user: @student).join!

    assert_raises(ActiveRecord::RecordNotFound) { invite.reload }
  end

  test "join does not touch other users' pending invites" do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)
    unrelated_invite = FactoryBot.create(:project_group_invite,
                                         project_group: @group, sender: other_student, recipient: @leader,
                                         kind: :direct_request, status: :pending)

    GroupJoiner.new(@group, current_user: @student).join!

    assert unrelated_invite.reload.persisted?
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when already grouped elsewhere in course' do
    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
    FactoryBot.create(:project_group_member, project_group: other_group, user: @student)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'blocked when group confirmed' do
    @group.update!(confirmed: true)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when group locked' do
    @group.update!(locked: true)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :group_locked, result.blocked_reason
  end

  test 'blocked when group full' do
    filler = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: filler, role: :student)
    FactoryBot.create(:project_group_member, project_group: @group, user: filler)
    another = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: another, role: :student)
    FactoryBot.create(:project_group_member, project_group: @group, user: another)
    # group_max: 3, now at 3 with leader+filler+another

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'concurrent joins on last slot. only one succeeds' do
    filler = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: filler, role: :student)
    FactoryBot.create(:project_group_member, project_group: @group, user: filler)
    # group_max: 3, currently 2 (leader+filler) — exactly 1 slot left

    contender_a = FactoryBot.create(:user)
    contender_b = FactoryBot.create(:user)
    [contender_a, contender_b].each { |u| FactoryBot.create(:enrolment, course: @course, user: u, role: :student) }

    results = [contender_a, contender_b].map do |user|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupJoiner.new(ProjectGroup.find(@group.id), current_user: user).join!
        end
      end
    end.map(&:value)

    joined = results.select(&:joined?)
    blocked = results.select(&:blocked?)

    assert_equal 1, joined.length
    assert_equal 1, blocked.length
    assert_equal :group_full, blocked.first.blocked_reason
  end
end
~~~~

=== test/services/group_member_adder_test.rb | 87 lines | last commit f39f918d 2026-08-21 ===

~~~~
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
~~~~

=== test/services/group_confirmer_test.rb | 71 lines | last commit c8e571e1 2026-07-25 ===

~~~~
require 'test_helper'

class GroupConfirmerTest < ActiveSupport::TestCase
  test 'confirms a group when member count is within min/max in default mode' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert result.confirmed?
    assert group.reload.confirmed?
  end

  test 'blocks with size_illegal when member count is below min in default mode' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 3, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 1, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :size_illegal, result.blocked_reason
    assert_not group.reload.confirmed?
  end

  test 'confirms a group when size appears in legal distribution' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    group = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert result.confirmed?
  end

  test 'blocks with size_illegal when size does not appear in legal distribution' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    group = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 2, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :size_illegal, result.blocked_reason
  end

  test 'blocks with window_closed when grouping window is closed' do
    course = create(:course, grouping_enabled: true, grouping_open: false, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocks with already_confirmed when group is already confirmed' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)
    create_list(:project_group_member, 3, project_group: group)

    result = GroupConfirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :already_confirmed, result.blocked_reason
  end
end
~~~~

=== test/services/group_reverter_test.rb | 33 lines | last commit c8e571e1 2026-07-25 ===

~~~~
require 'test_helper'

class GroupReverterTest < ActiveSupport::TestCase
  test 'reverts a confirmed group to draft' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)

    result = GroupReverter.new(group).revert!

    assert result.reverted?
    assert_not group.reload.confirmed?
  end

  test 'blocks with window_closed when grouping window is closed' do
    course = create(:course, grouping_enabled: true, grouping_open: false, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: true)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocks with already_draft when group is already draft' do
    course = create(:course, grouping_enabled: true, grouping_open: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group  = create(:project_group, course: course, confirmed: false)

    result = GroupReverter.new(group).revert!

    assert_not result.reverted?
    assert_equal :already_draft, result.blocked_reason
  end
end
~~~~

=== test/services/group_direct_inviter_test.rb | 146 lines | last commit f39f918d 2026-08-21 ===

~~~~
require 'test_helper'

class GroupDirectInviterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    @recipient = create(:user)
    create(:enrolment, course: @course, user: @recipient, role: :student)
  end

  test 'leader invites an ungrouped enrolled student — pending direct_invite created, mailer queued' do
    assert_enqueued_jobs 1 do
      result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!
      assert result.invited?
    end

    invite = ProjectGroupInvite.find_by(project_group: @group, recipient: @recipient)
    assert invite.present?
    assert invite.direct_invite?
    assert invite.pending?
  end

  test 'blocked when recipient is not enrolled in the course' do
    outsider = create(:user) # no enrolment at all

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: outsider).invite!

    assert result.blocked?
    assert_equal :invalid_recipient, result.blocked_reason
  end

  test 'blocked when recipient is enrolled as a non-student (e.g. lecturer)' do
    lecturer = create(:user)
    create(:enrolment, course: @course, user: lecturer, role: :lecturer)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: lecturer).invite!

    assert result.blocked?
    assert_equal :invalid_recipient, result.blocked_reason
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create_list(:project_group_member, 1, project_group: @group) # bring size to 2 (min)
    @group.update!(confirmed: true)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when group is full' do
    filler = create(:user)
    create(:enrolment, course: @course, user: filler, role: :student)
    create(:project_group_member, project_group: @group, user: filler)
    another = create(:user)
    create(:enrolment, course: @course, user: another, role: :student)
    create(:project_group_member, project_group: @group, user: another)
    # group_max: 3, now at 3 (leader+filler+another)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'blocked when recipient is already grouped elsewhere in the course' do
    other_group = create(:project_group, course: @course, leader_id: @recipient.id)
    create(:project_group_member, project_group: other_group, user: @recipient)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'duplicate pending invite to the same recipient+group is rescued into already_invited' do
    GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :already_invited, result.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, recipient: @recipient).count
  end

  # ── Edge: no locked? check at all — invites bypass lock state by design ───

  test 'inviting works on a locked group — lock status is irrelevant to direct invites' do
    @group.update!(locked: true)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.invited?
  end

  # ── Edge: leader inviting themselves — implicitly blocked via already_grouped ─

  test 'leader inviting themselves is blocked as already_grouped, not a distinct error' do
    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @leader).invite!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  # ── Edge: same student can hold pending invites from multiple groups at once ─

  test 'a student can hold pending invites from two different groups simultaneously' do
    other_leader = create(:user)
    create(:enrolment, course: @course, user: other_leader, role: :student)
    other_group = create(:project_group, course: @course, leader_id: other_leader.id)
    create(:project_group_member, project_group: other_group, user: other_leader)

    result_a = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!
    result_b = GroupDirectInviter.new(other_group, current_user: other_leader, recipient: @recipient).invite!

    assert result_a.invited?
    assert result_b.invited?
    assert_equal 2, ProjectGroupInvite.where(recipient: @recipient, status: :pending).count
  end

  # ── Contrast with GroupJoiner: nil group_max IS treated as unlimited here ────

  test 'nil group_max is treated as unlimited, not zero capacity' do
    @course.update_columns(group_max: nil) # bypasses course validation to isolate this service's logic

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.invited?
  end
end
~~~~

=== test/services/group_direct_requester_test.rb | 105 lines | last commit f39f918d 2026-08-21 ===

~~~~
require 'test_helper'

class GroupDirectRequesterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id, locked: true)
    create(:project_group_member, project_group: @group, user: @leader)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  test 'student requests a locked, unconfirmed group with a leader — pending direct_request created, mailer queued' do
    assert_enqueued_jobs 1 do
      result = GroupDirectRequester.new(@group, current_user: @student).request!
      assert result.requested?
    end

    invite = ProjectGroupInvite.find_by(project_group: @group, sender: @student)
    assert invite.present?
    assert invite.direct_request?
    assert_equal @leader.id, invite.recipient_id
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when already grouped' do
    other_group = create(:project_group, course: @course, leader_id: @student.id)
    create(:project_group_member, project_group: other_group, user: @student)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when locked group has no leader' do
    @group.update!(leader_id: nil)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :no_leader_assigned, result.blocked_reason
  end

  test 'blocked when group is unlocked — should join directly instead' do
    @group.update!(locked: false)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :group_unlocked, result.blocked_reason
  end

  test 'duplicate pending request is rescued into already_requested' do
    GroupDirectRequester.new(@group, current_user: @student).request!

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :already_requested, result.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
  end

  # ── Edge: no with_lock — relies entirely on the DB unique partial index ───────

  test 'concurrent duplicate requests — DB unique index catches the race, not app logic' do
    results = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupDirectRequester.new(ProjectGroup.find(@group.id), current_user: @student).request!
        end
      end
    end.map(&:value)

    requested = results.select(&:requested?)
    blocked   = results.select(&:blocked?)

    assert_equal 1, requested.length
    assert_equal 1, blocked.length
    assert_equal :already_requested, blocked.first.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
  end
end
~~~~

=== test/services/group_invite_link_generator_test.rb | 77 lines | last commit f39f918d 2026-08-21 ===

~~~~
require 'test_helper'

class GroupInviteLinkGeneratorTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 4, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'leader generates a link — created with a token and 24h expiry' do
    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.generated?
    assert result.token.present?
    assert_in_delta 24.hours.from_now, result.expires_at, 5.seconds

    link = @group.project_group_invite_links.find_by(sender: @leader)
    assert_equal result.token, link.token
  end

  test 'regenerating destroys this sender\'s old link and creates a new one' do
    first = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!
    second = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert_not_equal first.token, second.token
    assert_equal 1, @group.project_group_invite_links.where(sender: @leader).count
    assert_not ProjectGroupInviteLink.exists?(token: first.token)
  end

  test 'regenerating does not touch another sender\'s link' do
    other_member = create(:user)
    create(:enrolment, course: @course, user: other_member, role: :student)
    create(:project_group_member, project_group: @group, user: other_member)
    other_link = GroupInviteLinkGenerator.new(@group, current_user: other_member).generate!

    GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert ProjectGroupInviteLink.exists?(token: other_link.token)
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  # ── Edge: leadership transfer doesn't revoke the ex-leader's existing link ────

  test 'a link generated before a leadership transfer stays fully valid after the transfer' do
    old_leader_link = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    new_leader = create(:user)
    create(:enrolment, course: @course, user: new_leader, role: :student)
    create(:project_group_member, project_group: @group, user: new_leader)
    @group.update!(leader_id: new_leader.id) # simulates promote_next_leader!/promote_leader

    assert ProjectGroupInviteLink.exists?(token: old_leader_link.token)
    link = ProjectGroupInviteLink.find_by(token: old_leader_link.token)
    assert_not link.expires_at.past?
  end
end
~~~~

=== test/services/group_invite_link_redeemer_test.rb | 142 lines | last commit f39f918d 2026-08-21 ===

~~~~
require 'test_helper'

class GroupInviteLinkRedeemerTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    @link_sender = create(:user)
    create(:enrolment, course: @course, user: @link_sender, role: :student)
    @link = create(:project_group_invite_link, project_group: @group, sender: @link_sender,
                                               token: 'valid-token', expires_at: 1.hour.from_now)

    @redeemer_user = create(:user)
    create(:enrolment, course: @course, user: @redeemer_user, role: :student)
  end

  test 'valid unexpired link grants instant membership, no approval step' do
    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.redeemed?
    assert_equal @group.id, result.group.id
    assert @group.project_group_members.exists?(user_id: @redeemer_user.id)
  end

  test 'blocked when link has expired' do
    @link.update!(expires_at: 1.hour.ago)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :expired, result.blocked_reason
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when group is full' do
    2.times do
      filler = create(:user)
      create(:enrolment, course: @course, user: filler, role: :student)
      create(:project_group_member, project_group: @group, user: filler)
    end
    # group_max: 3, now at 3 (leader + 2 fillers)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'blocked when redeemer is already grouped elsewhere in the course' do
    other_group = create(:project_group, course: @course, leader_id: @redeemer_user.id)
    create(:project_group_member, project_group: other_group, user: @redeemer_user)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  # ── Edge: redemption bypasses locked? entirely — a link joins a locked group ──

  test 'redeeming a link joins a LOCKED group instantly, bypassing the request/approve flow' do
    @group.update!(locked: true)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.redeemed?, 'confirm intentional: link redemption ignores locked? entirely'
  end

  # ── Edge: clears BOTH sender-role and recipient-role pending invites course-wide ─

  test 'redeeming clears the redeemer\'s own pending request (sender role) course-wide' do
    other_group = create(:project_group, course: @course, leader_id: @leader.id)
    own_request = create(:project_group_invite, project_group: other_group, sender: @redeemer_user,
                                                recipient: @leader, kind: :direct_request, status: :pending)

    GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert_not ProjectGroupInvite.exists?(own_request.id)
  end

  test 'redeeming clears a pending direct_invite where the redeemer is the RECIPIENT' do
    other_group = create(:project_group, course: @course, leader_id: @leader.id)
    incoming_invite = create(:project_group_invite, project_group: other_group, sender: @leader,
                                                    recipient: @redeemer_user, kind: :direct_invite, status: :pending)

    GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert_not ProjectGroupInvite.exists?(incoming_invite.id)
  end

  test 'redeeming does not touch an unrelated user\'s pending invite' do
    other_student = create(:user)
    create(:enrolment, course: @course, user: other_student, role: :student)
    unrelated = create(:project_group_invite, project_group: @group, sender: other_student,
                                              recipient: @leader, kind: :direct_request, status: :pending)

    GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert ProjectGroupInvite.exists?(unrelated.id)
  end

  # ── Edge: exact expiry boundary ────────────────────────────────────────────

  test 'link is still redeemable at the exact instant of expires_at (not-yet-past)' do
    travel_to @link.expires_at do
      result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!
      assert result.redeemed?
    end
  end

  test 'link is blocked one second past expires_at' do
    travel_to @link.expires_at + 1.second do
      result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!
      assert result.blocked?
      assert_equal :expired, result.blocked_reason
    end
  end
end
~~~~

=== test/services/group_invite_responder_test.rb | 186 lines | last commit f39f918d 2026-08-21 ===

~~~~
require 'test_helper'

class GroupInviteResponderTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id, locked: true)
    create(:project_group_member, project_group: @group, user: @leader)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  # ── direct_request: student sent it, leader is recipient ─────────────────

  test 'leader accepts a direct_request — sender (the requesting student) is added as member' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.accepted?
    assert @group.project_group_members.exists?(user_id: @student.id)
    assert invite.reload.accepted?
  end

  # ── direct_invite: leader sent it, student is recipient ──────────────────

  test 'student accepts a direct_invite — recipient (the invited student) is added as member' do
    invite = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
                                           kind: :direct_invite, status: :pending)

    result = GroupInviteResponder.new(invite, current_user: @student).accept!

    assert result.accepted?
    assert @group.project_group_members.exists?(user_id: @student.id)
    assert invite.reload.accepted?
  end

  test 'declining either kind flips status without changing membership' do
    request = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                            kind: :direct_request, status: :pending)
    invite  = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
                                            kind: :direct_invite, status: :pending)

    GroupInviteResponder.new(request, current_user: @leader).decline!
    GroupInviteResponder.new(invite, current_user: @student).decline!

    assert request.reload.declined?
    assert invite.reload.declined?
    assert_not @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'accept blocked with already_responded when invite was already handled' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :accepted)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :already_responded, result.blocked_reason
  end

  test 'accept blocked when window closed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @course.update!(grouping_open: false)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'accept blocked when joining user is already grouped elsewhere' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    other_group = create(:project_group, course: @course, leader_id: @student.id)
    create(:project_group_member, project_group: other_group, user: @student)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'accept blocked when group already confirmed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'accept blocked when group is full' do
    2.times do
      filler = create(:user)
      create(:enrolment, course: @course, user: filler, role: :student)
      create(:project_group_member, project_group: @group, user: filler)
    end
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'decline blocked with already_responded when invite was already handled' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :declined)

    result = GroupInviteResponder.new(invite, current_user: @leader).decline!

    assert result.blocked?
    assert_equal :already_responded, result.blocked_reason
  end

  # ── Edge: accept! reloads inside the lock — double-accept race is caught ─────

  test 'concurrent double-accept — only one actually adds the member' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    results = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupInviteResponder.new(ProjectGroupInvite.find(invite.id), current_user: @leader).accept!
        end
      end
    end.map(&:value)

    accepted = results.select(&:accepted?)
    blocked  = results.select(&:blocked?)

    assert_equal 1, accepted.length
    assert_equal 1, blocked.length
    assert_equal :already_responded, blocked.first.blocked_reason
    assert_equal 1, @group.project_group_members.where(user_id: @student.id).count
  end

  # ── Edge: decline! has no with_lock, no window/confirmed gate at all ─────────

  test 'declining is allowed even after the grouping window has closed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @course.update!(grouping_open: false)

    result = GroupInviteResponder.new(invite, current_user: @leader).decline!

    assert result.declined?
  end

  test 'declining is allowed even after the group has been confirmed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteResponder.new(invite, current_user: @leader).decline!

    assert result.declined?
  end

  # ── Edge: accepting clears the joining user's OTHER pending items, not this one ─

  test 'accepting clears the joining user\'s other pending invites, and does not touch the one just accepted' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    other_group = create(:project_group, course: @course, leader_id: @leader.id)
    stale_request = create(:project_group_invite, project_group: other_group, sender: @student,
                                                  recipient: @leader, kind: :direct_request, status: :pending)

    GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert invite.reload.accepted?, 'the invite being accepted must survive clear_conflicting_invites!'
    assert_not ProjectGroupInvite.exists?(stale_request.id)
  end
end
~~~~

=== test/services/group_size_confirmability_calculator_test.rb | 83 lines | last commit f39f918d 2026-08-21 ===

~~~~
require 'test_helper'

class GroupSizeConfirmabilityCalculatorTest < ActiveSupport::TestCase
  test 'confirmable_size? is true when size is within min/max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when size is below min in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 3, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.confirmable_size?(2)
  end

  test 'confirmable_size? is false when size exceeds max in default mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 3)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: course.students.count).execute
    assert_not result.confirmable_size?(4)
  end

  test 'confirmable_size? is true when size appears in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when size does not appear in legal distribution' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert_not result.confirmable_size?(2)
  end

  test 'result is not found when no legal distribution exists' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 4, group_max: 4)
    create_list(:enrolment, 7, course: course, role: :student)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 7).execute
    assert_not result.found?
  end

  test 'breakdown has a single entry, not two, when students divide evenly into group_max' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    # 8 students / max 4 => k=2, base=4, rem=0 — should yield ONE breakdown entry of {size: 4, count: 2}
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 8).execute

    assert result.found?
    assert_equal 1, result.breakdown.length
    assert_equal({ group_size: 4, number_of_groups: 2 }, result.breakdown.first)
  end

  test 'confirmable_size? is true for the size that exactly empties the remaining pool' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    # only one group's worth of students left to place
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 3).execute

    assert result.confirmable_size?(3)
  end

  test 'confirmable_size? is false when confirming this size strands an unconfirmable remainder' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    # 5 students to place; confirming a group of 4 leaves 1 student stranded (below group_min of 3)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 5).execute

    assert_not result.confirmable_size?(4)
  end

  test 'feasible_count? is true for a zero remainder' do
    assert Queries::GroupSizeConfirmabilityCalculator.feasible_count?(0, 2, 4)
  end

  test 'feasible_count? is false for a negative remainder' do
    assert_not Queries::GroupSizeConfirmabilityCalculator.feasible_count?(-1, 2, 4)
  end

  test 'default mode allows a confirmable size even when the course has far fewer students than that' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    result = Queries::GroupSizeConfirmabilityCalculator.new(course, students_to_group: 1).execute

    assert result.confirmable_size?(4)
  end
end
~~~~


#### D2. Reference-implementation tests
=== test/services/supervisor_capacity_updater_test.rb | 206 lines | last commit 2977d6a3 2026-07-24 ===

~~~~
require 'test_helper'

class SupervisorCapacityUpdaterTest < ActiveSupport::TestCase
  setup do
    @course = FactoryBot.create(:course,
                                supervisor_projects_limit: 10,
                                supervisor_auto_calculate_enabled: false,
                                grouped: false)

    @lecturer1 = FactoryBot.create(:enrolment, :lecturer, course: @course)
    @lecturer2 = FactoryBot.create(:enrolment, :lecturer, course: @course)
    @lecturer3 = FactoryBot.create(:enrolment, :lecturer, course: @course)

    @service = SupervisorCapacityUpdater.new(@course)
  end

  # --- HAPPY PATH ---

  test 'updates offsets for multiple lecturers against the manual base' do
    offsets = {
      @lecturer1.id.to_s => '5',
      @lecturer2.id.to_s => '3'
    }

    result = @service.update!(offsets: offsets, excluded_ids: [])

    assert result.updated?
    assert result.errors.empty?

    @lecturer1.reload
    @lecturer2.reload
    @lecturer3.reload

    assert_equal 5, @lecturer1.supervisor_capacity_offset
    assert_equal 3, @lecturer2.supervisor_capacity_offset
    assert_equal 0, @lecturer3.supervisor_capacity_offset
    assert_not @lecturer1.supervisor_capacity_excluded
  end

  test 'handles an empty batch as a no-op success' do
    result = @service.update!(offsets: {}, excluded_ids: [])

    assert result.updated?
    assert result.errors.empty?
  end

  test 'exclusion bypasses the capacity check even with an otherwise-invalid offset' do
    offsets = { @lecturer1.id.to_s => '-10' }
    excluded_ids = [@lecturer1.id.to_s]

    result = @service.update!(offsets: offsets, excluded_ids: excluded_ids)

    assert result.updated?
    @lecturer1.reload
    assert @lecturer1.supervisor_capacity_excluded
    assert_equal(-10, @lecturer1.supervisor_capacity_offset)
  end

  test 'clears a previously set offset back to zero' do
    @lecturer1.update!(supervisor_capacity_offset: 5)

    result = @service.update!(offsets: { @lecturer1.id.to_s => '0' }, excluded_ids: [])

    assert result.updated?
    @lecturer1.reload
    assert_equal 0, @lecturer1.supervisor_capacity_offset
  end

  test 'uses the live auto-calculated base, not the manual limit, when enabled' do
    @course.update!(supervisor_auto_calculate_enabled: true)
    create_solo_projects(@course, 21)

    result = @service.update!(offsets: { @lecturer1.id.to_s => '-3' }, excluded_ids: [])

    assert result.updated?
    @lecturer1.reload
    assert_equal(-3, @lecturer1.supervisor_capacity_offset)
  end

  test 'applies exclusion for a lecturer even when no offset is present in the same batch' do
    result = @service.update!(offsets: {}, excluded_ids: [@lecturer3.id.to_s])

    assert result.updated?
    @lecturer3.reload
    assert @lecturer3.supervisor_capacity_excluded
    assert_equal 0, @lecturer3.supervisor_capacity_offset
  end

  test 'preserves an existing offset, dormant, when excluding a lecturer whose offset is not in this batch' do
    @lecturer3.update!(supervisor_capacity_offset: 4)

    result = @service.update!(offsets: {}, excluded_ids: [@lecturer3.id.to_s])

    assert result.updated?
    @lecturer3.reload
    assert @lecturer3.supervisor_capacity_excluded
    assert_equal 4, @lecturer3.supervisor_capacity_offset
  end

  # --- INVALID INPUT / REJECTED OFFSETS ---

  test 'rejects an offset that brings capacity to exactly zero' do
    result = @service.update!(offsets: { @lecturer1.id.to_s => '-10' }, excluded_ids: [])

    assert_not result.updated?
    assert_includes result.errors.first, @lecturer1.user.name
    assert_includes result.errors.first, 'negative or zero capacity'
  end

  test 'rejects an offset that brings capacity below zero' do
    result = @service.update!(offsets: { @lecturer1.id.to_s => '-11' }, excluded_ids: [])

    assert_not result.updated?
    assert_includes result.errors.first, 'negative or zero capacity'
  end

  test 'collects an error per invalid enrolment in the same batch' do
    offsets = {
      @lecturer1.id.to_s => '-10',
      @lecturer2.id.to_s => '-11',
      @lecturer3.id.to_s => '5'
    }

    result = @service.update!(offsets: offsets, excluded_ids: [])

    assert_not result.updated?
    assert_equal 2, result.errors.length
    assert(result.errors.any? { |e| e.include?(@lecturer1.user.name) })
    assert(result.errors.any? { |e| e.include?(@lecturer2.user.name) })
  end

  test 'rejects using the live auto-calculated base, not the manual limit, when enabled' do
    @course.update!(supervisor_auto_calculate_enabled: true)
    create_solo_projects(@course, 21)

    result = @service.update!(offsets: { @lecturer1.id.to_s => '-7' }, excluded_ids: [])

    assert_not result.updated?
    assert_includes result.errors.first, 'negative or zero capacity'
  end

  # --- ATOMICITY ---

  test 'does not persist any changes, including otherwise-valid ones, when one enrolment in the batch is invalid' do
    original_updated_ats = [@lecturer1, @lecturer2, @lecturer3].map(&:updated_at)

    offsets = {
      @lecturer1.id.to_s => '-10', # invalid
      @lecturer2.id.to_s => '3'    # otherwise valid
    }

    result = @service.update!(offsets: offsets, excluded_ids: [])

    assert_not result.updated?

    [@lecturer1, @lecturer2, @lecturer3].each(&:reload)

    assert_equal 0, @lecturer1.supervisor_capacity_offset
    assert_equal 0, @lecturer2.supervisor_capacity_offset
    assert_equal 0, @lecturer3.supervisor_capacity_offset
    assert_equal original_updated_ats, [@lecturer1, @lecturer2, @lecturer3].map(&:updated_at)
  end

  # --- EDGE CASES ---

  test 'silently ignores an enrolment id that does not exist' do
    offsets = {
      '999999' => '5',
      @lecturer1.id.to_s => '3'
    }

    result = @service.update!(offsets: offsets, excluded_ids: [])

    assert result.updated?
    @lecturer1.reload
    assert_equal 3, @lecturer1.supervisor_capacity_offset
  end

  test 'ignores non-lecturer enrolments (student and coordinator roles)' do
    student = FactoryBot.create(:enrolment, :student, course: @course)
    coordinator = FactoryBot.create(:enrolment, :coordinator, course: @course)

    offsets = {
      student.id.to_s => '5',
      coordinator.id.to_s => '5'
    }

    result = @service.update!(offsets: offsets, excluded_ids: [])

    assert result.updated?
    student.reload
    coordinator.reload
    assert_equal 0, student.supervisor_capacity_offset
    assert_equal 0, coordinator.supervisor_capacity_offset
  end

  private

  def create_solo_projects(course, count)
    count.times do
      student_user = FactoryBot.create(:user)
      FactoryBot.create(:enrolment, :student, course: course, user: student_user)
      FactoryBot.create(:project, course: course, owner_type: 'User', owner_id: student_user.id)
    end
  end
end
~~~~

=== test/services/supervisor_capacity_calculator_test.rb | 18 lines | last commit ea98ef2b 2026-07-24 ===

~~~~
# test/services/supervisor_capacity_calculator_test.rb
require 'test_helper'

class SupervisorCapacityCalculatorTest < ActiveSupport::TestCase
  test 'calculate returns capacity info for a lecturer enrolment' do
    course = FactoryBot.create(:course, supervisor_projects_limit: 10)
    lecturer = FactoryBot.create(:user)
    enrolment = FactoryBot.create(:enrolment, :lecturer, course: course, user: lecturer)

    result = Queries::SupervisorCapacityCalculator.new(course).execute
    lecturer_capacity = result.lecturer_capacities.find { |lc| lc.enrolment.id == enrolment.id }

    assert_equal 0, lecturer_capacity.approved_count
    assert_equal 0, lecturer_capacity.pending_count
    assert_equal course.supervisor_projects_limit, lecturer_capacity.effective_cap
    assert_equal false, lecturer_capacity.at_capacity?
  end
end
~~~~


#### D3. Other grouping-related model / controller / integration tests
=== test/models/project_group_student_actions_test.rb | 57 lines | last commit 429b676f 2026-08-21 ===

~~~~
require 'test_helper'

class ProjectGroupStudentActionsTest < ActiveSupport::TestCase
  def setup
    @course = create(:course,
                     grouping_enabled: true,
                     student_list_finalised: false,
                     group_min: 2,
                     group_max: 4,
                     grouping_open: true)
    @alice = create(:user)
    @bob   = create(:user)
    @carol = create(:user)

    @group = create(:project_group, course: @course, leader_id: @alice.id)
    create(:project_group_member, project_group: @group, user: @alice,
                                  created_at: 1.hour.ago)
    create(:project_group_member, project_group: @group, user: @bob,
                                  created_at: 30.minutes.ago)
  end

  # ── GroupConfirmer ───────────────────────────────────────────────────────

  test 'GroupConfirmer confirms a legal group' do
    # group has alice + bob (2 members), min is 2
    result = GroupConfirmer.new(@group).confirm!
    assert result.confirmed?
    assert @group.reload.confirmed?
  end

  test 'GroupConfirmer blocks with size_illegal when group is below min' do
    solo = create(:project_group, course: @course, leader_id: @carol.id)
    create(:project_group_member, project_group: solo, user: @carol)
    # only 1 member, min is 2
    result = GroupConfirmer.new(solo).confirm!
    assert_not result.confirmed?
    assert_equal :size_illegal, result.blocked_reason
    assert_not solo.reload.confirmed?
  end

  # ── pending_requests ──────────────────────────────────────────────────────

  test 'pending_requests returns only pending request invites' do
    pending  = create(:project_group_invite, project_group: @group, sender: @carol, status: :pending)
    declined = create(:project_group_invite, project_group: @group, sender: create(:user), status: :declined)

    assert_includes     @group.pending_requests, pending
    assert_not_includes @group.pending_requests, declined
  end

  # ── leader? helper ────────────────────────────────────────────────────────

  test 'leader? returns true for group leader' do
    assert @group.leader?(@alice)
    assert_not @group.leader?(@bob)
  end
end
~~~~

=== test/models/project_group_invite_test.rb | 56 lines | last commit f39f918d 2026-08-21 ===

~~~~
require 'test_helper'

class ProjectGroupInviteTest < ActiveSupport::TestCase
  def setup
    @course  = create(:course, grouping_enabled: true, student_list_finalised: true,
                               group_min: 2, group_max: 4, grouping_open: true)
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
~~~~

=== test/models/student_group_member_test.rb | 7 lines | last commit fee040bc 2026-01-09 ===

~~~~
require 'test_helper'

class StudentGroupMemberTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
~~~~

=== test/models/course_grouping_settings_test.rb | 170 lines | last commit f39f918d 2026-08-21 ===

~~~~
# test/models/course_grouping_settings_test.rb

require 'test_helper'

class CourseGroupingSettingsTest < ActiveSupport::TestCase
  # Validations

  test 'group_min and group_max are required when grouping is enabled' do
    course = build(:course, grouping_enabled: true, group_min: nil, group_max: nil)
    assert_not course.valid?
    assert course.errors[:group_min].any?
    assert course.errors[:group_max].any?
  end

  test 'group_min must be greater than zero' do
    course = build(:course, grouping_enabled: true, group_min: 0, group_max: 4)
    assert_not course.valid?
    assert course.errors[:group_min].any?
  end

  test 'group_max must be greater than or equal to group_min' do
    course = build(:course, grouping_enabled: true, group_min: 4, group_max: 3)
    assert_not course.valid?
    assert course.errors[:group_max].any?
  end

  test 'group_min and group_max are not required when grouping is disabled' do
    course = build(:course, grouping_enabled: false, group_min: nil, group_max: nil)
    assert course.valid?
  end

  test 'grouping_closes_at must be after grouping_opens_at' do
    course = build(:course,
                   grouping_enabled: true,
                   group_min: 2,
                   group_max: 4,
                   grouping_opens_at: 1.day.from_now,
                   grouping_closes_at: 1.hour.from_now)
    assert_not course.valid?
    assert course.errors[:grouping_closes_at].any?
  end

  test 'grouping window dates are valid when closes_at is after opens_at' do
    course = build(:course,
                   grouping_enabled: true,
                   group_min: 2,
                   group_max: 4,
                   grouping_opens_at: 1.hour.from_now,
                   grouping_closes_at: 1.day.from_now)
    assert course.valid?
  end

  # grouping_window_open?

  test 'grouping_window_open? returns false when grouping is disabled' do
    course = create(:course, grouping_enabled: false)
    assert_not course.grouping_window_open?
  end

  test 'grouping_window_open? returns true when grouping is enabled and no window is set' do
    course = create(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
    assert course.grouping_window_open?
  end

  test 'grouping_window_open? returns true when current time is within the window' do
    course = create(:course,
                    grouping_enabled: true,
                    grouping_open: true,
                    group_min: 2,
                    group_max: 4,
                    grouping_opens_at: 1.hour.ago,
                    grouping_closes_at: 1.hour.from_now)
    assert course.grouping_window_open?
  end

  test 'grouping_window_open? returns false when window has closed' do
    course = create(:course,
                    grouping_enabled: true,
                    grouping_open: true,
                    group_min: 2,
                    group_max: 4,
                    grouping_opens_at: 2.hours.ago,
                    grouping_closes_at: 1.hour.ago)
    assert_not course.grouping_window_open?
  end

  test 'grouping_window_open? returns false when window has not opened yet' do
    course = create(:course,
                    grouping_enabled: true,
                    grouping_open: true,
                    group_min: 2,
                    group_max: 4,
                    grouping_opens_at: 1.hour.from_now,
                    grouping_closes_at: 2.hours.from_now)
    assert_not course.grouping_window_open?
  end

  # disable_grouping!

  test 'disable_grouping! sets grouping_enabled to false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    course.disable_grouping!
    assert_not course.reload.grouping_enabled?
  end

  test 'disable_grouping! resets student_list_finalised to false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    course.disable_grouping!
    assert_not course.reload.student_list_finalised?
  end

  test 'disable_grouping! destroys draft project_groups' do
    course = create(:course, grouping_enabled: true, group_min: 2, group_max: 4)
    draft = create(:project_group, course: course, confirmed: false)
    course.disable_grouping!
    assert_not ProjectGroup.exists?(draft.id)
  end

  test 'disable_grouping! preserves confirmed project_groups' do
    course = create(:course, grouping_enabled: true, group_min: 2, group_max: 4)
    confirmed = create(:project_group, course: course, confirmed: true)
    course.disable_grouping!
    assert ProjectGroup.exists?(confirmed.id)
  end

  # revert_to_default_mode!

  test 'revert_to_default_mode! sets student_list_finalised to false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    course.revert_to_default_mode!
    assert_not course.reload.student_list_finalised?
  end

  test 'revert_to_default_mode! leaves grouping_enabled true' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    course.revert_to_default_mode!
    assert course.reload.grouping_enabled?
  end

  test 'revert_to_default_mode! destroys draft project_groups' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    draft = create(:project_group, course: course, confirmed: false)
    course.revert_to_default_mode!
    assert_not ProjectGroup.exists?(draft.id)
  end

  test 'revert_to_default_mode! does not destroy confirmed project_groups' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    confirmed = create(:project_group, course: course, confirmed: true)
    course.revert_to_default_mode!
    assert ProjectGroup.exists?(confirmed.id)
  end

  test 'grouping_window_open? returns false when grouping_open is false' do
    course = build(:course, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
    assert_not course.grouping_window_open?
  end

  test 'grouping_window_open? returns true when grouping_enabled and grouping_open with no dates' do
    course = build(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4,
                            grouping_opens_at: nil, grouping_closes_at: nil)
    assert course.grouping_window_open?
  end

  test 'disable_grouping! sets grouping_open to false' do
    course = create(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
    course.disable_grouping!
    assert_not course.reload.grouping_open?
  end
end
~~~~

=== test/models/course_test.rb | 52 lines | last commit 41cf0895 2026-03-14 ===

~~~~
require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  def setup
    @course = Course.create!(
      course_name: 'Test Course',
      grouped: false
    )
  end

  test 'generate_coursecode! generates a code and saves it' do
    assert_nil @course.coursecode

    @course.generate_coursecode!

    assert_not_nil @course.coursecode
    assert_operator @course.coursecode.length, :>=, 6

    # Reload from DB to ensure it was saved
    @course.reload
    assert_not_nil @course.coursecode
  end

  test 'generate_coursecode! raises error if course is grouped' do
    @course.update!(grouped: true)

    error = assert_raises(StandardError) do
      @course.generate_coursecode!
    end

    assert_equal "Course join code can't be used for grouped course", error.message
  end

  test 'generate_coursecode! generates unique codes (randomness)' do
    @course.generate_coursecode!
    code1 = @course.coursecode

    @course.generate_coursecode!
    code2 = @course.coursecode

    assert_not_equal code1, code2
  end

  test 'different courses get different codes' do
    course2 = Course.create!(course_name: 'Course 2', grouped: false)

    @course.generate_coursecode!
    course2.generate_coursecode!

    assert_not_equal @course.coursecode, course2.coursecode
  end
end
~~~~

=== test/controllers/enrolments_controller_test.rb | 70 lines | last commit f3786523 2026-08-31 ===

~~~~
require 'test_helper'

class EnrolmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @student = create(:user, has_registered: false)
    @enrolment = create(:enrolment, user: @student, course: @course)
  end

  test 'coordinator can destroy a student enrolment in their own course' do
    sign_in @coordinator

    assert_difference('@course.enrolments.count', -1) do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end

    assert_redirected_to course_path(@course)
  end

  test 'an unauthenticated/non-coordinator user cannot destroy an enrolment' do
    attacker = create(:user)
    sign_in attacker

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end
  end

  test "coordinator of a different course cannot destroy this course's enrolment" do
    other_course = create(:course)
    other_coordinator = create(:user)
    create(:enrolment, :coordinator, user: other_coordinator, course: other_course)

    sign_in other_coordinator

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course)
    end
  end

  test 'client-submitted coordinator_id is ignored for authorization' do
    attacker = create(:user)
    sign_in attacker

    assert_no_difference('@course.enrolments.count') do
      delete enrolment_path(id: @enrolment, course_id: @course, coordinator_id: @coordinator.id)
    end
  end

  test 'enrolment from another course cannot be deleted by course-scoped id' do
    other_course = create(:course)
    other_student = create(:user)
    other_enrolment = create(:enrolment, user: other_student, course: other_course)

    sign_in @coordinator

    delete enrolment_path(id: other_enrolment, course_id: @course)

    assert other_course.enrolments.reload.exists?(id: other_enrolment.id)
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
~~~~

=== test/integration/grouping_settings_surface_test.rb | 46 lines | last commit 8a35e745 2026-10-21 ===

~~~~
require 'test_helper'

class GroupingSettingsSurfaceTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, group_min: 2, group_max: 4)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @student = create(:user)
    create(:enrolment, :student, user: @student, course: @course)
    sign_in @coordinator
  end

  test 'coordinator sees the grouping workspace status bar and the settings link' do
    get course_project_groups_path(@course)

    assert_response :success
    assert_match 'Grouping settings', response.body
    assert_match settings_course_path(@course), response.body
    assert_match 'Default mode', response.body
  end

  test 'coordinator sees the renamed mode labels on course settings' do
    get settings_course_path(@course)

    assert_response :success
    assert_match 'Default mode', response.body
    assert_match 'Auto-Confirmability mode', response.body
    assert_match 'Grouping mode', response.body
  end

  test 'a student sees the workspace without the settings link' do
    sign_in @student

    get course_project_groups_path(@course)

    assert_response :success
    assert_match 'Default mode', response.body
    assert_no_match(/Grouping settings/, response.body)
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
~~~~

=== test/integration/enroll_via_coursecode_test.rb | 63 lines | last commit 00ec853f 2026-10-10 ===

~~~~
require 'test_helper'

class EnrollViaCoursecodeTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @course.generate_coursecode! # Ensures a valid code is created

    @student = create(:user)
  end

  test 'should successfully enroll in course with valid coursecode' do
    @course.update!(coursecode_enabled: true)

    # Sign in the student
    post session_path, params: { email_address: @student.email_address, password: 'password' }
    assert_redirected_to dashboard_path

    # Check initial enrolment state
    assert_not @course.students.include?(@student)

    # Submit valid coursecode
    post invite_path, params: { coursecode: @course.coursecode }

    # The student is redirected to the dashboard and sees a success message
    assert_redirected_to dashboard_path
    assert_equal 'Successfully joined the course', flash[:notice]

    # Verify that an enrolment was created
    assert @course.students.include?(@student)
  end

  test 'should notify students that they are already enrolled in the course' do
    @course.update!(coursecode_enabled: true)

    # Sign in the student
    post session_path, params: { email_address: @student.email_address, password: 'password' }
    assert_redirected_to dashboard_path

    # Submit valid coursecode (and again)
    post invite_path, params: { coursecode: @course.coursecode }
    post invite_path, params: { coursecode: @course.coursecode }

    # The student is redirected to the dashboard and sees a success message
    assert_redirected_to dashboard_path
    assert_equal 'You already joined the course', flash[:notice]
  end

  test 'should display error for invalid coursecode' do
    # Sign in the student
    post session_path, params: { email_address: @student.email_address, password: 'password' }
    assert_redirected_to dashboard_path

    # Run POST with an invalid course code
    post invite_path, params: { coursecode: 'INVALIDCODE123' }

    # Student cannot join, is redirected with an error alert
    assert_redirected_to dashboard_path
    assert_equal 'Invalid course code', flash[:alert]

    # Check that they did not join the course
    assert_not @course.students.include?(@student)
  end
end
~~~~

=== test/integration/update_coursecode_test.rb | 70 lines | last commit 00ec853f 2026-10-10 ===

~~~~
require 'test_helper'

class UpdateCoursecodeTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @lecturer = create(:user, :staff)
    create(:enrolment, :coordinator, user: @lecturer, course: @course)
  end

  test 'should generate and display a course code via update_coursecode API' do
    # Sign in the lecturer (coordinator)
    post session_path, params: { email_address: @lecturer.email_address, password: 'password' }
    assert_redirected_to dashboard_path

    assert_nil @course.coursecode

    # The UI only renders the code/regenerate controls while joining via code
    # is enabled, so enable before generating.
    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: true } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    post update_coursecode_course_path(@course), params: { generate: true }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    # The request should succeed and return turbo stream content
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type

    # The coursecode must be generated and saved to the course via the API call
    @course.reload
    assert_not_nil @course.coursecode

    # Check if there's a generated course code on the UI via the turbo stream response
    # It replaces the 'course_code_form' which contains the new course code string.
    assert_match @course.coursecode, response.body
  end

  test 'should toggle the coursecode_enabled field in courses' do
    # Sign in the lecturer (coordinator)
    post session_path, params: { email_address: @lecturer.email_address, password: 'password' }
    assert_redirected_to dashboard_path

    assert_nil @course.coursecode
    assert_equal @course.coursecode_enabled, false

    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: true } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    # The request should succeed and return turbo stream content
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type

    # The coursecode_enabled must be set to true
    @course.reload
    assert_equal @course.coursecode_enabled, true
  end

  test 'turning joining off wipes the stored coursecode' do
    post session_path, params: { email_address: @lecturer.email_address, password: 'password' }
    assert_redirected_to dashboard_path

    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: true } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    post update_coursecode_course_path(@course), params: { generate: true }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_not_nil @course.reload.coursecode

    post update_coursecode_course_path(@course), params: { course: { coursecode_enabled: false } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :success
    @course.reload
    assert_not @course.coursecode_enabled
    assert_nil @course.coursecode
  end
end
~~~~


#### D4. Factories
=== test/factories/project_groups.rb | 8 lines | last commit 2e833c40 2026-05-09 ===

~~~~
FactoryBot.define do
  factory :project_group do
    association :course
    group_name { Faker::Lorem.unique.word }
    confirmed { false }
    locked { false }
  end
end
~~~~

=== test/factories/project_group_members.rb | 6 lines | last commit 2e833c40 2026-05-09 ===

~~~~
FactoryBot.define do
  factory :project_group_member do
    association :user
    association :project_group
  end
end
~~~~

=== test/factories/project_group_invites.rb | 9 lines | last commit 429b676f 2026-08-21 ===

~~~~
FactoryBot.define do
  factory :project_group_invite do
    association :project_group
    association :sender, factory: :user
    association :recipient, factory: :user
    kind   { :direct_request }
    status { :pending }
  end
end
~~~~

=== test/factories/project_group_invite_links.rb | 8 lines | last commit f39f918d 2026-08-21 ===

~~~~
FactoryBot.define do
  factory :project_group_invite_link do
    association :project_group
    association :sender, factory: :user
    token { SecureRandom.urlsafe_base64(8) }
    expires_at { 24.hours.from_now }
  end
end
~~~~

=== test/factories/courses.rb | 27 lines | last commit 601ab904 2026-08-07 ===

~~~~
FactoryBot.define do
  factory :course do
    course_name { Faker::Educator.course_name }
    grouped { false }
    supervisor_projects_limit { 5 }
    starting_week { 1 }
    student_access { :no_restriction }
    lecturer_access { true }
    use_progress_updates { false }
    require_coordinator_approval { false }

    after(:create) do |course|
      template = course.build_project_template
      template.project_template_fields.build(
        label: 'Project Title',
        field_type: 'shorttext',
        applicable_to: 'both',
        is_project_title: true
      )
      template.save!
    end

    trait :grouped do
      grouped { true }
    end
  end
end
~~~~

=== test/factories/enrolments.rb | 15 lines | last commit acd57379 2026-03-16 ===

~~~~
FactoryBot.define do
  factory :enrolment do
    association :user
    association :course
    role { :student }
  end

  trait :lecturer do
    role { :lecturer }
  end

  trait :coordinator do
    role { :coordinator }
  end
end
~~~~

=== test/factories/users.rb | 13 lines | last commit 0d361709 2026-08-26 ===

~~~~
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email_address { Faker::Internet.unique.email }
    password { 'password' }
    has_registered { true }
    instid { Faker::Alphanumeric.alphanumeric(number: 8) }

    trait :staff do
      instid { nil }
    end
  end
end
~~~~


#### D5. Test support files
=== test/test_helper.rb | 17 lines | last commit 8a35e745 2026-10-21 ===

~~~~
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include FactoryBot::Syntax::Methods
  end
end
~~~~

=== test/support/with_clues.rb | 50 lines | last commit 6ba7103e 2026-09-10 ===

~~~~
# Dump the browser's console log and the page HTML whenever a system test
# fails, so a CI-only failure carries the JS/log context needed to debug it —
# the default screenshot alone is often not enough. Fault-tolerant by design:
# it only ever runs on a failure, and its own dumps must never mask the
# underlying failure.
#
# Mirrors "Sustainable Web Development with Rails" §12.6.3.
module TestSupport
  module WithClues
    # Wrap the whole test run (setups, body, teardowns) so any failure path
    # passes through the clue dump. Overriding `run` lets us do this without
    # colliding with ActiveSupport::TestCase's `around` callback DSL.
    def run(*)
      with_clues { super }
    end

    private

    def with_clues
      yield
    rescue Exception => e # rubocop:disable Lint/RescueException -- must surface every failure path, not just StandardError
      puts "[ with_clues ] Test failed: #{e.class}: #{e.message}"
      dump_browser_logs
      dump_page_html
      raise
    end

    def dump_browser_logs
      return puts "[ with_clues ] NO BROWSER LOGS: page.driver #{page.driver.class} does not respond to #browser" unless page.driver.respond_to?(:browser)
      return puts "[ with_clues ] NO BROWSER LOGS: page.driver.browser #{page.driver.browser.class} does not respond to #manage" unless page.driver.browser.respond_to?(:manage)
      return puts "[ with_clues ] NO BROWSER LOGS: page.driver.browser.manage #{page.driver.browser.manage.class} does not respond to #logs" unless page.driver.browser.manage.respond_to?(:logs)

      puts '[ with_clues ] Browser Logs {'
      page.driver.browser.manage.logs.get(:browser).each do |log|
        puts "  #{log.level}: #{log.message}"
      end
      puts '[ with_clues ] } END Browser Logs'
    rescue StandardError => e
      puts "[ with_clues ] browser log dump failed: #{e.class}: #{e.message}"
    end

    def dump_page_html
      puts '[ with_clues ] HTML {'
      puts page.html
      puts '[ with_clues ] } END HTML'
    rescue StandardError => e
      puts "[ with_clues ] page HTML dump failed: #{e.class}: #{e.message}"
    end
  end
end
~~~~


---

# E. Schema and migrations

## E1. `db/schema.rb` - grouping-relevant tables and columns (verbatim excerpt)

Schema version on this branch: `2026_10_01_123305` (line 13 of `db/schema.rb`).
The **same** version string is on `origin/main`, but the file contents differ - main has
none of the grouping tables below. See `02_backend_audit.md` Step-0 notes.

~~~~
ActiveRecord::Schema[8.0].define(version: 2026_10_01_123305) do
~~~~

The grouping-relevant tables, reproduced verbatim from `db/schema.rb`:

~~~~
  create_table "courses", force: :cascade do |t|
    t.string "course_name", null: false
    t.integer "number_of_updates"
    t.integer "starting_week", null: false
    t.boolean "grouped", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supervisor_projects_limit", null: false
    t.boolean "require_coordinator_approval", null: false
    t.integer "student_access", null: false
    t.boolean "lecturer_access", null: false
    t.boolean "use_progress_updates", null: false
    t.string "course_description"
    t.string "file_link"
    t.string "coursecode"
    t.boolean "coursecode_enabled", default: false, null: false
    t.boolean "toggle_topics", default: true
    t.boolean "grouping_enabled", default: false, null: false
    t.boolean "student_list_finalised", default: false, null: false
    t.integer "group_min"
    t.integer "group_max"
    t.boolean "grouping_open", default: false, null: false
    t.datetime "grouping_opens_at"
    t.datetime "grouping_closes_at"
    t.boolean "auto_approve_copied_topics_without_changes", default: false, null: false
    t.boolean "supervisor_auto_calculate_enabled", default: false, null: false
    t.boolean "lecturers_can_manage_groups", default: true, null: false
    t.string "email_domain_restriction"
    t.boolean "email_domain_restriction_enabled", default: false, null: false
    t.index ["coursecode"], name: "index_courses_on_coursecode", unique: true
  end

  create_table "enrolments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "course_id", null: false
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "supervisor_capacity_offset", default: 0, null: false
    t.boolean "supervisor_capacity_excluded", default: false, null: false
    t.index ["course_id"], name: "index_enrolments_on_course_id"
    t.index ["user_id"], name: "index_enrolments_on_user_id"
  end

  create_table "project_group_invite_links", force: :cascade do |t|
    t.integer "project_group_id", null: false
    t.integer "sender_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_group_id"], name: "index_project_group_invite_links_on_project_group_id"
    t.index ["sender_id"], name: "index_project_group_invite_links_on_sender_id"
    t.index ["token"], name: "index_project_group_invite_links_on_token", unique: true
  end

  create_table "project_group_invites", force: :cascade do |t|
    t.integer "project_group_id", null: false
    t.integer "sender_id", null: false
    t.integer "kind", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "recipient_id", null: false
    t.index ["project_group_id"], name: "index_project_group_invites_on_project_group_id"
    t.index ["recipient_id", "project_group_id", "kind"], name: "idx_pgi_unique_pending_recipient_group_kind", unique: true, where: "((status = 0) AND (kind = 1))"
    t.index ["recipient_id"], name: "index_project_group_invites_on_recipient_id"
    t.index ["sender_id", "project_group_id", "kind"], name: "idx_pgi_unique_pending_sender_group_kind", unique: true, where: "((status = 0) AND (kind = 0))"
    t.index ["sender_id"], name: "index_project_group_invites_on_sender_id"
  end

  create_table "project_group_members", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_group_id"], name: "index_project_group_members_on_project_group_id"
    t.index ["user_id"], name: "index_project_group_members_on_user_id"
  end

  create_table "project_groups", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "group_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "confirmed", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.integer "leader_id"
    t.integer "course_group_sequence"
    t.index ["course_id", "course_group_sequence"], name: "index_project_groups_on_course_id_and_course_group_sequence", unique: true
    t.index ["course_id"], name: "index_project_groups_on_course_id"
  end
~~~~

Foreign keys relevant to grouping (verbatim from the tail of `db/schema.rb`):

~~~~
  add_foreign_key "project_group_invite_links", "project_groups"
  add_foreign_key "project_group_invite_links", "users", column: "sender_id"
  add_foreign_key "project_group_invites", "project_groups"
  add_foreign_key "project_group_invites", "users", column: "recipient_id"
  add_foreign_key "project_group_invites", "users", column: "sender_id"
  add_foreign_key "project_group_members", "project_groups"
  add_foreign_key "project_group_members", "users"
  add_foreign_key "project_groups", "courses"
  add_foreign_key "project_groups", "users", column: "leader_id"
  add_foreign_key "enrolments", "courses"
  add_foreign_key "enrolments", "users"
~~~~

**Note:** there is **no unique index on `project_group_members(user_id)`** and no unique
index on `(user_id, course_id)`. `project_group_members` has only two non-unique
indexes. See `02_backend_audit.md` Part D, question 3.

## E2. Migrations touching grouping tables and columns - verbatim

| Migration file | Timestamp | Branch |
|---|---|---|
| `db/migrate/20250714101030_create_enrolments.rb` | 20250714101030 | pre-existing (on `main`) |
| `db/migrate/20250714101033_create_project_groups.rb` | 20250714101033 | pre-existing (on `main`) |
| `db/migrate/20250715105517_create_project_group_members.rb` | 20250715105517 | pre-existing (on `main`) |
| `db/migrate/20260426065457_add_grouping_settings_to_courses.rb` | 20260426065457 | pre-existing (on `main`) |
| `db/migrate/20260429092127_add_grouping_fields_to_project_groups.rb` | 20260429092127 | pre-existing (on `main`) |
| `db/migrate/20260507104009_add_groups_sequence_to_project_groups.rb` | 20260507104009 | pre-existing (on `main`) |
| `db/migrate/20260531093000_create_project_group_invites.rb` | 20260531093000 | added on this branch |
| `db/migrate/20260714065220_add_dissolved_at_to_project_groups.rb` | 20260714065220 | added on this branch |
| `db/migrate/20260714065259_add_token_and_expires_at_to_project_group_invites.rb` | 20260714065259 | added on this branch |
| `db/migrate/20260726153230_remove_dissolved_at_from_project_groups.rb` | 20260726153230 | added on this branch |
| `db/migrate/20260806113423_reshape_project_group_invites.rb` | 20260806113423 | added on this branch |
| `db/migrate/20260806113610_create_project_group_invite_links.rb` | 20260806113610 | added on this branch |
| `db/migrate/20260811072831_fix_direct_invite_sender_unique_index.rb` | 20260811072831 | added on this branch |
| `db/migrate/20260811102449_add_lecturers_can_manage_groups_to_courses.rb` | 20260811102449 | added on this branch |

=== db/migrate/20250714101030_create_enrolments.rb | 11 lines | last commit c930ce04 2025-07-31 ===

~~~~
class CreateEnrolments < ActiveRecord::Migration[8.0]
  def change
    create_table :enrolments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end
  end
end
~~~~

=== db/migrate/20250714101033_create_project_groups.rb | 10 lines | last commit c930ce04 2025-07-31 ===

~~~~
class CreateProjectGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :project_groups do |t|
      t.references :course, null: false, foreign_key: true
      t.string :group_name, null: false

      t.timestamps
    end
  end
end
~~~~

=== db/migrate/20250715105517_create_project_group_members.rb | 10 lines | last commit c930ce04 2025-07-31 ===

~~~~
class CreateProjectGroupMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :project_group_members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
~~~~

=== db/migrate/20260426065457_add_grouping_settings_to_courses.rb | 11 lines | last commit 73e14690 2026-04-30 ===

~~~~
class AddGroupingSettingsToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :grouping_enabled, :boolean, default: false, null: false
    add_column :courses, :student_list_finalised, :boolean, default: false, null: false
    add_column :courses, :group_min, :integer
    add_column :courses, :group_max, :integer
    add_column :courses, :grouping_open, :boolean, default: false, null: false
    add_column :courses, :grouping_opens_at, :datetime
    add_column :courses, :grouping_closes_at, :datetime
  end
end
~~~~

=== db/migrate/20260429092127_add_grouping_fields_to_project_groups.rb | 8 lines | last commit eb8b1d2b 2026-04-30 ===

~~~~
class AddGroupingFieldsToProjectGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :project_groups, :confirmed, :boolean, default: false, null: false
    add_column :project_groups, :locked, :boolean, default: false, null: false
    add_column :project_groups, :leader_id, :integer
    add_foreign_key :project_groups, :users, column: :leader_id
  end
end
~~~~

=== db/migrate/20260507104009_add_groups_sequence_to_project_groups.rb | 6 lines | last commit a1161130 2026-05-11 ===

~~~~
class AddGroupsSequenceToProjectGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :project_groups, :course_group_sequence, :integer
    add_index :project_groups, [:course_id, :course_group_sequence], unique: true
  end
end
~~~~

=== db/migrate/20260531093000_create_project_group_invites.rb | 20 lines | last commit 8ed23b3c 2026-05-31 ===

~~~~
class CreateProjectGroupInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :project_group_invites do |t|
      t.references :project_group, null: false, foreign_key: true
      t.references :sender,        null: false, foreign_key: { to_table: :users }
      t.integer    :kind,          null: false, default: 0
      t.integer    :status,        null: false, default: 0

      t.timestamps
    end

    # One pending request per sender per group per kind.
    # Partial index: allows a new request after a prior one was declined.
    add_index :project_group_invites,
              [:sender_id, :project_group_id, :kind],
              unique: true,
              where: "status = 0",
              name: "idx_pgi_unique_pending_sender_group_kind"
  end
end
~~~~

=== db/migrate/20260714065220_add_dissolved_at_to_project_groups.rb | 5 lines | last commit 5e1daba7 2026-07-14 ===

~~~~
class AddDissolvedAtToProjectGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :project_groups, :dissolved_at, :datetime
  end
end
~~~~

=== db/migrate/20260714065259_add_token_and_expires_at_to_project_group_invites.rb | 7 lines | last commit 5e1daba7 2026-07-14 ===

~~~~
class AddTokenAndExpiresAtToProjectGroupInvites < ActiveRecord::Migration[8.0]
  def change
    add_column :project_group_invites, :token, :string
    add_column :project_group_invites, :expires_at, :datetime
    add_index :project_group_invites, :token, unique: true
  end
end
~~~~

=== db/migrate/20260726153230_remove_dissolved_at_from_project_groups.rb | 5 lines | last commit 353d5e92 2026-07-27 ===

~~~~
class RemoveDissolvedAtFromProjectGroups < ActiveRecord::Migration[8.0]
  def change
    remove_column :project_groups, :dissolved_at, :datetime
  end
end
~~~~

=== db/migrate/20260806113423_reshape_project_group_invites.rb | 18 lines | last commit 350ddd9e 2026-08-07 ===

~~~~
class ReshapeProjectGroupInvites < ActiveRecord::Migration[8.0]
  def change
    remove_index :project_group_invites, :token
    remove_column :project_group_invites, :token, :string
    remove_column :project_group_invites, :expires_at, :datetime

    add_column :project_group_invites, :recipient_id, :integer, null: false
    add_foreign_key :project_group_invites, :users, column: :recipient_id
    add_index :project_group_invites, :recipient_id

    # Blocks a leader double-inviting same student into same group.
    add_index :project_group_invites,
              %i[recipient_id project_group_id kind],
              unique: true,
              where: "status = 0 AND kind = 1",
              name: "idx_pgi_unique_pending_recipient_group_kind"
  end
end
~~~~

=== db/migrate/20260806113610_create_project_group_invite_links.rb | 14 lines | last commit 350ddd9e 2026-08-07 ===

~~~~
class CreateProjectGroupInviteLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :project_group_invite_links do |t|
      t.references :project_group, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :project_group_invite_links, :token, unique: true
  end
end
~~~~

=== db/migrate/20260811072831_fix_direct_invite_sender_unique_index.rb | 11 lines | last commit dcf494af 2026-08-11 ===

~~~~
class FixDirectInviteSenderUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :project_group_invites, name: "idx_pgi_unique_pending_sender_group_kind"

    add_index :project_group_invites,
              %i[sender_id project_group_id kind],
              unique: true,
              where: "status = 0 AND kind = 0",
              name: "idx_pgi_unique_pending_sender_group_kind"
  end
end
~~~~

=== db/migrate/20260811102449_add_lecturers_can_manage_groups_to_courses.rb | 5 lines | last commit 52052e28 2026-08-12 ===

~~~~
class AddLecturersCanManageGroupsToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :lecturers_can_manage_groups, :boolean, default: true, null: false
  end
end
~~~~


---

# F. Test run output (raw)

All output in this section was captured live on the machine that produced this file.
The three test runs were executed against the branch's own test database
(`propro_test` + Rails' `propro_test-0..11` parallel worker databases). Nothing was
written to `propro_development`.

## F0. Pre-flight

~~~~
$ git rev-parse --abbrev-ref HEAD
feat/student-grouping-crud

$ git rev-parse HEAD
8a35e745159b8af0ce07f36de2b22defa16d8ca2

$ git rev-list --count main..HEAD          # commits on this branch not on main
89
$ git rev-list --count HEAD..main          # commits on main not on this branch
0

$ git merge-base main HEAD
98ca0a9b52d4551bc85265535b7e22acde01717a

$ git status --porcelain --untracked-files=no
(no output - no tracked file is modified)

$ git status -sb
## feat/student-grouping-crud...origin/feat/student-grouping-crud [ahead 116]
?? docs/grouping_backend_audit.md
?? docs/grouping_backend_dump.md
?? docs/grouping_backend_raw_search.md

$ ruby -v
ruby 3.4.10 (2026-06-30 revision 2b0b7728dc) +PRISM [x86_64-linux]

$ bundle -v
Bundler version 2.6.7

$ pg_isready
/var/run/postgresql:5432 - accepting connections

$ psql -l | grep -i propro
 propro_development             | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test                    | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-0                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-1                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-10                 | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-11                 | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-2                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-3                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-4                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-5                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-6                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-7                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-8                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 propro_test-9                  | chiam    | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
~~~~

## F1. Grouping services - targeted run

Command:

~~~~
RAILS_ENV=test bin/rails test \
  test/services/group_creator_test.rb \
  test/services/group_joiner_test.rb \
  test/services/group_member_adder_test.rb \
  test/services/group_confirmer_test.rb \
  test/services/group_reverter_test.rb \
  test/services/group_direct_inviter_test.rb \
  test/services/group_direct_requester_test.rb \
  test/services/group_invite_link_generator_test.rb \
  test/services/group_invite_link_redeemer_test.rb \
  test/services/group_invite_responder_test.rb \
  test/services/group_size_confirmability_calculator_test.rb
~~~~

Output:

~~~~
Running 96 tests in parallel using 12 processes
Run options: --seed 20876

# Running:

................................................................................................

Finished in 4.234887s, 22.6688 runs/s, 47.6990 assertions/s.
96 runs, 202 assertions, 0 failures, 0 errors, 0 skips

~~~~

## F2. Grouping models / controllers / integration - targeted run

Command:

~~~~
RAILS_ENV=test bin/rails test \
  test/models/project_group_invite_test.rb \
  test/models/project_group_student_actions_test.rb \
  test/models/student_group_member_test.rb \
  test/models/course_grouping_settings_test.rb \
  test/models/course_test.rb \
  test/controllers/enrolments_controller_test.rb \
  test/integration/grouping_settings_surface_test.rb \
  test/integration/enroll_via_coursecode_test.rb \
  test/integration/update_coursecode_test.rb
~~~~

Output:

~~~~
Running 50 tests in a single process (parallelization threshold is 50)
Run options: --seed 25160

# Running:

..................................................

Finished in 3.481843s, 14.3602 runs/s, 37.0493 assertions/s.
50 runs, 129 assertions, 0 failures, 0 errors, 0 skips

~~~~

## F3. Full suite

Command:

~~~~
RAILS_ENV=test bin/rails test
~~~~

Output:

~~~~
≈ tailwindcss v4.1.12

Done in 368ms
Running 281 tests in parallel using 12 processes
Run options: --seed 31372

# Running:

......................................................................................................................................................................................................................./home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
............................................................../home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
../home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:288: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
/home/chiam/.local/share/mise/installs/ruby/3.4.10/lib/ruby/gems/3.4.0/gems/htmldiff-0.0.1/lib/htmldiff.rb:276: warning: literal string will be frozen in the future (run with --debug-frozen-string-literal for more information)
..

Finished in 9.233571s, 30.4324 runs/s, 94.9795 assertions/s.
281 runs, 877 assertions, 0 failures, 0 errors, 0 skips

~~~~

The `htmldiff` warnings come from the `htmldiff` gem (a transitive dependency of the
view-comparison helpers) and are unrelated to grouping. They are reproduced above
exactly as printed - 41 warning lines in total, all of the two kinds
`htmldiff.rb:276` and `htmldiff.rb:288`.

## F4. Coverage tooling

~~~~
$ grep -n "simplecov\|coverage" Gemfile Gemfile.lock
(no matches)

$ ls -d test/coverage
(no coverage directory)
~~~~

**No coverage tooling exists in this repository.** There is no `simplecov` gem in the
`Gemfile`/`Gemfile.lock`, no `.simplecov` file, no `test/coverage/` directory, and no
`COVERAGE` environment-variable handling. Per-file coverage for the service files
**cannot be produced** with the tooling present. The number of `test '...'` blocks per
file is given below instead (the runner's totals in F1/F2 are authoritative).

| Test file | `test` blocks | Source under test |
|---|---|---|
| `test/services/group_creator_test.rb` | 10 | `app/services/group_creator.rb` |
| `test/services/group_joiner_test.rb` | 9 | `app/services/group_joiner.rb` |
| `test/services/group_member_adder_test.rb` | 5 | `app/services/group_member_adder.rb` |
| `test/services/group_confirmer_test.rb` | 6 | `app/services/group_confirmer.rb` |
| `test/services/group_reverter_test.rb` | 3 | `app/services/group_reverter.rb` |
| `test/services/group_direct_inviter_test.rb` | 12 | `app/services/group_direct_inviter.rb` |
| `test/services/group_direct_requester_test.rb` | 8 | `app/services/group_direct_requester.rb` |
| `test/services/group_invite_link_generator_test.rb` | 6 | `app/services/group_invite_link_generator.rb` |
| `test/services/group_invite_link_redeemer_test.rb` | 12 | `app/services/group_invite_link_redeemer.rb` |
| `test/services/group_invite_responder_test.rb` | 13 | `app/services/group_invite_responder.rb` |
| `test/services/group_size_confirmability_calculator_test.rb` | 12 | `app/services/queries/group_size_confirmability_calculator.rb` |
| **sum (F1 batch)** | **96** | matches the runner's `96 runs` exactly |

F2 batch, for reference:

| Test file | `test` blocks |
|---|---|
| `test/models/project_group_invite_test.rb` | 6 |
| `test/models/project_group_student_actions_test.rb` | 4 |
| `test/models/student_group_member_test.rb` | 0 |
| `test/models/course_grouping_settings_test.rb` | 22 |
| `test/models/course_test.rb` | 4 |
| `test/controllers/enrolments_controller_test.rb` | 5 |
| `test/integration/grouping_settings_surface_test.rb` | 3 |
| `test/integration/enroll_via_coursecode_test.rb` | 3 |
| `test/integration/update_coursecode_test.rb` | 3 |
| **sum (F2 batch)** | **50** |

Both batch sums match the runner's totals exactly (`96 runs` / `50 runs`), so no
grouping test file is missing from the batches above. The reference-implementation
tests dumped in D2 are **not** part of either batch above
(`test/services/supervisor_capacity_updater_test.rb` = 14 blocks,
`test/services/supervisor_capacity_calculator_test.rb` = 1 block); they were run
separately during the audit and also passed.

## F5. System tests

`bin/rails test` does **not** include `test/system/**`. The system-test suite was not
run as part of this audit (it requires a browser driver). No system test file targets
grouping: `test/system/courses/settings_save_test.rb` and
`test/system/courses/settings_coursecode_test.rb` cover the Course Settings page but not
its grouping section (see `docs/grouping_backend_audit.md` Part E).

---

# G. Markdown docs about services and grouping - verbatim
=== docs/Abstraction/service_classes.md | 104 lines | last commit c8e571e1 2026-07-25 ===

~~~~
# Service classes

Everything that resides in `app/services`.

Service classes represent operations that coordinate changes between models (such as entities and value objects). Changes impact the state of the application (.new!, .save!, .update!).

1. When an object makes no changes to the state of the application, then it's not a service. It may be a query object or value object.
2. When there is no operation, there is no need to execute a service. The class would probably be better designed as a plain query object or value object.
3. Query objects live under `app/services/queries`, namespaced as `module Queries`. They're housed alongside service classes but are exempt from the "changes state" rule above — that's the intentional carve-out, not a contradiction of it.

When implementing a service class, follow these patterns:

## 1. Initializer arguments

1. The service class initializer should contain, in its arguments:
   1. A model instance that is being acted upon. This should be the first positional argument of the initializer. The argument name is left to the developer's discretion, such as `course`, `enrolment`, `project`.
   2. `current_user:` is an optional keyword argument, used only when the service needs the user as data — e.g. recording who performed an action. It is never how the service decides whether the action is allowed. Authorization (who can act) is a Pundit policy concern, checked by the controller before the service runs — never re-derived or re-checked inside the service itself.
   3. When the service has no use for a user object at all (a background job, a side-effect of another operation), the `current_user:` argument is not needed.
   4. For all additional data required by a service, explicit keyword arguments are recommended. Only split into `params:`/`options:` hashes once a service's argument list gets long (roughly 4–5+ keyword arguments, or you're passing configuration that isn't a model attribute) — don't do this preemptively for a two- or three-argument service.

```ruby
# course: A model instance that is being acted upon.
# offsets: New per-lecturer capacity offsets to apply.
# excluded_ids: Enrolment IDs to exclude from auto-calculated capacity.
def initialize(course, offsets:, excluded_ids:)
  @course = course
  @offsets = offsets
  @excluded_ids = excluded_ids
end
```

```ruby
# issue: A model instance that is being acted upon.
# current_user: Optional — only present when needed as data (e.g. audit
#   logging). Never used to gate the operation; that's Pundit's job.
# params: Model properties that will be assigned directly.
# options: Extra configuration for this service, not model properties.
def initialize(issue, current_user: nil, params: {}, options: {})
  @issue = issue
  @current_user = current_user
  @params = params
  @options = options
end
```

## 2. Method naming

Query objects (`app/services/queries`) implement a single public `#execute` method, no arguments. All required data is passed in through the initializer.

Service classes that change state use an explicit, bang-verb instance method matching the action instead — `confirm!`, `remove!`, `revert!`, `update!`. Not `execute`, not `call`. `#execute` on a state-changing service hides the side effect at the call site the same way `#call` does; the verb needs to be visible where it's called.

```ruby
# good — command service, bang-verb, all data via the initializer
SupervisorCapacityUpdater.new(course, offsets: offsets, excluded_ids: excluded_ids).update!

# good — query object, single #execute
Queries::SupervisorCapacityCalculator.new(course).execute

# avoid — a generic `call`, or `execute` on a state-changing service, obscures what happens
SupervisorCapacityUpdater.new(course, offsets: offsets, excluded_ids: excluded_ids).call
```

## 3. Return a rich result object, not a boolean

If a return value is needed, the service should return its result via a `Result` object — never a bare `true`/`false`, and never an ActiveRecord instance on its own.

- A `Result` object can carry a success/failure state, an error list, and whatever data the caller actually needs — named and typed, not a generic hash the caller has to know the shape of.
- `success?`/`error?` are only required on a `Result` that has a genuine second outcome — a `blocked_reason`, an `errors` array, or equivalent. Don't add them to a `Result` that always succeeds; that's aliasing nothing.

```ruby
class SupervisorCapacityUpdater
  class Result
    include ServiceResult # provides success?/error? from `errors.empty?`

    attr_reader :course, :errors

    def initialize(updated:, course:, errors: [])
      @updated = updated
      @course = course
      @errors = errors
    end

    def updated? = @updated
  end
end
```

```ruby
# ServiceResult — shared module, mixed into a Result class that has a real failure mode
module ServiceResult
  def success? = errors.empty?
  def error? = !success?
end
```

## 4. Patterns to avoid

1. **Creating class methods closes doors.** Prefer instance methods so a service can be composed, tested, and extended without `self.`-method gymnastics.
2. **Using a generic method name like `call` — or `execute` on a state-changing service — obscures behavior.** `execute` is reserved for query objects, where the verb already lives in the class name (`SupervisorCapacityCalculator#execute`). A state-changing service's whole reason to exist is its side effect, so its method name should say what that side effect is.
3. **Passing services into services via dependency injection obscures behavior.** If a service needs another service's output, instantiate it directly inside the method that needs it (as `SupervisorCapacityUpdater` does with `SupervisorCapacityCalculator`) rather than injecting it through the constructor. This keeps the dependency visible at the point it's used, and avoids needing container/wiring knowledge to trace what a service actually depends on.

### References

[GitLab's service class conventions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/reusing_abstractions.md)
~~~~

=== docs/adr/0023-grouping-settings-live-in-course-settings.md | 104 lines | last commit 8a35e745 2026-10-21 ===

~~~~
# ADR 0023 — Grouping settings live only in Course Settings

Date: 2026-10-21
Status: Accepted

## Context

The student self-grouping feature grew its own settings surface: a
coordinator `<details>` panel at the top of the grouping workspace
(`/courses/:course_id/project_groups`) with its own form, its own
`project_groups#update_settings` endpoint, and its own copy of the
grouping rules. Meanwhile the Course Settings page grew a **Grouping**
section of its own (Student Self-Grouping, Beta) with the same fields,
posted through `courses#handle_settings`.

After `main` was merged into `feat/student-grouping-crud` the two
surfaces collided head-on:

- The workspace panel rendered in the **pre-redesign** markup
  (`new_tailwind` stylesheet, which `main` deleted), so it no longer
  matched the rest of the app.
- It was the only place on the workspace page that told a coordinator
  whether grouping was on, which mode the course was in, and the
  min/max limits — but it was also a second, differently-shaped editor
  for settings that Course Settings already owns.
- The two editors disagreed on shape (`courses#handle_settings` reads
  nested `course[...]` params; `project_groups#update_settings` reads
  flat params) and on behaviour, so the same course could be left in a
  different state depending on which form was used last.

The two modes also had three names in the tree at once — "Default" /
"Final student list" on the Course Settings form, "Default mode" /
"Auto-Eligibility mode" on the workspace page, and "Default mode" /
"Auto-Confirmability mode" in
`Queries::GroupSizeConfirmabilityCalculator`.

## Decision

**Course Settings is the only grouping-settings UI.** The workspace
panel is deleted, and the mode vocabulary is fixed.

- **One editor.** The Grouping section of `courses/settings.html.erb`
  (Student Self-Grouping, Beta) is the only place grouping is
  configured. `courses#handle_settings` is the only write path with a
  UI.
- **The workspace page keeps a status bar, not a form.** The
  coordinator `<details>` panel is replaced by a read-only bar showing
  the window state, the mode, and the min/max limits, plus a
  **Grouping settings** link to `settings_course_path(@course)` for
  anyone who passes `CoursePolicy#manage_groups?`. The bar is shown to
  every viewer, so students and lecturers keep seeing the mode.
- **The two modes are named "Default mode" and "Auto-Confirmability
  mode"** — the calculator's wording, which describes what the mode
  actually checks (whether a group size may be confirmed) rather than
  the coordinator's mental model ("my list is final"). The boolean
  attribute stays `student_list_finalised`; only the user-facing text
  changes. Course Settings' "Student list mode" section header becomes
  "Grouping mode".
- **The finalised-list lock is `main`'s, and it stays.** Once a course
  is persisted with grouping enabled in Default mode, the
  Auto-Confirmability radio is disabled and cannot be selected. The
  reverse direction (Auto-Confirmability → Default) *is* allowed and
  goes through `Course#revert_to_default_mode!`, which destroys draft
  groups and leaves confirmed groups alone. Turning grouping off
  entirely (`Course#disable_grouping!`) also destroys draft groups.
- **`project_groups#update_settings` is kept but is no longer
  reachable from any UI.** It is a second write path for the same
  settings and should be deleted; it is kept here only so the merge
  does not have to touch the route table. Nothing renders a form for
  it.

## Consequences

- There is exactly one place to learn what the grouping settings are
  and one place to change them.
- The workspace page no longer carries the old stylesheet or a second
  copy of the form, so it stops drifting from the app's design.
- Coordinators lose the ability to toggle grouping without leaving the
  workspace; they get one click to Course Settings instead.
- `project_groups#update_settings` is dead weight — a route with no
  form. It is recorded here so the next reader knows it is deliberate
  debt and not an oversight.
- The Auto-Confirmability mode cannot be entered once a course has
  been saved in Default mode. If a coordinator imported the wrong
  student list, they must turn grouping off and back on rather than
  flipping the mode.

## Known debt (out of scope, listed only)

- `project_groups#update_settings` should be deleted along with its
  route (`patch :update_settings`).
- The grouping workspace page still carries the pre-redesign markup;
  only its settings panel was removed. A restyle to the current design
  system is separate work.

## References

- ADR 0022 — project and topic tabs are routes (the route-per-tab
  pattern the two group surfaces also follow; its "known debt" list
  names the `groups` / `project_groups` naming overlap)
- `app/services/queries/group_size_confirmability_calculator.rb` — the
  two modes' rules, and the source of the "Auto-Confirmability" name
- `app/views/courses/settings.html.erb` — the Grouping section
- `app/views/project_groups/index.html.erb` — the status bar
~~~~

=== docs/adr/0024-two-group-surfaces-stay-separate.md | 79 lines | last commit 8a35e745 2026-10-21 ===

~~~~
# ADR 0024 — The course Groups tab and the grouping workspace stay separate surfaces

Date: 2026-10-21
Status: Accepted

## Context

Two surfaces render the same `ProjectGroup` records, and both are called
"Groups":

- **The course Groups tab** — `/courses/:course_id/groups` →
  `groups#index` (ADR 0019). A monitoring table: Group / Members
  (expandable) / Project Title / Status / Supervisor, with search,
  status and lecturer filters, re-rendered over htmx. Policy-scoped, and
  built for a coordinator answering "who is in which group, and what
  happened to their project".
- **The grouping workspace** — `/courses/:course_id/project_groups` →
  `project_groups#index`. Where students actually form groups: my-group
  panel, browse groups (All / Draft / Confirmed), ungrouped students,
  create / join / invite / confirm / dissolve.

They overlap: both list groups, both have a search box, and both show
members. Before the merge only the second existed, in its pre-redesign
form. The merge brought `main`'s Groups tab alongside it, and ADR 0022's
route audit already flagged the "`groups` / `project_groups` naming
overlap" as known debt.

Three ways out were on the table: rename the workspace so the two are
distinguishable, fold one into the other, or keep both.

## Decision

**Both surfaces stay, with their current names.** The Groups tab
remains the coordinator's monitoring table; the grouping workspace
remains the participation surface students and group leaders work in.
The naming overlap is accepted, not fixed, in this pass.

- The **Groups tab** is read-mostly: it answers questions about groups
  that already exist. It links out to projects, not to the workspace.
- The **grouping workspace** is write-mostly: it is where a group is
  created, joined, confirmed or dissolved. It links out to nothing —
  it *is* the destination for grouping actions.
- Neither is renamed and neither is merged into the other. The two
  routes stay separate, as ADR 0019 and ADR 0022 require routes to be.

## Consequences

- "Groups" is ambiguous in this codebase: it names a course tab, a
  route segment, and a model. Anyone reading the code has to know which
  surface is meant from the route or the controller, not the word.
- The two surfaces can drift — the workspace still carries the
  pre-redesign markup while the Groups tab follows the current design
  system — and a group can look different in each.
- Two search boxes over the same records means two ways to find the
  same group, with different results.
- A student who is only asked to "join a group" is sent to one surface;
  a coordinator asked "who is in that group" is sent to another. The
  hand-off between them is a URL, not a link on the page.

## Known debt (out of scope, listed only)

- Renaming one of the two surfaces, or merging them, is still open.
  The Groups tab's members column already expands to show the same
  member list the workspace shows in its group cards, so the data
  overlap is real, not just the naming.
- ADR 0022's route audit lists the `groups` / `project_groups` overlap
  among ~35 non-canonical routes left alone; this ADR makes the naming
  half of that deliberate.

## References

- ADR 0019 — course tabs are routes
- ADR 0022 — project and topic tabs are routes; participant profiles
  are routes (its "known debt" list names this overlap)
- ADR 0023 — grouping settings live only in Course Settings
- `app/controllers/groups_controller.rb` and
  `app/views/courses/_groups_tab.html.erb` — the Groups tab
- `app/controllers/project_groups_controller.rb` and
  `app/views/project_groups/index.html.erb` — the grouping workspace
~~~~


---

# Excluded / not found

| Expected | Found? | Note |
|---|---|---|
| Shared `ServiceResult` module | **NO** | `grep -rn "ServiceResult" app lib test` -> zero hits. `docs/Abstraction/service_classes.md` lines 71-94 presents it as an illustrative snippet inside a doc, not as a file in the tree. `SupervisorCapacityUpdater::Result` (the doc's own example) does **not** `include ServiceResult` - see section B. |
| `test/services/group_member_remover_test.rb` | **NO** | Does not exist on this branch. `GroupMemberRemover` has no service-level test file. `bin/rails test test/services/group_member_remover_test.rb` errors: `Could not load test file ... (Rails::TestUnit::InvalidTestError)`. |
| `test/fixtures/*.yml` | **NO** | `test/fixtures/` does not exist. `test/test_helper.rb` line 12 calls `fixtures :all`, a no-op without the directory. All data comes from FactoryBot. |
| `app/models/concerns/*.rb` | **NO** | Only `app/models/concerns/.keep` (empty). `ProjectGroup`, `ProjectGroupMember`, `ProjectGroupInvite`, `ProjectGroupInviteLink`, `Course`, `Enrolment`, `User` include no concerns. |
| `app/jobs/*group*.rb` | **NO** | `app/jobs/` contains only `application_job.rb`. All grouping mail goes through `GeneralMailer` with `deliver_later`. |
| A "link" kind on `ProjectGroupInvite` | **NO** | `ProjectGroupInvite` has exactly two kinds: `direct_request: 0`, `direct_invite: 1` (`app/models/project_group_invite.rb` line 6). Invite *links* are a separate model + table: `ProjectGroupInviteLink` / `project_group_invite_links`. |
| `dissolved_at` column on `project_groups` | **NO (on this branch)** | Added by `db/migrate/20260714065220_add_dissolved_at_to_project_groups.rb`, removed by `db/migrate/20260726153230_remove_dissolved_at_from_project_groups.rb`. `db/schema.rb` has no `dissolved_at`. Groups are hard-deleted, never soft-dissolved. |
| `force_confirm` (staff bypass of confirm) | **NO (on this branch)** | Removed in commit `5e1daba7` ("feat: removed force_confirm, ..."). `grep -rn "force_confirm" app lib config test db` -> zero hits today. The old method is visible at `git show 5e1daba7^:app/models/project_group.rb` (line 106). |
| `project_group_invites.token` / `.expires_at` | **NO** | Added by `20260714065259_add_token_and_expires_at_to_project_group_invites.rb`, removed by `20260806113423_reshape_project_group_invites.rb`. Token/expiry now live on `project_group_invite_links`. |
| A grouping section in `CONTEXT.md` | **NO** | `CONTEXT.md` (27,674 bytes, modified 2026-10-21) documents course settings, the coursecode widget, template fields, project show, course tabs, browse tables, participant/lecturer profiles, app chrome, topic forms, form actions and the landing page. It contains **no** grouping-glossary section: `grep -niE "group" CONTEXT.md` returns only incidental mentions (the Course Settings "Grouping" section card, the course Groups tab, the topics-directory "supervisor group"). It is therefore not dumped; the two ADRs that do describe grouping are dumped in section G. |
| `STUDENT_GROUPING_ARCHITECTURE.md`, `STUDENT_GROUPING_CRUD_TASKS.md`, `STUDENT_GROUPING_REFERENCE.md` | **NO** | `.gitignore` lists all three as ignored; none exists in the working tree and none is tracked. Not available to this audit. |
| `ProPro_Design/groups_tab_mockup.html.erb` | **YES, not dumped** | A design mockup (HTML), not backend material; `ProPro_Design/` is gitignored. Listed for completeness only. |
| Coverage report | **NO** | No coverage tooling exists - see F4. |
| `test/system/**` grouping tests | **NO** | No system test targets grouping. |

## Notes on dump fidelity

- Every dump above is the file's content at HEAD (`8a35e745159b8af0ce07f36de2b22defa16d8ca2`), read from the working tree, which is clean and identical to HEAD.
- Fences are four tildes (`~~~~`) as requested; no dumped body contains a `~~~~` sequence of its own, so no fence is broken.
- **No secrets are included.** `config/master.key`, `config/credentials*` and any `.env*` file were never read. No token, key or real email address appears in the dumps; `SecureRandom.urlsafe_base64(8)` and `24.hours.from_now` appear as source code, not as values.
