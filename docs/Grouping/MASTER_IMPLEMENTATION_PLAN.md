# ProPro Grouping: Master Implementation Plan

Branch: `feat/student-grouping-crud` (audited at `0afad3c`; the rev 4 race-condition audit was read at `3619ce7c`, one commit later). Source of truth for requirements and wording: the "ProPro: Grouping" spec doc. Service conventions: `docs/Abstraction/service_classes.md`. Test conventions: `docs/testing.md` (Copeland ch. 12, 14.5, 16.5). Code conventions: section 9. Production read-only queries run 2026-11-02 (section 8). Revision 8.

## Changes in this revision (rev 8)

- **D27 is decided (naming):** not confirmed groups are named Tmp### from a per-course counter, never reused. Confirm gives the lowest free G###. Reopen releases it and gives a new Tmp###. Imported groups keep their CSV names and take no number. Names are display only, and links use the group id.
- **D28 is decided (joining):** not confirmed groups take direct joins. Confirmed groups take requests, invites and links. No approval toggle, and the locked column is dropped as its own PR.
- **D29 is decided (confirmed groups taking members):** accepting a request, invite or link into a confirmed group reopens it, and all members are notified. A project freezes membership and clears pending requests and invites. Imported groups are never reopened by students.
- **Origin column is decided:** an `origin` column with values `formation` and `import`, default `formation`. The P1b backfill stamps `import` using the fingerprint, once, in the same migration that assigns leaders. The Importer sets `origin: import` on every group it creates. Services and policies check `origin` to block student actions. The UI hides the buttons. Coordinators can still add, remove and delete imported groups, and no one can reopen them. Imported groups have no student actions at all.
- **D17 is superseded:** D17's never-reused counter now applies to Tmp only.
- **No naming migration:** existing groups are all confirmed and keep their G numbers. Course 3 is confirmed by the backfill and keeps its numbers too. The "unconfirmed to Tmp" migration and its test are dropped. The only schema work left is the Tmp counter.
- **Production count dropped:** it is one test course, so it is removed from "not checked".
- **Not decided (section 1h):** D30 (Groups tab content, PROPOSED), the cap for a confirmed group in prevent-leftover mode (goes to the D2 reviewer), how an imported group looks on group formation (needs its own UX pass), the routes check (unverified), and the UX items reopened by D27 to D29.
- **Plan items changed by these decisions:** D1, D2 handover, D7 state model, D9, D12 / R12, D13, D17, D21, I11 to I14, R3 / R6, B8, C1, T7, T15, T21, T22, T23, T24, T26, T27, new T34 to T36, P1b, P2, P3, P4, P4b, P7, sections 3b, 4, 7 and 8.

## Earlier revision (rev 7)

- **R13 is decided:** course locks use `FOR NO KEY UPDATE`, never plain `FOR UPDATE`. The latter blocks the FK key-share lock a concurrent member insert needs and deadlocks against a join holding the group lock.
- **B15 is fixed:** coordinator detection uses `exists?(role: :coordinator)` in `GroupsController` and `ProjectGroupPolicy`, so a dual-role user is not misclassified by whichever enrolment row comes first.
- **P2 follow-up test hardening:** the lock test now runs a real coordinator-write/join race, covers `Leaver` and `Kicker`, and asserts the course lock is `FOR NO KEY UPDATE` before the group lock.

## Earlier revision (rev 6)

- **D26 is decided: there is no promote-leader.** Nobody can choose a new leader. The leader changes only by succession: when the leader leaves, is kicked or is removed, the earliest remaining member (`created_at, id`) takes over (B9, D11, T20). Staff still choose the leader when they create a group, and an imported group gets its first CSV member (C1). `FRONTEND.md` (section 9) and `OPEN_ITEMS.md` had already marked the endpoint stale with no UI. Rev 4 (R12) then specified services for it without recording a decision to keep it, which was an oversight, and D26 reverses it.
- **R12 is narrowed** to two services: the require-approval toggle and group delete. The promotion-vs-removal race test (T26) goes with the endpoint, because succession picks the successor inside the group lock and no second writer of `leader_id` is left.
- **To delete (a follow-up commit to P2, where the services were built):** `GroupLeadersController`, the `resource :leader` route, `ProjectGroupPolicy#promote_leader?`, `Groups::LeaderPromoter`, `Groups::Coordinator::LeaderPromoter`, their tests, the routing-test row and the two integration tests that call `course_group_leader_path`. P2 stays DONE; this is clean-up of one over-built item.
- **C1 is reworded:** "a coordinator can change the leader later" is no longer true. The imported leader (first CSV member) stays until succession replaces them.
- **Left as they are:** `FRONTEND.md` section 9 and `OPEN_ITEMS.md` already list the deletion, which D26 confirms. ADRs 0022 and 0025 still list `promote_leader` in their route lists; they are history and stay as written.

## Earlier revision (rev 5)

- **D7 is decided:** self-leave works only while the group is not confirmed and the window is open. In a confirmed group nobody can self-leave, the leader included. P0b is closed.
- **Policy exception:** `ProjectGroupMemberPolicy#destroy?` changes in P2 (it returns true for the member and the leader whatever the status today). New test T32.
- **Section 9 added:** code conventions and quality, including the comment rules (with GitLab examples) and a review checklist.
- **Production checked (2026-11-02, read-only):** no group has two projects, no duplicate `group_name` in a course, no student in two groups of one course. The D22 index, the I11 index and the B3 index are safe to add. Q4 is answered.
- **Backfill counted:** 353 import-fingerprint groups in 14 courses. 349 are in 13 grouping-off courses and will be confirmed; 350 leaderless groups have members and will get a leader. The fingerprint rule (C1) held: every leaderless group with members is a fingerprint group. The P1b backfill migration ships as its own PR.
- **O15 decided:** course 3 is the team's live testing course ("Sandbox Group Approved Topic"), so it is not deleted. The backfill confirms every not-confirmed group that already has a project, a general rule instead of a course-specific one. This covers course 3's 4 groups.
- **B3 moved into P1b** (with R1 and T6), because the Importer sets `course_id` on the members it creates. All member inserts go through one helper, `ProjectGroupMember.add`.
- **Re-audit done:** B1, B2 and I8 were re-audited against HEAD and are DONE (T1 to T3 pass). One residual to check in P2 (I8).
- **B13 located:** the import passes `group_member[:email]`, a key that does not exist (the key is `email_address`). Proposed for P3, as its own commit.
- **Production runs Rails 8.1.4; the branch lockfile has 8.0.2.** Rebase onto main before P1b.

## Earlier revision (rev 4)

- **Race-condition audit added (section 2d):** twelve races (R1 to R12) and eight further edge cases (E1 to E8), written as current / reference apps / proposed. Reference apps (cloned 2026-11-02, sparse, only the files named in 2d were read): GitLab, Canvas LMS, Discourse.
- **D17 decided:** counter column on `courses`, numbers never reused. Name uniqueness index, Creator takes the next number when a generated name is taken. I14 is no longer WONTFIX.
- **D20 to D25 added (decided):** lock convention and order (D20), course lock for everything that changes the head-count N (D21), one project per group enforced in the DB (D22), destructive confirmations are server-side (D23), stale invites cleared by a member callback and no withdraw feature (D24), `grouped?` guards (D25).
- **B14 added:** a group can get two projects (check-then-create with no lock or index). R4 and R5 are fixed together with it in P1b.
- **B3 confirmed:** unique index `(course_id, user_id)` on `project_group_members`.
- **R12:** `GroupLeadersController#update`, `GroupsController#update` and `#destroy` write without a lock. Small lock-taking services are added to the D12 split. Rev 6 drops the leader-promotion part: the endpoint is deleted (D26).
- **Tests:** the service thread tests run inside Rails transactional tests and may not test concurrency (2d). T7 and T8 change to non-transactional race tests with a canary; T24 to T31 added.
- **Rev 3 "not checked" items answered:** a test does rely on lecturer-as-staff (D10), the new-project page does not stop a student in an unconfirmed group (O14), the closed formation page shows a read-only empty state with the wrong copy (1d), and group rename does not exist on this branch (Q8, I11).
- **B1, B2 and I8 may be stale:** the branch moved one commit after the audit and `GroupMembersController#destroy` already redirects. Re-audit them first in P1 (done in rev 5).
- **Phases:** P1b gains B14 (R4, R5). P2 gains the R12 services and E1. P3 gains R1 (B3), R3, R9, E4 and E6 (B3 moved to P1b in rev 5). P4 gains the D17 counter and E3.

## Earlier revision (rev 3)

- **D7 is the working rule:** self-leave from a confirmed group is blocked, and only the leader can reopen, because otherwise "confirmed" means nothing. The advisor can still object. (Decided in rev 5.)
- **D2 stays with the other reviewer.** Handover note added: staff-confirmed groups outside the limits change the head-count N, and not-confirmed groups now survive leaving prevent-leftover mode. Rev 4 adds: the race on N (R3) is fixed with a lock in the services, without changing `confirmable_size?`.
- **D13 added (decided):** mode switches no longer delete not-confirmed groups. `destroy_draft_groups` is deleted and the two tests flip (T17). The spec line and section 7 change too.
- **O11 banner** also covers leftover groups after grouping is off, not just "window closed".
- **D10 revised:** `manage_groups?` audit done (section 1b). It is grouping-only, so it is deleted: 11 call sites become the coordinator check and the column is dropped.
- **D11 / D12:** coordinator removal and enrolment removal are one path (drop `dissolve_confirmed`, add a transaction). Coordinator services are separate small services, not one service with an override flag. `Kicker` keeps its name.
- **Namespace:** coordinator-side services live in `Groups::Coordinator::` (both levels kept). This replaces `Groups::Management::` and the interim `Groups::Staff::`.
- **Reopen with a proposal:** the button is hidden, with no explanation line.
- **Students keep the Groups tab.**
- **O11 banner copy and rules, entry points, gates and empty states** are recorded (1c, 1d, O11, O14).
- **P1b migration backfill rule** recorded. **Importer:** A1 (leader) and A3 (do not move grouped students) kept, A2 dropped as an assumption, imported groups get no sequence. CSV import items moved to their own section 2c (not owned by grouping, still blocking).
- **Group naming and sequence audit** against ProPro code and Moodle (3b): D17 open pending a race-condition audit (decided in rev 4), I11 to I14, T21.
- **B13** (mailer `:email` key bug) is still open.
- **Phases:** P4b added (coordinator Confirmer and Reopener, O11, O14). Tests T15 to T23 added; T2 to T4 reworded for the coordinator.

## Earlier revision (rev 2)

- **D9 decided:** a group that has a proposal cannot be reopened by anyone, coordinators included. O9 shrinks to scoping the confirmed-group validation to `on: :create`.
- **D10 decided:** drop `lecturers_can_manage_groups`. O5 is now a TODO in P4. (Revised in rev 3.)
- **D7 provisional:** self-leave only while not confirmed; only the leader reopens. B4 and T5 are dropped. (Working rule in rev 3, decided in rev 5.)
- **D8 decided** (user confirmed D5 and D8).
- **D11 added (open):** what happens to a group and its project when a student leaves the course, and what staff may do after the window closes. O2 is blocked on it.
- **D12 added (proposed):** split services into formation (student) and `Groups::Management::` (staff). Leader kick becomes its own formation service. (Namespace is `Groups::Coordinator::` in rev 3.)
- **Phases:** P0 is done. P0b added (advisor questions). P1b now runs before P1 (CSV import first). Test plan gains T13, T14.

## How agents use this doc

- Status values: TODO, WIP, DONE, BLOCKED, DECISION, DECIDED, PROVISIONAL, PROPOSED, OPEN, DROPPED, ACCEPTED, UNVERIFIED. Update the Status column in the same PR that does the work.
- Never run `git add` or `git commit`; the user stages and commits every change.
- One PR per phase. Never mix a rename with a behaviour change.
- Minimal, targeted edits. No new abstractions beyond what an item asks for.
- Every bug fix lands with a regression test that fails before the fix.
- Don't change Pundit policies unless an item says so (policies were audited only for the group, member, invite and invite-link policies and `CoursePolicy#manage_groups?`, in rev 4). D7 changes `ProjectGroupMemberPolicy#destroy?` in P2, and P2 also changes `ProjectGroupPolicy#destroy?` so coordinators can delete a group in any state. D26 deletes `ProjectGroupPolicy#promote_leader?`. Rev 8: P3 adds an explicit policy exception, `JoinRequester` and its policy allow confirmed groups (D29).
- Items marked unverified are suspected from reading the code, not reproduced. Write the failing test first; if it passes, mark the item DONE (not a bug).
- Concurrency rules (D20): lock order is course, then group, then enrolment; checks without a DB constraint behind them happen inside the lock; every write to a group or its members goes through a lock-taking service, never `@group.update!` in a controller.
- Follow the code conventions in section 9 in every PR.

## Audit scope

Static read of models, schema, routes, 11 group services, group controllers, group_formations/groups views (partly), and group tests. Not done: running the suite or app, most JS controllers, mailer views, courses/settings UI. Rev 3 reads added: every call site of `manage_groups?`, `GroupMemberRemover` behaviour per actor, `submission_state_for` on Overview, and the naming and sequence audit in 3b. Rev 4 reads added: all group controllers, `ProjectGroupPolicy`, `ProjectGroupMemberPolicy`, `ProjectGroupInvitePolicy`, `ProjectGroupInviteLinkPolicy`, `ProjectsController#new` and `#create`, `GeneralMailer` group actions, `User` associations, and the reference apps in 2d. Rev 5 adds: read-only production queries (section 8), `CoursesController` CSV import, `Project` validation, `GroupReverter`, and a re-audit of `GroupMembersController#destroy` against HEAD.

## 1. Decisions needed (block later phases)

| ID | Decision | Options | Status |
|---|---|---|---|
| D1 | Canonical vocabulary | Spec has two vocabularies ("Auto-Confirmability / Default mode / draft" in 1.x and 3.0 vs "Prevent leftover students / Not confirmed / Reopen" in the user flow). Decided: use the user-flow set everywhere, internal enum/column names follow it | DECIDED |
| D2 | Confirmability model when Prevent leftover students is on | (a) strict quota: size must be base or base+1; (b) current feasibility check (any size in min..max whose remainder is still splittable). Code does (b); spec says (a) and also says "minimize groups, keep balanced". **Handover note for the other reviewer:** staff-confirmed groups outside the limits change the head-count N, and not-confirmed groups now survive leaving prevent-leftover mode (D13). Rev 4: the race on N (R3) is fixed by the course lock (D21) and does not change the model. Rev 8: student joins into confirmed groups change N (D29). Open question for the reviewer (Q5): in prevent-leftover mode, is the cap for a confirmed group group_max or the quota? | BLOCKED (other reviewer owns it) |
| D3 | "No limit" for min/max | Spec default is No limit; Course validates both as required when grouping is enabled. Either allow nil (and handle everywhere) or update the spec | DECIDED |
| D4 | Rename revert to reopen in code | Spec button is "Reopen group"; code uses `revert!`, `GroupReverter`, `revert?`. Optional, user-facing copy must say Reopen regardless | DECIDED |
| D5 | Namespace services under `Groups::` | Optional, cosmetic. Default: leave flat. Decided: namespace them; coordinator-side services go under `Groups::Coordinator::` (D12) | DECIDED |

## 1b. What the decisions change, and the new open questions

D1, D3, D4, D5, D6, D7, D8, D9, D10, D12, D13, D17, D18, D19 and D20 to D26 are settled. D27 to D29 are settled in rev 8, and D17 is superseded by D27. D30 is PROPOSED, not decided. D2 belongs to another reviewer, so P5 and T10 are blocked and nobody changes `confirmable_size?` behaviour (pure renames are fine).

| ID | Decision | Consequence for the plan | Status |
|---|---|---|---|
| D1 | User-flow vocabulary | Rename map in section 4 applies as written. Also retire "Auto-Confirmability" and "Default mode" from code comments, docs and spec sections 1.x and 3.0. Remove stale spec text outside the doc's overview tab completely. Rev 8: add "Tmp group" and "group number" to the glossary | DECIDED |
| D3 | No limit is the default | nil min means 1, nil max means unlimited. Remove the "required when grouping is enabled" validations on Course and update `course_grouping_settings_test`. Prevent leftover students must require both min and max (the quota model has nothing to compute otherwise). One shared helper for effective min/max, used by every service. B7 becomes this work | DECIDED |
| D4 | Reopen | `GroupReverter` becomes `Groups::Reopener#reopen!` (coordinator version `Groups::Coordinator::Reopener`, D6), policy `revert?` becomes `reopen?`, `:already_draft` becomes `:already_not_confirmed`, copy is "Group reopened." Route stays `confirmation#destroy` | DECIDED |
| D5 | `Groups::` namespace | Map below. Tests move to `test/services/groups/`. `Queries::` stays where service_classes.md puts it | DECIDED |
| D6 | Coordinators confirm and reopen | See below. Spec text saying coordinators cannot change status and there is no Confirm or Reopen is stale and must be updated | DECIDED |
| D7 | Staff removal and self-leave on a confirmed group | See below. Self-leave only while not confirmed; in a confirmed group nobody can self-leave, the leader included. Spec section "Remove a member" and the self-leave line change. Coordinator removal never changes status | DECIDED (rev 5) |
| D8 | Name services by user action, Moodle-style | Adopted in the map below, including the Leaver / MemberRemover split (refined by D12) | DECIDED |
| D9 | A group with a proposal cannot be reopened | See below | DECIDED |
| D10 | Drop `lecturers_can_manage_groups`, delete `manage_groups?` | See below | DECIDED |
| D11 | Group and project when a student leaves the course; coordinator actions after close | See below | DECIDED (one shared removal path) |
| D12 | Formation vs coordinator service layers | See below | DECIDED |
| D13 | Mode switches keep not-confirmed groups | See below. Mode switches keep not-confirmed groups. Rev 8: not-confirmed groups kept after a mode switch keep Tmp names. Where they show depends on D30 | DECIDED |
| D15 | Coordinator overrides show warnings | Illegal sizes show as warnings ("below minimum", already in the mockup); coordinators can override the size limits (D6) | DECIDED |
| D17 | Group names and sequence | **Superseded by D27: D17's never-reused counter now applies to Tmp only.** Original text: counter column `courses.last_group_sequence` (integer, default 0, not null), incremented atomically under the course lock that Creator already takes, so a number is never reused after a delete. Unique index `(course_id, group_name)` plus model validation. If a generated name is taken (an imported group named `G003`), Creator takes the next number. Imported groups keep CSV names and no sequence. Backfill: counter = `MAX(course_group_sequence)` per course. See 3b | DECIDED (rev 4), SUPERSEDED by D27 |
| D18 | Move a member | Drop "Move a member" from the spec; coordinators remove and re-add | DECIDED |
| D19 | Re-enable prevent leftover students | Prevent leftover students can be turned back on after being switched off | DECIDED |
| D20 | Lock convention and order | Order: course, then group, then enrolment; never take an earlier lock while holding a later one (that is how deadlocks start). Any check without a DB constraint behind it happens inside the lock. Every write to a group row or its members goes through a service that takes the lock, so the require-approval toggle and group delete become services (R12; leader promotion is dropped, D26; the approval-toggle services are deleted in a follow-up commit, D28). No external calls inside a lock; mail is enqueued after commit (E6). Course lock is `FOR NO KEY UPDATE`, because plain `FOR UPDATE` conflicts with the FK key-share lock a member insert needs and deadlocks against a join holding the group lock (R13) | DECIDED (rev 7) |
| D21 | Course lock for everything that changes N | N is students minus members of confirmed groups, so every writer takes the course lock first: Confirmer and Coordinator::Confirmer, Reopener and Coordinator::Reopener, add or remove a member of a confirmed group, group delete, enrolment add and remove, the Importer, and `Groups::SettingsUpdater` (min, max, prevent-leftover flag). Always taken, not conditional on the mode (the mode can flip mid-request, and N is only used in prevent-leftover mode). Joins do not change N and stay on the group lock only. Rev 8: "Joins do not change N" is false for confirmed groups. Accepting a request, invite or link into a confirmed group reopens it (D29) and takes the course lock. Calculator and `confirmable_size?` are untouched (D2) | DECIDED (rev 4) |
| D22 | One project per group in the DB | Partial unique index on `projects(owner_id) WHERE owner_type = 'ProjectGroup'` (lecturers can own several topics, so no general index). Project creation takes the group lock, which also serialises it against Reopener (R4, R5, B14). Production checked in rev 5: no group has two projects | DECIDED (rev 4) |
| D23 | Destructive confirmations are server-side | The remover no longer reads `dissolve_confirmed` from request params (E1). `Groups::Leaver` refuses whenever the group has a project, whatever the params. `Coordinator::MemberRemover` and `Coordinator::GroupDeleter` return a needs-confirmation result and act only on a second, policy-checked request. Coordinator delete of a group with a project warns first, then deletes (same rule as the last-member case, E2) | DECIDED (rev 4) |
| D24 | Invite cleanup | `ProjectGroupMember` gets an `after_destroy` callback that deletes that user's pending `direct_invite` records for that group, so it also fires on `dependent: :destroy` paths. No withdraw feature for invites and requests (not wanted) (E4, E5) | DECIDED (rev 4) |
| D25 | `grouped?` guards | `ensure_grouped` on every group controller action. `Groups::Creator` and `Groups::Coordinator::Importer` check `grouped?`, because they are the only places that create groups; the other services act on a group that already exists (E3) | DECIDED (rev 4) |
| D26 | No promote-leader | The leader changes only by succession (earliest remaining member), never by choice. Delete the endpoint, the route, `promote_leader?` and both promoter services. See below | DECIDED (rev 6) |
| D27 | Naming | Not confirmed groups are named Tmp### from a per-course counter, never reused. Confirm gives the lowest free G###. Reopen releases it and gives a new Tmp###. Imported groups keep their CSV names and take no number. Names are display only, and links use the group id. See below | DECIDED (rev 8) |
| D28 | Joining | Not confirmed groups take direct joins. Confirmed groups take requests, invites and links. No approval toggle, and the locked column is dropped as its own PR. See below | DECIDED (rev 8) |
| D29 | Confirmed groups taking members | Accepting a request, invite or link into a confirmed group reopens it, and all members are notified. A project freezes membership and clears pending requests and invites. Imported groups are never reopened by students. See below | DECIDED (rev 8) |
| Origin | `origin` column on groups | Values `formation` and `import`, default `formation`. The P1b backfill stamps `import` using the fingerprint, once, in the same migration that assigns leaders. The Importer sets `origin: import` on every group it creates. Services and policies check `origin` to block student actions. The UI hides the buttons. See below | DECIDED (rev 8) |
| D30 | Groups tab content | Unconfirmed groups appear on the Groups tab only when formation is off. Not decided: this is still a "maybe", so it is treated as PROPOSED. See below | PROPOSED |

### D6: coordinators and status

The advisor said coordinators cannot change group status but should be able to clean up. Editing min and max does not do that: existing confirmed groups are not rechecked, and a not-confirmed group only becomes confirmable, so a leader still has to press Confirm while the window is open. The real gap is a Not confirmed group after the window closes: students cannot act, staff cannot confirm, and a confirmed group is required to start a proposal.

Options (rev 2):

- (a) a coordinator Confirm button. Simplest, but it contradicts the advisor's rule and lets staff confirm illegal sizes.
- (b) the system confirms automatically, at close and after each staff membership change, any not-confirmed group whose size is legal, so staff never touch status and fix illegal groups with add, remove and delete.
- (c) a one-off "Close grouping" action that does (b) once.

Rev 2 recommended (b). Question for the advisor: after close, who gets a too-small group to Confirmed, and how? In prevent-leftover mode (b) also depends on D2.

Rev 3 (from T15 and 3b):

- `Coordinator::Confirmer` confirms undersized and oversized groups and works with the window closed.
- `Coordinator::Reopener` works with the window closed and is blocked when the group has a proposal (D9).
- Lecturers and students cannot call them. A student leader still cannot confirm an illegal size.
- Students are blocked by the size limits; coordinators override (D15 shows the warnings).
- Coordinator add, remove and delete never change status (T2, T4, T16).
- Leftover not-confirmed groups, including those left after grouping is turned off (D13), are flagged by the O11 banner for the coordinator to confirm.
- Staff-confirmed groups outside the limits change the head-count N (D2 handover).
- Rev 4: both coordinator services take the course lock first (D21).
- Rev 8: both coordinator services include numbering (D27), so P4b depends on the P4 naming work.

### D7: self-leave and staff removal on a confirmed group (decided, rev 5)

- Self-leave works only while the group is not confirmed and the window is open. In a confirmed group nobody can self-leave, the leader included. Otherwise "confirmed" means nothing.
- Only the leader can turn confirmed off (Reopen), and not at all if the group has a proposal (D9). A leader who wants out of a confirmed group must reopen it first. A group with a proposal cannot be reopened, so only a coordinator can remove its members.
- A leader can kick only while the group is not confirmed and the window is open.
- Coordinator add, remove and delete never change status. Illegal sizes show as warnings (D15).

Effects:

- `Leaver` has no reopen branch and returns blocked `:group_confirmed`. `legal_at_current_size?` is deleted from the remover, so B4 and T5 disappear.
- The Leave control is hidden on a confirmed group. The formation view already renders it only when `policy(membership).destroy?`, so the fix is in the policy.
- **Explicit exception to "don't change Pundit policies" (P2):** `ProjectGroupMemberPolicy#destroy?` returns false for self-leave and for leader kick when the group is confirmed, and stays true for coordinators. Today it returns true for the member and the leader whatever the status (T32).
- The spec lines "Remove a member" and "self-leave from a confirmed group reopens it" must be updated.
- Alternative B (keep revert-if-illegal on staff removal) is only safe if someone has a way to re-confirm; it is not planned.
- Rev 8: the self-leave rule is unchanged by D28 and D29. The state model row "Confirmed + window open: nobody can join" changes (state model below).

### D9: groups with a proposal are never reopened (decided)

A group that already has a proposal cannot be reopened by anyone, including coordinators. Reasons: reopening a group that owns a project blurs the line between group formation and group management, and it leaves the proposal owned by a not-confirmed group (O9).

- `GroupReverter` (later `Reopener`) returns blocked with reason `:has_project`; `revert?` (later `reopen?`) is false when the group has a project. The UI hides the Reopen button, with no explanation line.
- `Project#project_group_must_be_confirmed` runs `on: :create` only, so a later status change can never block edits to an existing project.
- Changing membership of a group with a project is a management concern, not a formation one. See D11 and D12.
- Rev 4: project creation takes the group lock (D22), so a project cannot be created on a group while it is being reopened (R5).
- Rev 8: a group with a project cannot take new members. A project freezes membership and clears pending requests and invites (D29).

### D10: drop `lecturers_can_manage_groups`, delete `manage_groups?` (decided)

`manage_groups?` audit (rev 3):

- It is grouping-only and used in 11 places: staff creating a group (`groups#create`), staff adding a member (`group_members#create`), the manage UI in the formation page and table and `groups/edit`, four checks in `ProjectGroupPolicy` (`create?`, `confirm?`, `revert?`, `edit?`), and `ProjectGroupMemberPolicy#destroy?`.
- The lecturer flag is read in exactly one place, `CoursePolicy#manage_groups?`, and no test references the column.
- Promote-leader (dropped in D26) and deleting a confirmed group were already coordinator-only. **Rev 4 correction:** the rev 3 text also listed "rename" here, but rename does not exist on this branch (`GroupsController#update` permits only `locked`, no view has a name field), and group names cannot be edited. Today a lecturer (flag default true) can create, add, remove, confirm and reopen, but not promote a leader or delete a confirmed group.
- Deleting it means replacing the 11 call sites with the coordinator check and dropping the column.
- **Checked in rev 4:** a test does rely on a lecturer acting as staff by default. `test/integration/group_formation_page_test.rb` lines 80-81 ("coordinator and managing lecturer see Manage on the table") loops over the coordinator and the lecturer, and the lecturer is signed in again near line 127. These flip under D10 (T31).
- **Landed early in P2:** `ProjectGroupMemberPolicy#destroy?` already denies lecturers even when `CoursePolicy#manage_groups?` is true. The remaining D10 work is still P4.
- Lecturers get the same read-only closed message as students (1d).

Rev 2 text, superseded: `manage_groups?` becomes coordinator or lecturer, always. The spec's "lecturers manage groups" setting stays a future feature, built when someone asks.

### D11: course removal and management after close (decided: one shared removal path)

What happens to a group and its project when a student leaves the course (enrolment deleted), and what may staff do to groups after the window closes? Today `EnrolmentsController#destroy` passes `dissolve_confirmed: true`, so removing the last student deletes the group and its proposal with no warning (O2).

What kick and removal do today (one class, `GroupMemberRemover`, behaves differently depending on who clicks):

- Leader kick: needs the window open and the group not confirmed, then it just removes the membership. Nothing else can happen, since a leader can't kick themselves or empty the group.
- Self-leave: needs the window open. It reopens a confirmed group, promotes a new leader if needed, and deletes the group if it was the last member. (D7 changes this: self-leave from a confirmed group is blocked.)
- Staff removal: no window check. It promotes a leader, un-confirms the group if the size is now illegal, and shows a modal naming the proposal when the last member goes.
- Enrolment removal: uses the same class but hard-codes `dissolve_confirmed: true`, so the warning never shows and the group and proposal are deleted silently. It also isn't in a transaction.

Rev 3:

- Coordinator removal and enrolment removal are one path. They already share the class, so the fix is to drop the `dissolve_confirmed` flag so enrolment removal also shows the warning, and wrap it in a transaction.
- After D7 and D9, `Kicker` is tiny, and `Leaver` never meets a proposal (a not-confirmed group can't have one, except legacy rows). Legacy rows exist: 4 groups in course 3 (O15), which the backfill confirms. So the delete-with-warning logic lives only in the coordinator remover, which the enrolment path shares.
- A removed leader is replaced by the earliest member; the student's pending invites are cleared (T20).

Rev 4:

- The "warning" is a server-side step, not a request param (D23, E1). The same rule covers the coordinator "Delete group" button: a group with a project warns first, then deletes (E2).
- Enrolment removal takes the course lock first (D20, D21), then the group lock.

Matrix to settle (rev 2): last member vs leader vs other member; project vs no project; window open vs closed.

Default proposal (rev 2):

- Removing a non-last member removes the membership, promotes a leader if needed, and shows a size warning.
- Removing the last member of a group with no project deletes the group.
- Removing the last member of a group with a project deletes nothing silently. It is blocked, or needs an explicit coordinator action on the project first.

### D12: formation and coordinator layers (decided)

- **Formation services** are student actions. They check the window and the group's status.
- **Coordinator services** are coordinator actions, under `Groups::Coordinator::`. No window check, no status change from membership actions, and they must account for projects and enrolments.
- Separate small services (`Coordinator::Confirmer`, `Coordinator::Reopener`, `Coordinator::MemberRemover`), not one service with an override flag, because a flag makes it easy to pass the bypass from a student path.
- Namespace: `Groups::Coordinator::`, verbose on purpose. Both levels are kept: a top-level `Coordinator::Confirmer` reads like a model for the person and doesn't say what it confirms, `Groups::` is already the D5 domain namespace, the folder boundary makes the formation/coordinator split visible, and a flat `Groups::CoordinatorConfirmer` would give six similar names in one folder. The permission belongs in the policy, not the class name.
- The leader kick is a formation service (window open, not confirmed), so it leaves `MemberRemover` and becomes `Groups::Kicker#kick!`. The name stays `Kicker`.
- `MemberRemover` becomes coordinator-only.
- The shared steps (remove a membership, promote the next leader, delete the group if empty) stay as a private helper, not a new abstraction.
- `Importer` is the first coordinator service and sets the pattern: coordinator-initiated, ignores the window, creates groups already confirmed (C1).
- **Rev 4 (R12):** the two group writes that bypass services today become services in the same two layers: the require-approval toggle and group delete. A third, leader promotion, was dropped in rev 6 (D26). Formation versions check window and status; coordinator versions do not. Names in the map below. Controllers stop calling `@group.update!` and `@group.destroy!`.
- **Rev 8:** the approval-toggle services built in P2 get deleted in a follow-up commit, like D26 (D28). R12 shrinks to one service (group delete). This reopens a DONE item.

### D13: mode switches keep not-confirmed groups (decided)

- Mode switches no longer delete not-confirmed groups. Today `disable_grouping!` and `revert_to_default_mode!` both call `destroy_draft_groups`. Delete it and flip the two tests in `course_grouping_settings_test.rb` (lines 112 and 140) (T17).
- The spec line and plan section 7 change too.
- Leftover groups can now sit around after grouping is off, so the O11 banner must also cover that case, not just "window closed".
- Handover to D2: not-confirmed groups now survive leaving prevent-leftover mode.
- Prevent leftover students can be turned back on after being switched off (D19).
- Rev 8: not-confirmed groups kept after a mode switch keep Tmp names (D27). Where they show depends on D30.

### D18: Move a member (decided)

- Drop "Move a member" from the spec.
- Coordinators remove and re-add instead. No `Coordinator::Mover`.

### D19: Re-enable prevent leftover students (decided)

- Prevent leftover students can be turned back on after being switched off.
- The "can only be turned on once" rule is removed from the spec.

### D26: no promote-leader (decided, rev 6)

- There is no way to choose a new leader. `FRONTEND.md` (section 9) and `OPEN_ITEMS.md` already called the endpoint stale, with no UI and deletion planned for the backend pass. Rev 4 (R12) turned it into services without recording a decision to keep it. That was an oversight, and this reverses it.
- The leader changes only by succession. When the leader leaves, is kicked or is removed, the earliest remaining member (`created_at, id`) becomes leader (B9, D11, T20). Staff choose the leader when they create a group, and an imported group gets its first CSV member (C1).
- A coordinator who wants a different leader cannot pick one. Accepted: the earliest member is a fair default, and the student-facing UI never had the control.
- Removed: `GroupLeadersController`, the `resource :leader` route, `ProjectGroupPolicy#promote_leader?`, `Groups::LeaderPromoter`, `Groups::Coordinator::LeaderPromoter`, their tests, the routing-test row, and the two integration tests that call `course_group_leader_path`. The deletion lands as a follow-up commit to P2.
- The promotion-vs-removal race test (T26) is dropped. Succession selects the successor inside the group lock, so there is no second writer of `leader_id` on an existing group.
- ADRs 0022 and 0025 still list `promote_leader`; they are history and stay as written.

### D27: naming (decided, rev 8)

- Not confirmed groups are named Tmp### from a per-course counter, never reused. Confirm gives the lowest free G###. Reopen releases it and gives a new Tmp###. Imported groups keep their CSV names and take no number. Names are display only, and links use the group id.
- Superseded: D17's never-reused counter now applies to Tmp only.
- A freed number can be handed out again (G### belongs to confirmed groups only).
- Every URL, invite, request and invite-link token points at the group's database id, never its name. Example: `/courses/3/groups/4812`, not `/courses/3/groups/G002`. Rename Tmp012 to G002 and every link still works.
- No naming migration for existing groups. Existing groups are all confirmed and keep their G numbers. Course 3 is confirmed by the backfill and keeps its numbers too.
- Drop the "unconfirmed to Tmp" migration and its test. The only schema work left is the Tmp counter.
- Rename (I11): Confirmer and Reopener rename the group. The `(course_id, group_name)` index stays. The rename runs in one transaction under the course lock.
- Tmp stays for now (the label users see; see section 1h).
- Not checked: none of the group routes look groups up by name. Unverified (section 8).

### D28: joining (decided, rev 8)

- Not confirmed groups take direct joins. Confirmed groups take requests, invites and links. No approval toggle, and the locked column is dropped as its own PR.
- The "Require approval to join" toggle (`locked` column) is gone, and so is Leader #2 "Choose who can join".
- The approval-toggle services built in P2 get deleted in a follow-up commit, like D26. R12 shrinks to one service (group delete). P2 stays DONE.
- `Groups::Joiner` stays: not confirmed groups still take direct joins.
- The `locked` column is dropped as its own PR (behaviour change, not a rename). The `locked` to `requires_approval` rename (P7) is removed.

### D29: confirmed groups taking members (decided, rev 8)

- Accepting a request, invite or link into a confirmed group reopens it, and all members are notified. A project freezes membership and clears pending requests and invites. Imported groups are never reopened by students.
- Invites and links reopen a confirmed group too. This is the same rule as requests.
- Imported groups can't be reopened by anyone, so students can't grow them. Accepting a request or invite is a reopen, so imported groups are closed to requests, invites and links for students. Coordinators still add, remove and delete.
- Misuse is blocked in the service and the policy, and the button is hidden.
- Pending requests and invites are cleared when a project is created.
- Every member is notified on an accept-triggered reopen.
- Accepting a request into a confirmed group takes the course lock (D21). The shared invite-cleanup helper (B8) must also run when a request into a confirmed group is accepted.
- Student joins into confirmed groups change N (D2 handover).

### Origin column (decided, rev 8)

- When behaviour depends on where a record came from, systems store that as a field and don't derive it from side effects. Deriving it breaks: the fingerprint (no leader, no sequence) only worked until the backfill gave imported groups a leader. Any derived marker gets invalidated by the next unrelated change.
- Use an `origin` column with values `formation` and `import`, default `formation`. Don't use a boolean, because a third source later (an API sync, say) would be a migration.
- The P1b backfill stamps `import` using the fingerprint, once, in the same migration that assigns leaders. After that nothing reads the fingerprint again.
- The Importer sets `origin: import` on every group it creates.
- Services and policies check `origin` to block student actions. The UI hides the buttons.
- Coordinators can still add, remove and delete imported groups, and no one can reopen them.
- Imported groups: no student actions at all, confirmed as intended.
- UX reopened: how an imported group looks on group formation, and what a student in one sees, since they have no actions. This needs its own UX pass (section 1h).

### D30: Groups tab content (PROPOSED, not decided)

- Unconfirmed groups appear on the Groups tab only when formation is off. Still a "maybe", so it is treated as PROPOSED. Nothing below is built until it is decided.
- If adopted: the O11 banner, yellow rows, quiet "Not confirmed" pill and "Not confirmed" filter were decided assuming unconfirmed groups sit on the Groups tab. D30 changes that.
- If adopted: "Students keep the Groups tab" (1c) changes. A student in an unconfirmed group no longer sees their group there while formation is open.
- If adopted: O11, O14, O7 and O8 all depend on it. `groups_with_status` changes, and ADR 0024 (two surfaces) needs a superseding ADR.
- If adopted: where coordinators see unconfirmed groups while formation is open needs a decision.