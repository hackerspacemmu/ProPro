# Grouping backend - audit

**Purpose:** the analysis behind a refactor of the student-grouping backend - the
`Queries::` / `Group::` namespace question, the service-convention cleanup, and the
correctness review of the grouping services, controllers and policies.

**This file makes claims; the evidence lives elsewhere.** Every claim below is
labelled **FACT** (read directly off the source at the cited lines) or **INFERENCE**
(a conclusion drawn from those facts), and cites `file:line`.

**Companion files**

| File | What it holds |
|---|---|
| `docs/grouping_backend_dump.md` | verbatim dumps of all 11 grouping services, the reference implementations, 11 models, 24 test files, 7 factories, 15 migrations, the grouping schema excerpt, raw test output, and the convention docs |
| `docs/grouping_backend_raw_search.md` | the eight raw grep outputs, the branch's grouping commit history, and the schema/migration state |

**Date of capture:** 2026-10-21 22:14:22 +0800
**HEAD commit date:** 2026-10-21 16:29:08 +0800
**Current branch:** `feat/student-grouping-crud`
**HEAD sha:** `8a35e745159b8af0ce07f36de2b22defa16d8ca2`
**Base branch:** `main` (= `origin/main`) at `98ca0a9b52d4551bc85265535b7e22acde01717a`
(this is also the merge base with HEAD - the branch is 89 commits ahead of main and 0 behind).
**Working tree:** no tracked file is modified; the only untracked files are the audit
documents in `docs/`.

## Table of contents

| Section | Lines |
|---|---|
| B - where grouping data is written | 64 |
| C - service-convention conformance | 128 |
| D - correctness answers (Q1-Q19) | 431 |
| E - test cross-reference | 96 |
| **Total (Parts B-E)** | **719** |

---

## How to read this audit

- **Part B** is a map: every write to a grouping table, with the lock it runs inside.
  Read it first - it shows how little of the feature goes through the service layer.
- **Part C** checks the eleven grouping services against
  `docs/Abstraction/service_classes.md`. It separates *documented* violations from
  *team preferences* (the `Group::` namespace is a preference, not a rule).
- **Part D** answers nineteen questions about the behaviour of the feature. Each
  answer is labelled FACT or INFERENCE and cites `file:line`.
- **Part E** maps each answer to the test that already documents it, lists the seven
  tests that pin today's behaviour, and lists what is not covered at all.

**Scale:** 11 grouping services (760 lines), 4 grouping-specific models plus 7
supporting ones (543 lines), 4 grouping controllers plus `EnrolmentsController`,
4 grouping policies, 22 test files, 8 grouping migrations added on this branch,
79 branch commits touching grouping.

---

# Part B. Where grouping data is written

Every `create` / `update` / `destroy` of a `project_groups`, `project_group_members`,
`project_group_invites` or `project_group_invite_links` row, on this branch, with the
transaction/lock it runs inside.

**FACT** - the "Locked?" column is read off the source: `with_lock` opens its own
transaction and takes a row lock on the group's row; `ActiveRecord::Base.transaction`
is a transaction with no row lock; "none" means the write runs in whatever transaction
the caller happened to be in (usually none - these are controller actions).

| # | Where | What is written | Locked? | Notes |
|---|---|---|---|---|
| B1 | `app/services/group_creator.rb:31-36` | `project_groups.create!` - `leader_id`, `course_group_sequence`, `group_name` | `with_lock` on the **course** (`:11`) | sequence = `maximum(:course_group_sequence).to_i + 1`; name = `G%03d` |
| B2 | `app/services/group_creator.rb:37` | `project_group_members.create!` (the leader) | `with_lock` on the course | no enrolment check on the leader (see Q11) |
| B3 | `app/services/group_joiner.rb:18` | `project_group_members.create!` (the joiner) | `with_lock` on the **group** (`:9`) | window / already-grouped / confirmed / locked / full all checked inside the lock |
| B4 | `app/services/group_joiner.rb:27-31` | `project_group_invites.destroy_all` - the joiner's own pending `direct_request`s | inside the group lock | scoped to `sender_id = joiner` only - incoming `direct_invite`s are **not** cleared (see Q17) |
| B5 | `app/services/group_member_adder.rb:13-14` | **reads** - `already_grouped?`, `group_full?` | **none - before the lock** | the capacity read happens outside the lock (`:16`), so it can be stale (see Q12) |
| B6 | `app/services/group_member_adder.rb:17` | `project_group_members.create!` | `with_lock` on the group | the write is locked, but the capacity decision that allowed it was not |
| B7 | `app/services/group_member_remover.rb:20` | `@member.destroy!` | `with_lock` on the group (`:11`) | |
| B8 | `app/services/group_member_remover.rb:30` | `@group.update!(confirmed: false)` - revert to draft | inside the group lock | only for a self-leave or an illegal resulting size |
| B9 | `app/services/group_member_remover.rb:62` | `@group.update!(leader_id:)` - leader succession | inside the group lock | successor = earliest `project_group_members.created_at` |
| B10 | `app/services/group_member_remover.rb:66-68` | `project_group_invites.destroy_all`, `project_group_invite_links.destroy_all`, `@group.destroy!` - **dissolution** | inside the group lock | `@group.destroy!` cascades into the group's project (see Q2) |
| B11 | `app/services/group_confirmer.rb:17` | `@group.update!(confirmed: true)` | `with_lock` on the group (`:9`) | window + legality checked inside the lock |
| B12 | `app/services/group_reverter.rb:14` | `@group.update!(confirmed: false)` | `with_lock` on the group (`:8`) | window checked inside the lock |
| B13 | `app/services/group_direct_inviter.rb:21-27` | `project_group_invites.create!` (`kind: :direct_invite`) | **none** | `RecordNotUnique` / `RecordInvalid` rescued at `:32` |
| B14 | `app/services/group_direct_inviter.rb:29` | `GeneralMailer...deliver_later` | none | mail enqueued inside the service |
| B15 | `app/services/group_direct_requester.rb:19-25` | `project_group_invites.create!` (`kind: :direct_request`) | **none** | no capacity check at all on this path |
| B16 | `app/services/group_direct_requester.rb:27` | `GeneralMailer...deliver_later` | none | |
| B17 | `app/services/group_invite_link_generator.rb:17` | the same sender's old `project_group_invite_links` row `destroy!` | `with_lock` on the group (`:16`) | only the *same* sender's link is destroyed |
| B18 | `app/services/group_invite_link_generator.rb:19-23` | `project_group_invite_links.create!` (`token`, `expires_at: 24.hours.from_now`) | inside the group lock | |
| B19 | `app/services/group_invite_link_redeemer.rb:24` | `project_group_members.create!` | `with_lock` on the group (`:16`) | |
| B20 | `app/services/group_invite_link_redeemer.rb:37-43` | `project_group_invites.destroy_all` - pending invites where the redeemer is sender **or** recipient, course-wide | inside the group lock | |
| B21 | `app/services/group_invite_responder.rb:27-29` | `project_group_members.create!`, `@invite.update!(status: :accepted)`, `project_group_invites.destroy_all` | `with_lock` on the group (`:15`) | the accepted invite is set to `accepted` **before** the `destroy_all`, so it survives |
| B22 | `app/services/group_invite_responder.rb:31` | `GeneralMailer...deliver_later` | **inside the group lock** | mail enqueued while holding the group row lock |
| B23 | `app/services/group_invite_responder.rb:40` | `@invite.update!(status: :declined)` | **none** | decline runs outside any lock |
| B24 | `app/controllers/enrolments_controller.rb:20` | calls `GroupMemberRemover#remove!` with `dissolve_confirmed: true` | the service opens its own lock | the confirmation warning is skipped (see Q15) |
| B25 | `app/controllers/enrolments_controller.rb:29` | `enrolment.destroy!` | **separate transaction** | not atomic with B24 (see Q1) |
| B26 | `app/controllers/project_groups_controller.rb:52` | `@group.destroy!` (coordinator dissolves a group) | `ActiveRecord::Base.transaction` (`:51`) | same cascade as B10 |
| B27 | `app/controllers/project_groups_controller.rb:107` | `@group.update!(locked: true)` | none | policy-gated only (`ProjectGroupPolicy#lock?`) |
| B28 | `app/controllers/project_groups_controller.rb:118` | `@group.update!(locked: false)` | none | policy-gated only |
| B29 | `app/controllers/project_groups_controller.rb:130` | `@group.update!(leader_id:)` (promote leader) | none | policy-gated only; no service, no lock, no legality check |
| B30 | `app/controllers/project_groups_controller.rb:148` | `@course.disable_grouping!` -> destroys every **draft** group | `transaction` inside `Course` (`app/models/course.rb:84-87`) | confirmed groups survive; draft groups (and their projects) are destroyed |
| B31 | `app/controllers/project_groups_controller.rb:151` | `@course.revert_to_default_mode!` -> destroys every **draft** group | `transaction` inside `Course` (`app/models/course.rb:93-96`) | same shape as B30 |
| B32 | `app/controllers/project_groups_controller.rb:155-163` | `@course.update!` - `grouping_enabled`, `student_list_finalised`, `group_min`, `group_max`, `grouping_open`, `grouping_opens_at`, `grouping_closes_at` | `transaction` (`:142`) | flat `params`, manual whitelist, no strong parameters (see Q9) |
| B33 | `app/controllers/courses_controller.rb:246-254` | `@course.update!` - the same seven grouping attributes (plus the rest of the course settings, written in the earlier `update(` at `:217-234`) | `transaction` (`:216`) | manual whitelist; the grouping branch is reached only when grouping stays enabled (`:241-245`, see Q9) |
| B34 | `app/controllers/courses_controller.rb:449` | `ProjectGroup.find_or_create_by!(group_name:, course:)` - **CSV import** | none | the imported group gets **no** `course_group_sequence` (see Q4) |
| B35 | `app/controllers/courses_controller.rb:480` | `Enrolment.find_or_create_by!` - CSV import | none | |
| B36 | `app/controllers/courses_controller.rb:491-492` | `project_group_members.update!(project_group:)` / `.create!` - CSV import | none | an import **moves** an existing member to the imported group (`:491`) |
| B37 | `app/models/course.rb:191-195` | `destroy_draft_groups` -> `group.destroy!` per draft group | inside the caller's transaction | the only place draft groups are bulk-deleted |
| B38 | `app/models/user.rb:19` | `has_many :project_group_members, dependent: :destroy` | - | deleting a user silently removes their memberships |
| B39 | `app/models/project_group.rb:2,6,7,8` | `dependent: :destroy` on members, **project**, invites, links | - | the group -> project cascade is the root of Q2 |
| B40 | `app/models/project.rb:9,10` | `project_instances` and `progress_updates` `dependent: :destroy` | - | |
| B41 | `app/models/project_instance.rb:9,17` | `comments` and `project_instance_fields` `dependent: :destroy` | - | |

**INFERENCE** - the four controller-level writes that bypass the service layer
(B27, B28, B29, B34-B36) are the only grouping mutations with no Result object, no
business-rule checks and no lock. Every one of them is reachable only through a
Pundit policy check, which is why the rules still hold in practice - but the rules
live in the policy, not in the model, and a second caller of the same model method
would get no rules at all.

---

# Part C. Service-convention conformance

The convention being audited is `docs/Abstraction/service_classes.md` (dumped verbatim
in `docs/grouping_backend_dump.md`, section G). Its rules, in short:

- **R1 (initializer)** - the model being acted on is the first positional argument;
  `current_user:` is *data only*, never the way the service decides whether the action
  is allowed; extra data arrives as explicit keyword arguments; no preemptive
  `params:`/`options:` hashes.
- **R2 (naming)** - query objects expose a single `#execute`; state-changing services
  expose an explicit bang-verb instance method (`confirm!`, `remove!`), never `call` or
  `execute`.
- **R3 (result)** - return a rich `Result` object, never a bare boolean; `success?` /
  `error?` only on a Result that really has a second outcome.
- **R4 (avoid)** - no class methods; no generic `call`; no service-to-service injection
  through the constructor.
- **R5 (queries)** - query objects live in `app/services/queries` under `module Queries`.

## C.1 Summary table

| Service | R1 model first | R1 `current_user:` is data only | R2 bang-verb instance method | R3 rich Result | R4 no class methods | Query object? |
|---|---|---|---|---|---|---|
| `GroupCreator` | yes | **no** - it decides self-vs-coordinator from `current_user` (`:22-24`) and gates the window on it (`:13`) | yes `create!` | yes | yes | no (it writes) |
| `GroupJoiner` | yes | yes | yes `join!` | yes | yes | no (it writes) |
| `GroupMemberAdder` | yes | **no** - `current_user:` is accepted and never read | yes `add!` | yes | yes | no (it writes) |
| `GroupMemberRemover` | yes | **no** - it re-derives self-leave / leader-kick from `current_user` (`:40-46`) | yes `remove!` | yes | yes | no (it writes) |
| `GroupConfirmer` | yes | n/a - no `current_user:` | yes `confirm!` | yes | yes | no (it writes) |
| `GroupReverter` | yes | n/a - no `current_user:` | yes `revert!` | yes | yes | no (it writes) |
| `GroupDirectInviter` | yes | yes (sender) | yes `invite!` | yes | yes | no (it writes) |
| `GroupDirectRequester` | yes | yes (requester) | yes `request!` | yes | yes | no (it writes) |
| `GroupInviteLinkGenerator` | yes | yes (link owner) | yes `generate!` | yes | yes | no (it writes) |
| `GroupInviteLinkRedeemer` | yes | yes (redeemer) | yes `redeem!` | yes | yes | no (it writes) |
| `GroupInviteResponder` | yes | yes (responder) | yes `accept!` / `decline!` | yes | yes | no (it writes) |
| `Queries::GroupSizeConfirmabilityCalculator` | yes | n/a | yes `#execute` | yes | yes | **yes** (R5 satisfied) |
| `Queries::SupervisorCapacityCalculator` | yes | n/a | yes `#execute` | yes | yes | **yes** (R5 satisfied) |
| `SupervisorCapacityUpdater` | yes | n/a | yes `update!` | yes | yes | no (it writes) |

**FACT** - all eleven grouping services are flat classes in `app/services/`
(`app/services/group_creator.rb:3` and siblings). They are **not** namespaced.

**INFERENCE** - the convention document does **not** require a namespace for
state-changing services; it only mandates `module Queries` for query objects (R5,
`docs/Abstraction/service_classes.md:9`). So "the grouping services are not in a
`Group::` namespace" is a *team preference*, not a documented violation. If a
`Group::` namespace is wanted, it is a rename decision, not a conformance fix.

## C.2 Rule-by-rule notes

**R1 - `current_user:` used as an authorization gate.** Three services decide
*permission-shaped* questions from `current_user` inside the service:

- `GroupCreator#self_create?` (`app/services/group_creator.rb:22-24`) compares
  `@leader.id == @current_user.id` and the result gates the window check
  (`:13`). The document says authorization "is never how the service decides whether
  the action is allowed" (doc `:17`).
- `GroupMemberRemover#self_leave?` / `#leader_kick?`
  (`app/services/group_member_remover.rb:40-46`) re-derive who is removing whom.
  The controller *also* authorizes (`app/controllers/project_group_members_controller.rb:27`),
  so the rule exists twice, in two places, with two different definitions.
- `GroupCreator` additionally accepts a leader that has no enrolment in the course
  (`app/services/group_creator.rb:37` creates the membership with no enrolment check).

**FACT** - `GroupMemberAdder` takes `current_user:` (`app/services/group_member_adder.rb:4`)
and stores it (`:7`) but never reads it again. The convention says not to pass
`current_user:` when the service has no use for it (doc `:18`).

**R1 - the `dissolve_confirmed:` mode parameter.** `GroupMemberRemover` takes
`dissolve_confirmed: false` (`app/services/group_member_remover.rb:3`) and uses it to
*skip* the last-member confirmation branch (`:17`). The same operation therefore has
two behaviours selected by a boolean flag, and the flag is set to `true` by a caller
that shows no warning (`app/controllers/enrolments_controller.rb:20`).

**R3 - Result objects.** Every grouping service returns a nested `Result` class with a
`blocked_reason` and a `message`. Two inconsistencies:

- `GroupConfirmer::Result` (`app/services/group_confirmer.rb:28-46`) exposes
  `confirmed?` but **no** `blocked?` predicate, while every sibling Result exposes
  `blocked?`.
- `GroupMemberRemover::Result` (`:79-112`) uses an `outcome` enum
  (`:dissolved` / `:reverted` / `:needs_confirmation` / `:blocked` / `:unchanged`)
  instead of the `blocked_reason` + boolean shape the other ten use. Callers must
  branch on four different predicates.

**FACT** - the shared `ServiceResult` module shown in the convention document
(`docs/Abstraction/service_classes.md:88-92`) **does not exist** in this repository:
`grep -rn "ServiceResult" app lib test` returns zero hits. Each Result class
therefore re-implements its own `success?`/`error?`-style predicates by hand.

**R4 - no class methods.** All eleven services use instance methods only; the two
query objects use `#execute`; no service uses `call` or `execute`. **This rule is fully
satisfied.**

**R4 - service-to-service injection.** No grouping service takes another service in
its constructor. `ProjectGroup#confirmable?` (`app/models/project_group.rb:26-31`)
instantiates `Queries::GroupSizeConfirmabilityCalculator` directly, which is the
pattern the document asks for (doc `:100`) - but it puts a *service* behind a *model*,
which the document does not cover either way.

**Business rules that sit in the wrong layer.** Three places re-implement group-size
rules instead of asking the one query object that owns them
(`app/services/queries/group_size_confirmability_calculator.rb`):

| Rule | Duplicated in | Form |
|---|---|---|
| "is this group full?" | `app/services/group_member_adder.rb:25`, `app/services/group_direct_inviter.rb:39`, `app/services/group_invite_link_redeemer.rb:34`, `app/services/group_invite_responder.rb:49` | `course.group_max.present? && members.count >= course.group_max` |
| "is this group full?" (a **different** form) | `app/services/group_joiner.rb:16` | `members.count >= course.group_max.to_i` - nil becomes 0, so a nil `group_max` means "full" here and "unlimited" in the four services above |
| "is this size legal?" | `app/models/project_group.rb:26-31` (delegates to the query object - correct) | - |
| "may this user join?" | `app/services/group_direct_inviter.rb:13-15` (recipient must be an enrolled student) | re-derives a rule that belongs in a policy - `ProjectGroupPolicy#direct_invite?` (`app/policies/project_group_policy.rb:71-73`) only checks that the caller is the leader |

**FACT** - `GroupInviteLinkRedeemer`'s header comment
(`app/services/group_invite_link_redeemer.rb:3-4`) states that the enrolment/role
check lives in `ProjectGroupInviteLinkPolicy#redeem?` - that is the convention being
followed correctly, and it is the one place the codebase gets it right.

**FACT** - `GroupDirectRequester` has **no capacity check at all**: a student can
request to join a full locked group (`app/services/group_direct_requester.rb:10-32`).
The request is only turned into a membership by `GroupInviteResponder#accept!`, which
does check capacity (`app/services/group_invite_responder.rb:25`).

**User-facing strings inside services.** Every grouping service embeds its own English
copy in `Result#message` (for example `app/services/group_joiner.rb:52-58`). The same
sentence is repeated across services - "The grouping window is closed." appears in
`GroupCreator`, `GroupJoiner`, `GroupMemberRemover`, `GroupConfirmer`, `GroupReverter`,
`GroupDirectInviter`, `GroupInviteLinkGenerator`, `GroupInviteLinkRedeemer` and
`GroupInviteResponder`. There is no i18n layer and no shared message source.

---

# Part D. Correctness answers

Each answer is labelled **FACT** (read directly off the code at the cited lines) or
**INFERENCE** (a conclusion drawn from those facts).

## Q1. Is removing a student's enrolment atomic?

**FACT** - no. `EnrolmentsController#destroy` performs two independent writes:

1. `app/controllers/enrolments_controller.rb:20` -
   `GroupMemberRemover.new(group_member, current_user:, dissolve_confirmed: true).remove!`.
   The service opens its own transaction via `@group.with_lock`
   (`app/services/group_member_remover.rb:11`) and commits it.
2. `app/controllers/enrolments_controller.rb:29` - `enrolment.destroy!`, in a separate
   transaction.

**INFERENCE** - if `enrolment.destroy!` raises (a foreign-key or validation failure),
the group membership removal is already committed and is **not** rolled back: the
student stays in the group with no enrolment. If the service call fails first (`:22-25`
returns early), the enrolment is never touched. The controller's `rescue
ActiveRecord::RecordNotFound` (`:31`) does not cover either case.

## Q2. What happens to a group's proposal and comment data when the group dissolves?

**FACT** - it is deleted. The chain is:

- `app/models/project_group.rb:6` - `has_one :project, dependent: :destroy, as: :owner`
- `app/models/project.rb:9` - `has_many :project_instances, dependent: :destroy`
- `app/models/project.rb:10` - `has_many :progress_updates, dependent: :destroy`
- `app/models/project_instance.rb:9` - `has_many :comments, as: :location, dependent: :destroy`
- `app/models/project_instance.rb:17` - `has_many :project_instance_fields, dependent: :destroy`

The two entry points are `app/services/group_member_remover.rb:68` (`@group.destroy!`)
and `app/controllers/project_groups_controller.rb:52` (`@group.destroy!`).

**INFERENCE** - every proposal version, every comment on it, every progress update and
every submitted field value for that group is destroyed with the group. There is no
soft-delete, no archive, and no `dissolved_at` marker on this branch (the column was
added in `20260714065220` and removed again in `20260726153230`).

## Q3. How is "one group per student per course" enforced?

**FACT** - in application code only, inside each service, and never by the database:

- `app/services/group_creator.rb:27` - `already_grouped?` -> `blocked(:already_grouped)`
- `app/services/group_joiner.rb:13` - same check
- `app/services/group_member_adder.rb:13` - same check
- `app/services/group_direct_inviter.rb:19` - same check for the invite recipient
- `app/services/group_direct_requester.rb:14` - same check for the requester
- `app/services/group_invite_link_redeemer.rb:22` - same check
- `app/services/group_invite_responder.rb:23` - same check for the joining user

**FACT** - `db/schema.rb:119-126`: `project_group_members` has exactly two indexes,
`index_project_group_members_on_project_group_id` (`:124`) and
`index_project_group_members_on_user_id` (`:125`). **Neither is unique**, and there is
no index at all on `(user_id, course_id)` - the pair that actually has to be unique.

**INFERENCE** - the check and the insert are not atomic at the database level, so two
concurrent joins into two *different* groups of the same course can both pass the
`already_grouped?` check and both insert: `GroupJoiner` locks the *target group*
(`app/services/group_joiner.rb:9`), not the user or the course, and the two locks are
on different rows. A student can end up in two groups of the same course. The
"concurrent joins on last slot" test (`test/services/group_joiner_test.rb:100`) covers
the same-group case and passes, because the group row lock serialises it; the
different-group case has no test and no protection.

## Q4. How are group numbers allocated, and can they collide or be reused?

**FACT** - `app/services/group_creator.rb:31`:
`@course.project_groups.maximum(:course_group_sequence).to_i + 1`, inside
`@course.with_lock` (`:11`), stored as `course_group_sequence` and formatted into the
name `G%03d` (`:35`). The database has a unique index on
`(course_id, course_group_sequence)` (`db/schema.rb:137`).

**FACT** - three consequences follow:

1. **CSV-imported groups get no sequence.** `app/controllers/courses_controller.rb:449`
   creates groups with `ProjectGroup.find_or_create_by!(group_name:, course:)` and
   never sets `course_group_sequence`, so the column is `NULL`.
   `maximum(:course_group_sequence)` ignores `NULL` rows, so an auto-created `G001`
   can exist alongside an imported group named `G001`.
   `test/services/group_creator_test.rb:95` documents exactly this
   ("auto-generated group_name silently duplicates an existing CSV-imported group_name").
2. **Numbers are reused after dissolution.** Dissolving a group hard-deletes the row
   (`app/services/group_member_remover.rb:68`), so the next `maximum` returns the same
   value and the number is handed out again.
3. **`RecordNotUnique` is not rescued here.** `GroupDirectInviter` and
   `GroupDirectRequester` rescue it (`app/services/group_direct_inviter.rb:32`,
   `app/services/group_direct_requester.rb:30`); `GroupCreator` does not, so a
   sequence collision surfaces as a 500.

**FACT** - `test/services/group_creator_test.rb:106` ("concurrent self-creates never
collide on course_group_sequence") passes, because the course row lock serialises
creations.

## Q5. How is the grouping window represented and enforced?

**FACT** - it is represented **twice**:

- `app/models/course.rb:74-81` - `grouping_window_open?` combines three things:
  `grouping_enabled?`, the boolean `grouping_open?`, and the optional
  `grouping_opens_at` / `grouping_closes_at` timestamps.
- the boolean `grouping_open` is written directly by the two settings controllers
  (`app/controllers/courses_controller.rb:251`,
  `app/controllers/project_groups_controller.rb:160`) alongside the two timestamps.

**FACT** - `grouping_opens_at` / `grouping_closes_at` are ignored entirely when
`grouping_open` is false, and the timestamps are only a half-open check
(`Time.current >= opens_at` and `Time.current <= closes_at`,
`app/models/course.rb:78-79`), so the closing instant is inclusive.

**INFERENCE** - the two representations can disagree: a course with
`grouping_open = false` and a valid date window is closed; a course with
`grouping_open = true` and no dates is open forever. That is coherent, but it is not
documented anywhere, and the settings UI writes both halves in the same form, so a
coordinator can easily produce "open = false but dates set", which reads as a window
that is silently ignored.

## Q6. What happens when `group_max` is nil?

**FACT** - the code disagrees with itself:

- `app/services/group_joiner.rb:16` - `@group.project_group_members.count >= course.group_max.to_i`.
  `nil.to_i` is `0`, so with a nil `group_max` **every join is blocked as
  `:group_full`**.
- `app/services/group_member_adder.rb:25`,
  `app/services/group_direct_inviter.rb:39`,
  `app/services/group_invite_link_redeemer.rb:34`,
  `app/services/group_invite_responder.rb:49` - all use
  `course.group_max.present? && ...`, so a nil `group_max` means **unlimited**.
- `app/services/queries/group_size_confirmability_calculator.rb:15` - a nil
  `group_min` or `group_max` produces `blank_result(:group_size_limits_not_configured)`,
  and `Result#confirmable_size?` (`:85-92`) returns `false` for a `found? == false`
  result, so **no group can be confirmed**.
- `app/services/group_direct_requester.rb` - no capacity check at all, so a request is
  always allowed.

**FACT** - `app/models/course.rb:50-51` validates that `group_min` and `group_max` are
present whenever `grouping_enabled?` is true, so the nil case is only reachable when
grouping is off (or if validation is bypassed).

**INFERENCE** - with grouping switched off and then on again without limits, the
joiner reports every group as full while the calculator reports every group as
unconfirmable; the "unlimited" reading only exists in four of the six places.

## Q7. What are the invite models, and is there a "link" kind of invite?

**FACT** - there are **two** separate models and tables:

| Model | Table | Kinds / fields |
|---|---|---|
| `ProjectGroupInvite` | `project_group_invites` | `enum :kind, { direct_request: 0, direct_invite: 1 }` (`app/models/project_group_invite.rb:6`), `enum :status, { pending: 0, accepted: 1, declined: 2 }` (`:7`) |
| `ProjectGroupInviteLink` | `project_group_invite_links` | `token`, `expires_at`, `sender` (`app/models/project_group_invite_link.rb:1-4`) - no kind column |

**FACT** - the token/expiry columns used to live on `project_group_invites` and were
moved to the links table by `20260806113423_reshape_project_group_invites.rb`. There is
no third kind, and no `link` kind on `ProjectGroupInvite`.

## Q8. Can staff confirm or revert a group outside the normal rules? Is there a `force_confirm`?

**FACT** - there is no `force_confirm` on this branch:
`grep -rn "force_confirm" app lib config test db` returns zero hits. It was removed in
commit `5e1daba7` ("feat: removed force_confirm, ..."); the old method is visible at
`git show 5e1daba7^:app/models/project_group.rb`.

**FACT** - what *does* exist is a policy-level staff path:

- `app/policies/project_group_policy.rb:20-24` - `confirm?` returns true for
  `manage_groups_policy.manage_groups?` - i.e. any group in the course, not just the
  caller's own.
- `app/policies/project_group_policy.rb:26-30` - `revert?` does the same.
- `app/policies/course_policy.rb:27-29` - `manage_groups?` is true for the
  coordinator, or for a lecturer when `lecturers_can_manage_groups?` is set (the
  column defaults to `true`, `db/schema.rb` courses table).

**FACT** - the service-level window check is *not* bypassed by that path:
`app/services/group_confirmer.rb:12` and `app/services/group_reverter.rb:11` check
`grouping_window_open?` for every caller.

**INFERENCE** - so the "staff bypass" that exists is an *authorization* bypass, not a
*window* bypass: a coordinator (or a lecturer with `lecturers_can_manage_groups`) can
confirm or revert **any** group in the course, including one they do not lead, while
the grouping window is closed is still refused. If the team rule is "no staff bypass of
confirm/revert anywhere", this is where it is broken.

## Q9. How do the two settings endpoints write grouping settings?

**FACT** - there are two, and both write the same seven attributes:

| Endpoint | Where | Whitelisting |
|---|---|---|
| `ProjectGroupsController#update_settings` | `app/controllers/project_groups_controller.rb:138-171` | manual hash of `params[:grouping_*]` (`:155-163`); **no strong parameters**, flat params, no `params.require` |
| `CoursesController#handle_settings` | `app/controllers/courses_controller.rb:208-262` | manual hash of `params[:course][...]` (the course settings at `:217-234`, then the grouping branch at `:241-254`); no strong parameters |

**FACT** - both implement the same three-branch logic:

1. grouping was on and is being turned off -> `@course.disable_grouping!`
   (`app/controllers/project_groups_controller.rb:148`)
2. grouping was on in finalised mode and is being switched back -> `@course.revert_to_default_mode!`
   (`:151`)
3. otherwise -> a single `update!` of all seven attributes (`:155-163`)

**FACT** - `Course#disable_grouping!` (`app/models/course.rb:83-88`) and
`Course#revert_to_default_mode!` (`:92-97`) both call `destroy_draft_groups`
(`:191-195`) inside a transaction, so **draft groups and their projects are destroyed**
when the coordinator turns grouping off or leaves finalised mode. Confirmed groups
survive.

**INFERENCE** - branch 3 means the two endpoints can disagree about what "grouping
settings" are: the Course Settings page sends `params[:course][...]`, the Groups page
sends flat `params[:grouping_...]`. Any new grouping attribute has to be added to
both hashes by hand, and a missing key is silently dropped rather than rejected.

## Q10. Can `student_list_finalised` be switched back and forth?

**FACT** - the "only once" rule is a **view-level** rule only:

- `app/views/courses/settings.html.erb:265` - the "true" radio is rendered only when
  `!@course.student_list_finalised?`; once finalised, the form does not offer the
  option again.
- Nothing in the controllers prevents it: `app/controllers/project_groups_controller.rb:157`
  and `app/controllers/courses_controller.rb:248` assign `student_list_finalised`
  directly from the request.
- `app/models/course.rb:59-60` validates only that it cannot be true while grouping
  is disabled.

**FACT** - switching **true -> false** is handled properly: both controllers call
`revert_to_default_mode!`, which destroys draft groups and keeps confirmed ones
(`app/models/course.rb:92-97`; tests at `test/models/course_grouping_settings_test.rb:128`
and `:140`).

**INFERENCE** - the false -> true transition is enforced only by the browser. A POST
that sets `student_list_finalised=true` directly re-enables finalised mode on a course
that has already been through it, destroying nothing and silently changing the
confirmability model from min/max to quota.

## Q11. Does adding a member require the student to be enrolled in the course?

**FACT** - no. `GroupMemberAdder#add!` (`app/services/group_member_adder.rb:10-20`)
checks only that the user is not already in a group and that the group is not full.
There is no enrolment lookup.

**FACT** - this is deliberate, and the tests say so:
`test/services/group_member_adder_test.rb:79` - "CURRENT BEHAVIOR: coordinator can add
a user with no enrolment in the course at all"; and
`test/services/group_creator_test.rb:86` - "coordinator-create currently succeeds even
when the leader has no enrolment in the course".

**INFERENCE** - a coordinator can therefore place a user who is not enrolled in the
course into one of its groups. That user then appears in the group's member list and
in the group's project, but has no enrolment - the exact state that Q1's failed
`enrolment.destroy!` can also produce.

## Q12. Can a group exceed `group_max`?

**FACT** - yes, through `GroupMemberAdder`. The capacity read happens at
`app/services/group_member_adder.rb:14`, **before** the lock is taken at `:16`, so two
concurrent adds can both read "one slot left" and both insert.
`test/services/group_member_adder_test.rb:60` documents it: "a stale group_full? read
lets add! push the group over its group_max".

**FACT** - the other capacity checks are inside their lock:
`group_joiner.rb:16` (inside `with_lock` at `:9`),
`group_invite_link_redeemer.rb:21` (inside at `:16`),
`group_invite_responder.rb:25` (inside at `:15`),
`group_direct_inviter.rb:18` (no lock at all, but it creates an invite row, not a
membership).

## Q13. Which operations check the grouping window?

**FACT** - the window is checked by `Course#grouping_window_open?`
(`app/models/course.rb:74-81`). Where it is called:

| Operation | Service | Window checked? |
|---|---|---|
| Student creates a group | `group_creator.rb:13` | yes - but only when `self_create?`; a coordinator-placed group skips it (`:13`, `:22-24`) |
| Join a group | `group_joiner.rb:12` | yes |
| Leave a group (self) | `group_member_remover.rb:12`, `:48-50` | yes |
| Leader kicks a member | `group_member_remover.rb:12`, `:48-50` | yes |
| Coordinator removes a member | `group_member_remover.rb:12` | **no** - `requires_window_check?` (`:48-50`) is false for coordinator removals |
| Add a member directly | `group_member_adder.rb` | **no** - no window check anywhere in the service |
| Confirm a group | `group_confirmer.rb:12` | yes (for every caller, staff included) |
| Revert a group to draft | `group_reverter.rb:11` | yes (for every caller) |
| Send a direct invite | `group_direct_inviter.rb:16` | yes |
| Request to join | `group_direct_requester.rb:13` | yes |
| Accept an invite/request | `group_invite_responder.rb:22` | yes |
| Decline an invite/request | `group_invite_responder.rb:37-44` | **no** - deliberately, and tested (`test/services/group_invite_responder_test.rb:151`) |
| Generate an invite link | `group_invite_link_generator.rb:13` | yes |
| Redeem an invite link | `group_invite_link_redeemer.rb:19` | yes |
| Lock / unlock a group | `app/controllers/project_groups_controller.rb:98-124` | policy only (`app/policies/project_group_policy.rb:38-50`) |
| Promote a leader | `app/controllers/project_groups_controller.rb:126-136` | policy only (`app/policies/project_group_policy.rb:52-57`) |
| Destroy a group | `app/controllers/project_groups_controller.rb:47-60` | policy only (`app/policies/project_group_policy.rb:32-36`) |

**INFERENCE** - the window is a *student-facing* rule, not a *staff-facing* rule, and
the services enforce it unevenly: two staff operations (add a member, coordinator
removal) have no window check at all, while four policy-gated controller actions rely
on the policy's own window check rather than a service.

## Q14. What happens to a confirmed group when a member leaves?

**FACT** - `app/services/group_member_remover.rb:29-32`:

```ruby
if @group.confirmed? && (self_leave? || !legal_at_current_size?)
  @group.update!(confirmed: false)
  return Result.new(outcome: :reverted, blocked_reason: nil)
end
```

- A **self-leave** always reverts a confirmed group to draft, even if the remaining
  size is still perfectly legal.
- A **staff removal** reverts only when the remaining size became illegal
  (`legal_at_current_size?` -> `@group.confirmable?`, `:56-58`).

**FACT** - leader succession: `app/services/group_member_remover.rb:19`, `:27`, `:60-63`
- if the leaver was the leader, the successor is the member with the earliest
`project_group_members.created_at`; if no members remain, the group is dissolved
(`:22-25`).

**FACT** - a leader may not kick a member from a confirmed group:
`app/services/group_member_remover.rb:13` blocks with `:group_confirmed`.

**INFERENCE** - the asymmetry between self-leave and staff removal is not explained
anywhere in the code or the tests. It produces a surprising outcome: a student who
leaves a perfectly legal confirmed group silently demotes it to draft, while a
coordinator removing the same student from the same group leaves it confirmed.

## Q15. Is the "removing the last member destroys the project" warning enforced?

**FACT** - the warning exists and is rendered:
`app/controllers/project_group_members_controller.rb:39-46` renders
`project_group_members/dissolve_warning_modal` when the result is
`needs_confirmation?`; the service produces that result at
`app/services/group_member_remover.rb:17` when the group would drop to zero members,
has a project, and `dissolve_confirmed` is false. The modal's confirm button posts
`dissolve_confirmed: true`
(`app/views/project_group_members/_dissolve_warning_modal.html.erb:64`).

**FACT** - the warning is **bypassed** on one path:
`app/controllers/enrolments_controller.rb:20` passes `dissolve_confirmed: true`
unconditionally, so removing a student from the course deletes their group (and its
project, per Q2) with no warning at all.

**FACT** - the confirmation is also only offered when the group **has** a project
(`app/services/group_member_remover.rb:17` requires `@group.project.present?`).

**INFERENCE** - the two paths have the same effect on the data and very different
effects on the user: one shows a modal naming the project that will be deleted, the
other deletes it silently behind a "Student removed from course." notice.

## Q16. How do invite links behave across leader changes, expiry and regeneration?

**FACT** -

- **Leader change:** a link generated by the old leader stays fully valid -
  `app/services/group_invite_link_generator.rb:17` scopes the "destroy my old link"
  to the *same* sender, and the link row is not tied to the leader.
  `test/services/group_invite_link_generator_test.rb:65` documents it.
- **Expiry:** inclusive at the exact instant - `app/services/group_invite_link_redeemer.rb:12`
  uses `expires_at.past?`, so at exactly `expires_at` the link still works; one second
  later it does not. `test/services/group_invite_link_redeemer_test.rb:128` and `:135`
  document both sides.
- **Regeneration:** destroys only the same sender's link
  (`app/services/group_invite_link_generator.rb:17`);
  `test/services/group_invite_link_generator_test.rb:24` and `:33` document it.
- **Who may generate:** the leader only -
  `app/policies/project_group_policy.rb:67-69`. A coordinator cannot generate one.
- **What a link does when redeemed:** joins instantly, bypassing the request/approve
  flow and working on a locked group -
  `test/services/group_invite_link_redeemer_test.rb:85`.

**INFERENCE** - a link is effectively a bearer token with a 24-hour life that survives
the leader leaving or being replaced. Anyone who holds the URL can join the group,
and the only control on who can hold it is that the redeemer must be an enrolled
student (`app/policies/project_group_invite_link_policy.rb:2-4`).

## Q17. What happens to other pending invites and requests when someone joins?

**FACT** - three different rules, one per join path:

| Path | What it clears | Where |
|---|---|---|
| Direct join (`GroupJoiner`) | the joiner's own **pending `direct_request`s**, course-wide | `app/services/group_joiner.rb:27-31` |
| Link redemption (`GroupInviteLinkRedeemer`) | pending invites where the redeemer is sender **or** recipient, course-wide | `app/services/group_invite_link_redeemer.rb:37-43` |
| Accepting an invite (`GroupInviteResponder`) | pending invites where the joining user is sender **or** recipient, course-wide | `app/services/group_invite_responder.rb:57-63` |

**FACT** - the invite that was just accepted survives, because it is set to
`status: :accepted` at `app/services/group_invite_responder.rb:28` **before** the
`destroy_all` at `:29`. `test/services/group_invite_responder_test.rb:174` documents
it.

**INFERENCE** - the three paths are inconsistent: a student who joins directly keeps
pending **direct invites** addressed to them, while the same student who joins by
link or by accepting an invite has them cleared. The `kind: :direct_request` filter in
`GroupJoiner` (`app/services/group_joiner.rb:29`) is the only place the kind is
narrowed; the other two clear both kinds.

## Q18. Where is the grouping mail sent from, and is it inside a transaction?

**FACT** - four send sites, all `GeneralMailer...deliver_later`:

| Site | Where | Inside a lock? |
|---|---|---|
| Direct invite sent to the student | `app/services/group_direct_inviter.rb:29` | no |
| Join request sent to the leader | `app/services/group_direct_requester.rb:27` | no |
| Accept/decline notification | `app/services/group_invite_responder.rb:31` (accept) | **yes** - inside `@group.with_lock` (`:15`) |
| Accept/decline notification | `app/services/group_invite_responder.rb:41` (decline) | no |

**FACT** - there are no grouping job classes: `app/jobs/` contains only
`application_job.rb`.

**INFERENCE** - enqueuing inside the group lock holds the row lock across an adapter
write (the ActiveJob enqueue), which lengthens the critical section for every accept.
`deliver_later` itself does not send mail inside the transaction, so the
"mail sent but transaction rolled back" risk is small - but the enqueue is inside the
lock, and the accept path is the busiest one.

## Q19. Which grouping behaviours have no automated coverage?

**FACT** - `test/services/group_member_remover_test.rb` **does not exist**
(`bin/rails test test/services/group_member_remover_test.rb` -> "Could not load test
file", `Rails::TestUnit::InvalidTestError`). `GroupMemberRemover` is the only grouping
service with no test file.

**INFERENCE** - everything `GroupMemberRemover` does is therefore untested at the
service level: self-leave, leader kick, coordinator removal, the last-member
confirmation branch, dissolution, leader succession, the confirmed->draft reversion
and the `:group_confirmed` block on a confirmed group. Part E lists which of the
answers above are covered elsewhere and which are not covered at all.

---
# Part E. Test cross-reference

Every answer in Part D, mapped to the test that already documents the behaviour.
Tests are cited as `file:line` plus the test name, so they can be found with
`grep -n "test '" <file>`.

**Reading the table** - "covered" means a test asserts the behaviour as described in
the answer. "pinned" means the test asserts the behaviour **as it is today, even
though it looks like a defect**: those tests will fail if the behaviour is changed,
so they are the ones to read before any refactor of the grouping backend.

| Answer | Covered by | Note |
|---|---|---|
| Q1 enrolment removal is not atomic | **none** | `test/controllers/enrolments_controller_test.rb` covers authorisation only (`:13`, `:23`, `:32`, `:44`, `:53`); it never creates a group, so the `dissolve_confirmed: true` path at `app/controllers/enrolments_controller.rb:20` is untested |
| Q2 dissolving a group destroys the project data | **none** | no test creates a project on a group and then dissolves it |
| Q3 one group per student per course | `test/services/group_joiner_test.rb:57` (blocked when already grouped elsewhere), `test/services/group_member_adder_test.rb:28`, `test/services/group_direct_inviter_test.rb:82`, `test/services/group_direct_requester_test.rb:38`, `test/services/group_invite_link_redeemer_test.rb:73`, `test/services/group_invite_responder_test.rb:77` | the **concurrent** cross-group case is not covered (see Q3) |
| Q4 sequence allocation | `test/services/group_creator_test.rb:65` (unique incrementing sequences), `:95` (**pinned** - "auto-generated group_name silently duplicates an existing CSV-imported group_name"), `:106` (concurrent self-creates do not collide) | number reuse after dissolution is not covered; the `RecordNotUnique` path in `GroupCreator` is not covered |
| Q5 the two window representations | `test/models/course_grouping_settings_test.rb:55`, `:60`, `:65`, `:76`, `:87`, `:154`, `:159` | the boolean-plus-dates interaction is covered; the disagreement case is not |
| Q6 nil `group_max` | `test/services/group_direct_inviter_test.rb:139` ("nil group_max is treated as unlimited, not zero capacity") | this pins the **unlimited** reading in `GroupDirectInviter` only. The `GroupJoiner` reading (nil -> 0 -> always full) is **not** covered, and the two disagree |
| Q7 two invite models | `test/models/project_group_invite_test.rb:12`, `:16`, `:23`, `:29`, `:36`, `:46`; `test/services/group_invite_link_generator_test.rb:13`; `test/services/group_invite_link_redeemer_test.rb:23` | |
| Q8 staff confirm/revert path | `test/services/group_confirmer_test.rb:50` (window closed), `test/services/group_reverter_test.rb:14` | the **policy** path (coordinator/lecturer confirming another user's group) has no test; `ProjectGroupPolicy` has no test file at all |
| Q9 manual whitelisting in the settings endpoints | `test/integration/grouping_settings_surface_test.rb:13`, `:22`, `:31`; `test/models/course_grouping_settings_test.rb` (model-level, 22 tests) | the surface tests cover what is *rendered*, not what the two endpoints *write*; there is no controller test for `ProjectGroupsController#update_settings` |
| Q10 `student_list_finalised` reversibility | `test/models/course_grouping_settings_test.rb:128`, `:134`, `:140`, `:147` (model level, true -> false) | the **false -> true** direction is enforced only in the view (`app/views/courses/settings.html.erb:265`) and has no server-side test |
| Q11 adding a member without an enrolment | `test/services/group_member_adder_test.rb:79` (**pinned** - "CURRENT BEHAVIOR: coordinator can add a user with no enrolment in the course at all"), `test/services/group_creator_test.rb:86` (**pinned**) | |
| Q12 group can exceed `group_max` | `test/services/group_member_adder_test.rb:60` (**pinned** - "a stale group_full? read lets add! push the group over its group_max") | |
| Q13 window-check matrix | `test/services/group_creator_test.rb:37` and `:46` (self vs coordinator create), `test/services/group_joiner_test.rb:48`, `test/services/group_confirmer_test.rb:50`, `test/services/group_reverter_test.rb:14`, `test/services/group_direct_inviter_test.rb:48`, `test/services/group_direct_requester_test.rb:29`, `test/services/group_invite_link_generator_test.rb:44`, `test/services/group_invite_link_redeemer_test.rb:40`, `test/services/group_invite_responder_test.rb:66`, `test/services/group_invite_responder_test.rb:151` (decline allowed after the window closed) | no test asserts that a **coordinator removal** is window-exempt, or that a **direct add** is window-exempt |
| Q14 confirmed -> draft reversion | **none** | no test covers `GroupMemberRemover` at all (see Q19) |
| Q15 the dissolve warning | **none** | no test covers the `needs_confirmation?` branch or the `dissolve_confirmed: true` bypass |
| Q16 invite-link behaviour | `test/services/group_invite_link_generator_test.rb:13`, `:24`, `:33`, `:44`, `:53`, `:65`; `test/services/group_invite_link_redeemer_test.rb:23`, `:31`, `:85`, `:128`, `:135` | well covered |
| Q17 pending invites cleared on join | `test/services/group_joiner_test.rb:25`, `:36`, `test/services/group_invite_link_redeemer_test.rb:95`, `:105`, `:115`, `test/services/group_invite_responder_test.rb:174` | the inconsistency between the three paths is visible in these tests but is not asserted as intentional |
| Q18 mail delivery points | `test/services/group_direct_inviter_test.rb:17` ("mailer queued"), `test/services/group_direct_requester_test.rb:17` ("mailer queued") | `GroupInviteResponder`'s mail is not asserted in `test/services/group_invite_responder_test.rb` |
| Q19 untested behaviours | **the gap itself** | see the list below |

## E.1 Behaviours with no test at all

**FACT** - the following are not asserted anywhere in `test/`:

- anything done by `GroupMemberRemover` (self-leave, leader kick, coordinator removal,
  the last-member confirmation, dissolution, leader succession, the confirmed->draft
  reversion, the confirmed-group kick block);
- the `needs_confirmation?` -> `dissolve_confirmed: true` round trip through
  `app/views/project_group_members/_dissolve_warning_modal.html.erb:64`;
- a group that owns a project being destroyed (and the project data with it);
- the coordinator path in `EnrolmentsController#destroy` when the student is in a group
  (`app/controllers/enrolments_controller.rb:14-27`);
- `Course#disable_grouping!` / `#revert_to_default_mode!` **through a controller**
  (the model methods are covered by `test/models/course_grouping_settings_test.rb:100`,
  `:106`, `:112`, `:119`, `:128`, `:134`, `:140`, `:147`, `:165`, but the controller
  branches at `app/controllers/project_groups_controller.rb:147-151` and
  `app/controllers/courses_controller.rb:241-245` are not);
- `ProjectGroupsController#destroy` (`app/controllers/project_groups_controller.rb:47-60`),
  `#lock` (`:98`), `#unlock` (`:115`), `#promote_leader` (`:126`) - none of the
  controller actions that write a group directly have a controller test;
- the CSV-import path (`app/controllers/courses_controller.rb:447-499`) - including the
  "imported group has no `course_group_sequence`" fact behind Q4;
- `ProjectGroupPolicy` - there is no `test/policies/` directory at all, so no policy
  in `app/policies/` is directly tested.

**INFERENCE** - the grouping backend is tested at the *service* level and almost
entirely untested at the *controller and policy* level. That is why the four
controller-level writes in Part B (B27-B29, B34-B36) can exist with no business rules
at all: nothing in the suite would notice.

## E.2 The tests that pin today's behaviour

**FACT** - seven tests assert behaviour that looks like a defect. They pass today and
will fail if the behaviour changes, so they are the natural place to start a
"fix it and update the expectation" pass:

| Test | What it pins |
|---|---|
| `test/services/group_creator_test.rb:95` | an auto-generated `G001` may duplicate a CSV-imported group name |
| `test/services/group_creator_test.rb:86` | a coordinator may create a group whose leader has no enrolment |
| `test/services/group_member_adder_test.rb:79` | a coordinator may add a user with no enrolment at all |
| `test/services/group_member_adder_test.rb:60` | a stale capacity read may push a group past `group_max` |
| `test/services/group_direct_inviter_test.rb:139` | a nil `group_max` means unlimited (contradicting `GroupJoiner`) |
| `test/services/group_invite_responder_test.rb:151` | declining is allowed after the window closed and after confirmation (`:161`) |
| `test/services/group_invite_link_redeemer_test.rb:85` | redeeming a link joins a **locked** group instantly, bypassing request/approve |

## E.3 What the suite does cover well

**FACT** - the service layer is covered to a good standard: 96 examples across the
eleven grouping service test files plus the calculator, with dedicated tests for the
duplicate-invite race (`test/services/group_direct_inviter_test.rb:92`,
`test/services/group_direct_requester_test.rb:76`, `:88`), the concurrent double
accept (`test/services/group_invite_responder_test.rb:128`), the concurrent join race
(`test/services/group_joiner_test.rb:100`), the rollback of a failed membership
(`test/services/group_creator_test.rb:76`), and the sequence race
(`test/services/group_creator_test.rb:106`).

**INFERENCE** - the grouping *services* are in better shape than the grouping
*feature*: the services are small, single-purpose and lock their writes. The gaps are
at the seams - controller actions that write models directly, a policy layer with no
tests, and one service (`GroupMemberRemover`) that never got a test file at all.

---
---

# Excluded / not found

| Expected | Found? | Note |
|---|---|---|
| A shared `ServiceResult` module | **NO** | `grep -rn "ServiceResult" app lib test` -> zero hits. The convention doc shows it as an illustrative snippet (`docs/Abstraction/service_classes.md:88-92`), not as a file. Every Result class hand-rolls its own predicates. |
| `test/services/group_member_remover_test.rb` | **NO** | `GroupMemberRemover` has no test file (Q19). |
| `test/policies/` | **NO** | No policy in `app/policies/` has a direct test. |
| A `Group::` namespace | **NO** | All eleven grouping services are flat in `app/services/`. The convention doc does not require a namespace for command services - so this is a preference, not a violation (Part C.1). |
| Coverage data | **NO** | No coverage tooling exists in this repo; Part E uses test-block counts instead. |
| `force_confirm` | **NO** | Removed in `5e1daba7`; zero hits repo-wide (Q8). |
| `dissolved_at` | **NO** | Added and then removed on this branch; groups are hard-deleted (Q2). |
| A "link" invite kind | **NO** | Links are a separate model and table (Q7). |
| `CONTEXT.md` grouping glossary | **NO** | `CONTEXT.md` documents the rest of the app but has no grouping section; the grouping ADRs are dumped in `docs/grouping_backend_dump.md`, section G. |
| `STUDENT_GROUPING_ARCHITECTURE.md`, `STUDENT_GROUPING_CRUD_TASKS.md`, `STUDENT_GROUPING_REFERENCE.md` | **NO** | `.gitignore`d, not in the working tree, not tracked. |
| `ProPro_Design/groups_tab_mockup.html.erb` | **YES, not analysed** | An HTML mockup under a gitignored directory - a design artefact, not backend behaviour. |
| System tests for grouping | **NO** | `bin/rails test` excludes `test/system/**`, which needs a browser driver; no system test targets grouping. |
| Production / staging data | **NO** | Only `propro_test` was exercised; `propro_development` was not written to. |

## Verification performed

| Check | Command | Result |
|---|---|---|
| Grouping service tests | `RAILS_ENV=test bin/rails test test/services/group_*.rb test/services/group_size_confirmability_calculator_test.rb` | 96 runs, 202 assertions, 0 failures, 0 errors |
| Grouping model / controller / integration tests | the F2 batch in `docs/grouping_backend_dump.md` | 50 runs, 129 assertions, 0 failures, 0 errors |
| Full suite | `RAILS_ENV=test bin/rails test` | 281 runs, 877 assertions, 0 failures, 0 errors |
| Branch state | `git rev-list --count main..HEAD` / `HEAD..main` | 89 ahead, 0 behind |
| Tracked-file cleanliness | `git status --porcelain --untracked-files=no` | empty |

**No application code was changed to produce this audit.** The only files added are the
three markdown documents in `docs/`.
