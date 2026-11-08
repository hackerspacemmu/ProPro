# ProPro Grouping: Master Implementation Plan

Branch: `feat/student-grouping-crud` (audited at `0afad3c`; the rev 4 race-condition audit was read at `3619ce7c`, one commit later; rev 9 status read at `acaae256`). Source of truth for requirements and wording: the "ProPro: Grouping" spec doc. Service conventions: `docs/Abstraction/service_classes.md`. Test conventions: `docs/testing.md` (Copeland ch. 12, 14.5, 16.5). Code conventions: section 9. Production read-only queries run 2026-11-02 (section 8). Revision 9.

## Changes in this revision (rev 9)

- **Sections restored.** The committed rev 8 stopped after D30. The state model, service rename map, phase impact, answers 1c to 1f, the bug register, ownership audit, CSV import, race audit, inconsistencies, naming audit, wording map, test plan, phases, verified list, "not audited" and code conventions were all missing. Rev 9 restores them from rev 7 and applies the rev 8 and rev 9 changes. **Review these:** the rev 8 edits to the restored rows were reconstructed from the decision text in section 1b (state model, rename map, R3, R6, R12, I11 to I14, T21, T24, T26, section 3b, section 4, section 7 and section 8), and tests T34 to T36 were rewritten from D27 to D29 and the origin decision, because their rev 8 text was not in the committed file.
- **P1b is DONE** (commit `6ae59ea9`, branch head `acaae256`). The `origin` column exists with default `formation`, the Importer sets `import`, the backfill stamps `import` first (using the fingerprint, in every course), and Reopen is refused for imported groups (`:imported_group` in the service, `revert?` false in the policy). T13, T14, T22 and T25 are written. Not done here: the suite was not run, T23's production dry run and the read-only checks in section 8 are the owner's before deploy, and the commit also changed `db/seeds.rb` and three views (`_group_row`, `_groups_table`, `_size_warning_icon`) that the brief did not list.
- **P2b is new: the D28 cleanup, in two PRs** (brief `D28_APPROVAL_TOGGLE_REMOVAL.md`). Part 1 deletes both `ApprovalToggler` services, `GroupsController#update` and its route, the Manage switch, the table's request button and the lock gates, closes join requests, and deletes every pending request with a data migration. Part 2 drops `project_groups.locked`.
- **Join requests are closed for every group until P4c.** Requests are only for confirmed groups (D28). The requester keeps that final rule and refuses a not confirmed group with `:group_not_confirmed`; `ProjectGroupPolicy#request_to_join?` returns false until confirmed groups can accept requests (an explicit policy exception). The request plumbing stays for D29.
- **D31 is decided (request lifecycle).** The rules that keep requests from going stale are recorded in D31. Request expiry is still OPEN (section 1h).
- **P3 is split.** P3a keeps the work that does not depend on D29 (B6, B8, O2, R2, R3, R9, R10, E4, E6, B13 and the D31 cleanup rules). The D29 build is a new phase, P4c, after P4 (Tmp naming) and P4b (Reopener).
- **Renames stay in P7.** The `direct_` prefix (I4) is not touched by P2b: a rename never ships with a behaviour change.
- **Rebase onto main is deferred** by the owner. Do it before merging to main (Rails 8.1.4 in production, 8.0.2 in the lockfile).
- **Plan items changed by rev 9:** D28, D29, D31 (new), 1g and 1h (new), state model, rename map, phase impact, B6, B8, B13, O2, C1, R1 to R6, R8 to R10, R12, E4, E6, E7, I11 to I14, T7, T8, T13, T14, T16, T20 to T27, T29, new T37 and T38, P1b, P2b (new), P3a, P4, P4b, P4c (new), P7, sections 3b, 4, 7 and 8.

## Earlier revision (rev 8)

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
- Don't change Pundit policies unless an item says so (policies were audited only for the group, member, invite and invite-link policies and `CoursePolicy#manage_groups?`, in rev 4). D7 changes `ProjectGroupMemberPolicy#destroy?` in P2, and P2 also changes `ProjectGroupPolicy#destroy?` so coordinators can delete a group in any state. D26 deletes `ProjectGroupPolicy#promote_leader?`. Rev 9: P2b closes join requests with one policy change, `ProjectGroupPolicy#request_to_join?` returns false; P4c reopens it for confirmed groups (D29).
- Items marked unverified are suspected from reading the code, not reproduced. Write the failing test first; if it passes, mark the item DONE (not a bug).
- Concurrency rules (D20): lock order is course, then group, then enrolment; checks without a DB constraint behind them happen inside the lock; every write to a group or its members goes through a lock-taking service, never `@group.update!` in a controller.
- Follow the code conventions in section 9 in every PR.

## Audit scope

Static read of models, schema, routes, 11 group services, group controllers, group_formations/groups views (partly), and group tests. Not done: running the suite or app, most JS controllers, mailer views, courses/settings UI. Rev 3 reads added: every call site of `manage_groups?`, `GroupMemberRemover` behaviour per actor, `submission_state_for` on Overview, and the naming and sequence audit in 3b. Rev 4 reads added: all group controllers, `ProjectGroupPolicy`, `ProjectGroupMemberPolicy`, `ProjectGroupInvitePolicy`, `ProjectGroupInviteLinkPolicy`, `ProjectsController#new` and `#create`, `GeneralMailer` group actions, `User` associations, and the reference apps in 2d. Rev 5 adds: read-only production queries (section 8), `CoursesController` CSV import, `Project` validation, `GroupReverter`, and a re-audit of `GroupMembersController#destroy` against HEAD. Rev 9 adds: the P1b commit (`6ae59ea9`: origin column, Importer stamp, reopen guard, backfill), the whole lifecycle of pending join requests (every place invites and requests are created, cleared or accepted), and every use of `locked`. The suite was not run.

## 1. Decisions needed (block later phases)

| ID | Decision | Options | Status |
|---|---|---|---|
| D1 | Canonical vocabulary | Spec has two vocabularies ("Auto-Confirmability / Default mode / draft" in 1.x and 3.0 vs "Prevent leftover students / Not confirmed / Reopen" in the user flow). Decided: use the user-flow set everywhere, internal enum/column names follow it | DECIDED |
| D2 | Confirmability model when Prevent leftover students is on | (a) strict quota: size must be base or base+1; (b) current feasibility check (any size in min..max whose remainder is still splittable). Code does (b); spec says (a) and also says "minimize groups, keep balanced". **Handover note for the other reviewer:** staff-confirmed groups outside the limits change the head-count N, and not-confirmed groups now survive leaving prevent-leftover mode (D13). Rev 4: the race on N (R3) is fixed by the course lock (D21) and does not change the model. Rev 8: student joins into confirmed groups change N (D29). Open question for the reviewer (Q5): in prevent-leftover mode, is the cap for a confirmed group group_max or the quota? | BLOCKED (other reviewer owns it) |
| D3 | "No limit" for min/max | Spec default is No limit; Course validates both as required when grouping is enabled. Either allow nil (and handle everywhere) or update the spec | DECIDED |
| D4 | Rename revert to reopen in code | Spec button is "Reopen group"; code uses `revert!`, `GroupReverter`, `revert?`. Optional, user-facing copy must say Reopen regardless | DECIDED |
| D5 | Namespace services under `Groups::` | Optional, cosmetic. Default: leave flat. Decided: namespace them; coordinator-side services go under `Groups::Coordinator::` (D12) | DECIDED |

## 1b. What the decisions change, and the new open questions

D1, D3, D4, D5, D6, D7, D8, D9, D10, D12, D13, D17, D18, D19 and D20 to D26 are settled. D27 to D29 are settled in rev 8, and D17 is superseded by D27. D31 is settled in rev 9, except request expiry (OPEN, 1h). D30 is PROPOSED, not decided. D2 belongs to another reviewer, so P5 and T10 are blocked and nobody changes `confirmable_size?` behaviour (pure renames are fine).

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
| D21 | Course lock for everything that changes N | N is students minus members of confirmed groups, so every writer takes the course lock first: Confirmer and Coordinator::Confirmer, Reopener and Coordinator::Reopener, add or remove a member of a confirmed group, group delete, enrolment add and remove, the Importer, and grouping settings saved under the course lock in `handle_settings` (min, max, prevent-leftover flag). Always taken, not conditional on the mode (the mode can flip mid-request, and N is only used in prevent-leftover mode). Joins do not change N and stay on the group lock only. Rev 8: "Joins do not change N" is false for confirmed groups. Accepting a request, invite or link into a confirmed group reopens it (D29) and takes the course lock. Calculator and `confirmable_size?` are untouched (D2) | DECIDED (rev 4) |
| D22 | One project per group in the DB | Partial unique index on `projects(owner_id) WHERE owner_type = 'ProjectGroup'` (lecturers can own several topics, so no general index). Project creation takes the group lock, which also serialises it against Reopener (R4, R5, B14). Production checked in rev 5: no group has two projects | DECIDED (rev 4) |
| D23 | Destructive confirmations are server-side | The remover no longer reads `dissolve_confirmed` from request params (E1). `Groups::Leaver` refuses whenever the group has a project, whatever the params. `Coordinator::MemberRemover` and `Coordinator::GroupDeleter` return a needs-confirmation result and act only on a second, policy-checked request. Coordinator delete of a group with a project warns first, then deletes (same rule as the last-member case, E2) | DECIDED (rev 4) |
| D24 | Invite cleanup | `ProjectGroupMember` gets an `after_destroy` callback that deletes that user's pending `direct_invite` records for that group, so it also fires on `dependent: :destroy` paths. No withdraw feature for invites and requests (not wanted) (E4, E5) | DECIDED (rev 4) |
| D25 | `grouped?` guards | `ensure_grouped` on every group controller action. `Groups::Creator` and `Groups::Coordinator::Importer` check `grouped?`, because they are the only places that create groups; the other services act on a group that already exists (E3) | DECIDED (rev 4) |
| D26 | No promote-leader | The leader changes only by succession (earliest remaining member), never by choice. Delete the endpoint, the route, `promote_leader?` and both promoter services. See below | DECIDED (rev 6) |
| D27 | Naming | Not confirmed groups are named Tmp### from a per-course counter, never reused. Confirm gives the lowest free G###. Reopen releases it and gives a new Tmp###. Imported groups keep their CSV names and take no number. Names are display only, and links use the group id. See below | DECIDED (rev 8) |
| D28 | Joining | Not confirmed groups take direct joins. Confirmed groups take requests, invites and links. No approval toggle, and the locked column is dropped as its own PR. Rev 9: the work is P2b (two PRs), and join requests are closed for every group until P4c. See below | DECIDED (rev 8) |
| D29 | Confirmed groups taking members | Accepting a request, invite or link into a confirmed group reopens it, and all members are notified. A project freezes membership and clears pending requests and invites. Imported groups are never reopened by students. Rev 9: built in P4c. See below | DECIDED (rev 8) |
| Origin | `origin` column on groups | Values `formation` and `import`, default `formation`. The P1b backfill stamps `import` using the fingerprint, once, in the same migration that assigns leaders. The Importer sets `origin: import` on every group it creates. Services and policies check `origin` to block student actions. The UI hides the buttons. See below | DECIDED (rev 8) |
| D30 | Groups tab content | Unconfirmed groups appear on the Groups tab only when formation is off. Not decided: this is still a "maybe", so it is treated as PROPOSED. See below | PROPOSED |
| D31 | Lifecycle of pending join requests | Requests only exist for confirmed groups. They are deleted when the student lands in any group, when the group is reopened, when a project is created, and when the student leaves the course. Accept re-checks enrolment and ungrouped state. Expiry is OPEN. See below | DECIDED (rev 9); expiry OPEN |

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
- Rev 9, built in P2b (two PRs). Part 1 removes both `ApprovalToggler` services, `GroupsController#update` and its route, the Manage switch, the table's request button and the lock gates in `Groups::Joiner` and the requester. Part 2 drops the column.
- Rev 9, join requests are closed for every group until P4c. A not confirmed group takes direct joins, so the requester refuses it with `:group_not_confirmed`. A confirmed group cannot accept a request until D29 is built, so `ProjectGroupPolicy#request_to_join?` returns false for now. The service holds the final rule and the policy line is the one switch P4c flips. This is an explicit policy exception.
- Rev 9, the request plumbing stays: the `join_requests` route, `GroupJoinRequestsController`, the requester, `GroupInviteResponder`, the leader's incoming-requests list and the "Request sent" branch in the table.
- Rev 9, a data migration in P2b deletes every pending request (D31).
- Rev 9, `ProjectGroupPolicy#update?` stays (only `edit?` uses it now); it goes with the `manage_groups?` removal in P4 (D10). No `ignored_columns` step, matching the earlier column removals. The `direct_` renames stay in P7 (I4).

### D29: confirmed groups taking members (decided, rev 8)

- Accepting a request, invite or link into a confirmed group reopens it, and all members are notified. A project freezes membership and clears pending requests and invites. Imported groups are never reopened by students.
- Invites and links reopen a confirmed group too. This is the same rule as requests.
- Imported groups can't be reopened by anyone, so students can't grow them. Accepting a request or invite is a reopen, so imported groups are closed to requests, invites and links for students. Coordinators still add, remove and delete.
- Misuse is blocked in the service and the policy, and the button is hidden.
- Pending requests and invites are cleared when a project is created.
- Every member is notified on an accept-triggered reopen.
- Accepting a request into a confirmed group takes the course lock (D21). The shared invite-cleanup helper (B8) must also run when a request into a confirmed group is accepted.
- Student joins into confirmed groups change N (D2 handover).
- Rev 9: built in P4c, after P3a (shared cleanup, enrolment re-check), P4 (Tmp naming) and P4b (Reopener). The lifecycle rules for pending requests are D31.

### Origin column (decided, rev 8)

- When behaviour depends on where a record came from, systems store that as a field and don't derive it from side effects. Deriving it breaks: the fingerprint (no leader, no sequence) only worked until the backfill gave imported groups a leader. Any derived marker gets invalidated by the next unrelated change.
- Use an `origin` column with values `formation` and `import`, default `formation`. Don't use a boolean, because a third source later (an API sync, say) would be a migration.
- The P1b backfill stamps `import` using the fingerprint, once, in the same migration that assigns leaders. After that nothing reads the fingerprint again.
- The Importer sets `origin: import` on every group it creates.
- Services and policies check `origin` to block student actions. The UI hides the buttons.
- Coordinators can still add, remove and delete imported groups, and no one can reopen them.
- Imported groups: no student actions at all, confirmed as intended.
- UX reopened: how an imported group looks on group formation, and what a student in one sees, since they have no actions. This needs its own UX pass (section 1h).
- Rev 9, built in P1b: the column, the enum (`origin_import?`, `origin_formation?`), the Importer stamp, the backfill stamp (it runs before the backfill's confirm step, because the fingerprint reads `confirmed`), and the Reopen guard. Only Reopen has an `origin` guard so far: every other student write service already refuses a confirmed group, and imported groups are always confirmed. The other guards arrive with P4c, when confirmed groups start taking members.
- Rev 9, consequence for course 3: its 4 groups are fingerprint groups, so they become `import` and lose all student actions.
- No DB check constraint on `origin`: a constraint would bring back the migration that the string column was chosen to avoid.

### D30: Groups tab content (PROPOSED, not decided)

- Unconfirmed groups appear on the Groups tab only when formation is off. Still a "maybe", so it is treated as PROPOSED. Nothing below is built until it is decided.
- If adopted: the O11 banner, yellow rows, quiet "Not confirmed" pill and "Not confirmed" filter were decided assuming unconfirmed groups sit on the Groups tab. D30 changes that.
- If adopted: "Students keep the Groups tab" (1c) changes. A student in an unconfirmed group no longer sees their group there while formation is open.
- If adopted: O11, O14, O7 and O8 all depend on it. `groups_with_status` changes, and ADR 0024 (two surfaces) needs a superseding ADR.
- If adopted: where coordinators see unconfirmed groups while formation is open needs a decision.

### D31: lifecycle of pending join requests (decided rev 9; expiry OPEN)

Why: today nothing clears a pending request when a coordinator adds the student to a group, when a group is confirmed or reopened, when the window closes, or when the student leaves the group or the course. A leader could accept an old request later and the student would join a group they asked about long ago. After D29 that accept would also reopen a group and notify every member.

- A join request only exists for a confirmed group (D28). A not confirmed group takes direct joins and the requester refuses it (`:group_not_confirmed`). Nothing can create a request until P4c.
- A pending request is deleted (silently, no email) when:
  - the student lands in any group in the course: a direct join, an accepted invite or request, a redeemed link, or a coordinator add. One shared method does it (B8, P3a);
  - the group is reopened (P4b), because it now takes direct joins;
  - a project is created on the group (D29, P3a);
  - the student leaves the course (O2, P3a);
  - the group is deleted (already true, `dependent: :destroy`).
- At accept time the responder re-checks that the student is still enrolled and not in a group (B6, R10, P3a).
- Declining keeps its row with status declined (history). There is no withdraw feature (E5).
- **Expiry: OPEN.** Options: a time limit, as invite links have (24 hours), or clearing every pending request when the window closes. Recommended: a time limit, because it also covers a request that sits for a long time inside an open window. Needed before P4c.
- At the D28 deploy a data migration deletes every pending request (P2b), because each one is stale by the time requests reopen. Students with a pending request on a not confirmed group would otherwise see "Request sent" where the Join button should be.

### State model (proposed)

Window (course, open or closed) and status (group, not confirmed or confirmed) are separate axes. Size (below min, ok, above max) is a derived warning, not a state. Formation actions are student actions and need the window open. Coordinator membership actions never check the window and never change status (D7). Coordinator Confirm and Reopen are separate explicit actions (D6). Status means the leader locked membership and may start the proposal; window means students may act. A group with a proposal can never be reopened (D9).

| | Window open | Window closed |
|---|---|---|
| **Not confirmed** | Students: create, join, invite, link, leave, leader kick, confirm. No join requests (D28). Coordinator: add, remove, delete, confirm | Students: read only. Coordinator: add, remove, delete, confirm (D6). The O11 banner flags these groups |
| **Confirmed** | Students: leader reopens (only if no proposal, and not for an imported group). Nobody can leave, the leader included (D7). New members come in by request, invite or link, which reopens the group (D29, built in P4c); until then nobody can join. Coordinator: add, remove, delete, reopen (only if no proposal, and not for an imported group) | Students: read only. Coordinator: same |

Imported groups (`origin: import`) are always confirmed and have no student actions at all. Coordinators can still add, remove and delete them, and nobody can reopen them.

### Service rename map (D5, D8, D12)

Moodle's group self-selection module names its actions by user verb (create, select/join, unselect/leave, assign, export) and its docs show no confirm state, so copy the naming, not the model. Current names describe mechanism ("Direct", "Redeemer"); the spec's user flow uses verbs.

| Current | Proposed | Notes |
|---|---|---|
| `GroupCreator` | `Groups::Creator#create!` | Takes the course lock, names the group Tmp### from the counter (D27), checks `grouped?` (D25) |
| `GroupJoiner` | `Groups::Joiner#join!` | |
| `GroupDirectRequester` | `Groups::JoinRequester#request!` | Spec: "Request to join". Requests are for confirmed groups only (D28). Closed by policy from P2b until P4c (D29) |
| `GroupDirectInviter` | `Groups::Inviter#invite!` | Drops vestigial `direct_` (I4) |
| `GroupInviteResponder` | `Groups::InviteResponder#accept!` / `#decline!` | Handles requests and invitations |
| `GroupInviteLinkGenerator` | `Groups::InviteLinkGenerator#generate!` | |
| `GroupInviteLinkRedeemer` | `Groups::InviteLinkRedeemer#redeem!` | |
| `GroupConfirmer` | `Groups::Confirmer#confirm!` | Student leader. Course lock first, then group (D21). Gives the lowest free G### (D27) |
| `GroupReverter` | `Groups::Reopener#reopen!` | D4. Blocked with `:has_project` (D9) and `:imported_group` (origin, done in P1b). Course lock first (D21). Releases the G number and gives a new Tmp### (D27) |
| (new, D6) | `Groups::Coordinator::Confirmer`, `Groups::Coordinator::Reopener` | Window closed allowed; Reopener blocked with a proposal; lecturers and students cannot call them (T15). Course lock first (D21) |
| `GroupMemberAdder` | `Groups::Coordinator::MemberAdder#add!` | Coordinator only |
| `GroupMemberRemover` | Split three ways: `Groups::Leaver#leave!`, `Groups::Kicker#kick!`, `Groups::Coordinator::MemberRemover#remove!` | See below |
| (new) | `Groups::Coordinator::Importer` | C1. Coordinator, no window check, creates confirmed groups with the first CSV member as leader, no sequence and `origin: import`. Takes the course lock (D21) and sets `course_id` on the members (B3) |
| (new, D11) | `Groups::Coordinator::GroupDeleter`, enrolment-removal handler | Names tentative. Enrolment removal shares `Coordinator::MemberRemover` (D11). GroupDeleter warns before deleting a group with a project (D23) |
| `GroupLeadersController#update` (writes `leader_id` directly) | deleted (D26) | The endpoint, route, `promote_leader?` and both promoter services are removed. Succession stays inside `Leaver`, `Kicker` and `Coordinator::MemberRemover` |
| `GroupsController#update` (toggles `locked`) | deleted (D28) | The approval-toggle services, the action, the route and the Manage switch go in P2b; `locked` is dropped in P2b Part 2 |
| `GroupsController#destroy` (leader deleting a not-confirmed group) | `Groups::Deleter#delete!` | R12. Window open, not confirmed, group lock. Coordinator delete is `Coordinator::GroupDeleter` above |
| (new, O3) | grouping settings saved under the course lock in `handle_settings` | Takes the course lock (D21) |
| `Queries::GroupSizeConfirmabilityCalculator` | unchanged | Renames only, per D1 |

- **Leaver (self):** window required, not-confirmed groups only (D7, blocked with `:group_confirmed` otherwise, leader included), promotes leader, last member deletes the group. Refuses whenever the group has a project, whatever the request params (D23).
- **Kicker (leader):** window open, not confirmed.
- **Coordinator::MemberRemover:** any state, no window check, no status change, promotes a leader. Last member with a proposal needs a server-side confirm step and deletes group and proposal only after it (D23). Enrolment removal shares it.

This removes the actor branching in the old `remove!`. The controller picks by `current_user == member.user` and by role.

### Phase impact

- **P1b:** goes first. Builds `Groups::Coordinator::Importer` (C1 to C3), the backfill migration (its own PR), and scopes the project validation to `on: :create` with the `:has_project` reopen block (O9, D9). Rev 4: also B14 (project group lock and unique index, R4, R5). Rev 5: also B3 (`course_id` on members and the unique index, R1), because the Importer sets `course_id`. Rev 9: DONE, including the `origin` column.
- **P2:** the remover split lands here (`Leaver`, `Kicker`, `Coordinator::MemberRemover`), written against D7. B4 and T5 are dropped. Rev 4: also the R12 services (approval toggle, delete; leader promotion was dropped in rev 6, D26) and the server-side confirmation (E1, E2). Rev 5: also the `ProjectGroupMemberPolicy#destroy?` change (D7, T32) and the I8 residual check.
- **P2b (rev 9):** the D28 cleanup in two PRs: remove the approval toggle, close join requests, delete pending requests; then drop `locked`.
- **P3a:** O2 (coordinator removal and enrolment removal one path). Rev 4: course lock in the confirmers (R3), `:group_gone` (R9), invite cleanup callback (E4), mail after commit (E6). Rev 5: B13 (proposed). B3 moved to P1b. Rev 9 (D31): the shared cleanup also clears a student's pending requests when they land in any group or leave the course, project creation clears the group's pending requests and invites, and Responder re-checks enrolment and ungrouped state at accept time.
- **P4:** Rev 8: the D27 Tmp counter (replacing the D17 counter). B7 is the D3 work; O5 is the D10 column drop and `manage_groups?` deletion; D13 deletes `destroy_draft_groups`; I11 to I13. Rev 4: name index, `ensure_grouped` guards (E3), grouping settings saved under the course lock in `handle_settings` (R11).
- **P4b:** D6 coordinator Confirmer and Reopener, O4 policies (with the D9 condition), O11 banner, O14 Overview. Rev 8: numbering (D27). Rev 9: reopen deletes the group's pending requests (D31).
- **P4c (rev 9):** D29 and requests reopen: `JoinRequester` and its policy allow confirmed groups, accepting a request, invite or link into a confirmed group reopens it, the `origin` guards in every student write service, request expiry (once decided).
- **P5:** blocked on D2.
- **P7:** becomes the `Groups::` move plus the rename map. Rev 8: the `locked` rename is gone (D28). The `direct_` prefix rename (I4) lives here.

## 1c. Answers recorded in rev 3

| Question | Recorded answer |
|---|---|
| Leader backfill: should the P1b migration give the earliest member as leader to every group with members and no leader? | Yes, all courses (C1) |
| Importer A1: leader = first member in CSV order | Yes (C1) |
| Importer A2: reuse an existing group with the same name, without touching its status | Not a change: `find_or_create_by!(group_name:)` already reuses a group with the same name. Dropped as an assumption (C3) |
| Importer A3: don't move students who are already in a different group, and report them | Yes (C2) |
| D12 services: separate small coordinator services or one service with an override flag? | Separate, because a flag makes it easy to pass the bypass from a student path. Keep the name `Kicker`. Namespace `Groups::Coordinator::` |
| Reopen when a proposal exists: hide the button or show it disabled? | Hide it, with no explanation line (D9) |
| O11 banner and rows | As listed under O11 (2b), with the singular copy for one group |
| Students on the Groups tab: do students need to see projects and supervisors? | Yes, students keep seeing the Groups tab, so the pages stay separate |
| Entry points | As listed in 1d |
| Imported groups and `course_group_sequence` | Imported groups are left without a sequence; dropped from the importer and the migration (C1, D17) |

## 1e. Answers recorded in rev 4

| Question | Recorded answer |
|---|---|
| Group numbering: keep `MAX+1` or a GitLab-style counter? | Counter column; numbers are never reused (D17) |
| Unique `(course_id, user_id)` index on members? | Yes (B3, R1) |
| Course lock for everything that changes N? | Yes, always taken, for every writer of N (D21). Calculator untouched (D2) |
| One project per group: add as a new bug item? | Yes, B14, with a partial unique index on ProjectGroup owners only, because lecturers can own multiple topics (D22) |
| Waiter on a deleted group: 404 or handled? | Handled: shared helper returns `:group_gone` (R9) |
| Race tests transactional or not? | Non-transactional, with a canary (T7) |
| Does the audit cover supervisor capacity? | No. The owner will flag it separately; out of scope here |
| Where does the destroy confirmation live? | Server-side (D23, E1) |
| Coordinator deletes a group that has a project? | Warn, then delete, like the last-member rule (D23, E2) |
| Small lock-taking services for leader promotion, approval toggle and group delete? | Yes (R12, D12, D20). Leader promotion was dropped in rev 6 (D26) |
| Is a `grouped?` check needed on every write? | No. A group can only exist in a grouped course, so it is checked where groups are created (Creator, Importer) plus `ensure_grouped` on the controllers (D25, E3) |
| Stale invites from someone who left? | A callback on member destroy deletes them (D24, E4) |
| Withdraw feature for invites and requests? | Not wanted (E5 dropped) |
| Mail enqueue after the lock? | Yes (E6) |
| Can groups be renamed? | No. Group rename does not exist (I11, D10) |
| Re-audit B1, B2, I8 against HEAD? | Yes, first thing in P1 (done in rev 5) |

## 1f. Answers recorded in rev 6

| Question | Recorded answer |
|---|---|
| Keep a promote-leader endpoint? | No. It was already marked stale in `FRONTEND.md` and `OPEN_ITEMS.md`; R12 specified services for it by oversight (D26) |
| Can a coordinator pick a new leader? | No. The leader changes only by succession (B9, D11, T20). Staff choose the leader when they create a group; the Importer uses the first CSV member (C1) |
| Does removing a leader still hand leadership on? | Yes, to the earliest remaining member, ordered by `created_at, id` |

## 1g. Answers recorded in rev 9

| Question | Recorded answer |
|---|---|
| Should join requests also be blocked on not confirmed groups? | Yes. A not confirmed group takes direct joins; the requester refuses it with `:group_not_confirmed` (D28, D31) |
| How are requests closed for confirmed groups until D29 exists? | `ProjectGroupPolicy#request_to_join?` returns false (explicit policy exception in P2b). The service keeps the final rule; P4c flips the policy line |
| What happens to existing pending requests at the D28 deploy? | A data migration in P2b deletes them all (D31) |
| When else are pending requests deleted? | When the student lands in any group (coordinator add included), when the group is reopened, when a project is created, when the student leaves the course (D31) |
| Does the accept step re-check the student? | Yes: still enrolled and not in a group (D31, B6, R10) |
| Do requests expire? | Not decided (1h) |
| One PR or two for D28? | Two: P2b Part 1 (code) and Part 2 (drop `locked`) |
| Does D28 rename the `direct_` wording? | No. Renames stay in P7 (I4); a rename never ships with a behaviour change |
| Which `origin` guards exist now? | Only Reopen (service and policy). Every other student write service already refuses a confirmed group, so the other guards come with P4c |
| Rebase onto main? | Deferred; before merging to main |
| `ProjectGroupPolicy#update?` after the toggle is gone? | Stays for `edit?`; cleaned up with D10 in P4 |

## 1h. Open decisions and not checked (rev 9)

Decisions for the owner:

1. **D30, Groups tab content (PROPOSED).** Blocks O11, O14, O7, O8 and the UI side of P4b. If adopted it needs a superseding ADR for 0024, changes `groups_with_status`, changes "Students keep the Groups tab" (1c), and needs an answer for where coordinators see unconfirmed groups while formation is open.
2. **Request expiry (D31).** A time limit or clear-on-window-close. Recommended: a time limit. Blocks P4c.
3. **Confirmed-group cap in prevent-leftover mode (Q5, D2).** Group max or the quota? Owned by the other reviewer; blocks P5 and T10.
4. **How an imported group looks on group formation.** Students in one have no actions; what do they see? Needs its own UX pass before the `origin` UI hiding is built (P4c).
5. **The UX items reopened by D27 to D29.** To be listed when the UX pass happens.
6. **The "Tmp" label.** Stays for now.

Not decisions, but unfinished:

- The routes check: confirm that no group route looks a group up by name (unverified).
- The read-only production checks in section 8 (origin fingerprint, D28 locked groups and pending requests).
- T23: the backfill dry run on a restored production copy.

## 1d. Entry points, gates and empty states

Entry points:

- The Groups tab is the only nav entry.
- A "Group formation" button on the Groups tab, shown while grouping is enabled.
- Overview says "Find or create a group" for students, and shows a summary card for coordinators. The Overview CTA links straight to formation.
- Keep the normal tab strip on the formation page.
- No formation entry after close.

Entry gates:

| State | What shows |
|---|---|
| Grouping off | No button. Students see the closed message; coordinators see the settings empty state |
| On, window starts later (if there's a start date) | "Group formation opens on {date}", no button |
| Open, student without a group | "Find or create a group" to formation, plus the Groups tab button |
| Open, student in a group | Group status line, with a link to formation |
| Window ended | Closed message, no formation button. Coordinators get the banner if groups are unconfirmed |

Overview empty states:

- `_project_details_card` already splits coordinator and non-coordinator copy, and the coordinator version has a Settings button. Add the same kind of presenter flag for grouping.
- Coordinator: "Group formation is closed. Enable it to let students form groups." with a Settings button.
- Student: "Group formation is closed. Contact your coordinator if you are not in a group yet."
- Lecturer: the same read-only message as students, minus the contact line.
- "Closed" has two causes, grouping off or the window passed. Both end at the settings page, so one message works for both.
- A student with no group in a closed-window course currently sees the "Browse groups" CTA, which leads to a closed page. The new empty state fixes that too.

Formation page after close:

- Students can still reach the formation URL from emails after close, so that page needs a read-only closed state. **Checked in rev 4:** it already has one. `group_formations/show.html.erb` (around lines 101-105) renders an empty state "Grouping is closed by your coordinator" with "Your existing groups are still visible on the Groups tab". Two gaps: the heading is wrong when the window simply ended by date (grouping was not closed by the coordinator at that moment), and it shows no status for the student's own group. Replace the copy with the closed message above and add the own-group status line.

## 2. Bug register

| ID | Sev | Where | Problem | Fix | Phase | Status |
|---|---|---|---|---|---|---|
| B1 | High | `group_members_controller.rb#destroy`; `group_formations/show.html.erb:169-174`; `groups/edit.html.erb:69,174-177`; `group_members/_dissolve_warning_modal` | Re-audited against HEAD. T1 passes; the redirect path updates state correctly. No stale DOM observed | Re-audited; tests pass. No change required | P1 | DONE |
| B2 | Med | same controller, `result.blocked?` stream branch | Re-audited. The blocked path redirects with an alert; T3 covers it | Re-audited; tests pass. No change required | P1 | DONE |
| B3 | High | `project_group_members` schema; Creator locks course, Joiner/Redeemer/Responder/Adder/Remover lock the group | One-group-per-student-per-course is enforced only by `exists?` checks under different locks, so concurrent create/join or joins to two groups can put a student in two groups. Production checked 2026-11-02: no student is in two groups of a course, so the index applies cleanly | Migration: add `course_id` to `project_group_members` (backfill from group), unique index `(course_id, user_id)`, set via the association; rescue `RecordNotUnique` as `:already_grouped` in every adding service. Keep `exists?` only for the friendly message. Decided in rev 4 (R1); moved to P1b in rev 5 because the Importer sets `course_id`. Implemented as one helper, `ProjectGroupMember.add(user:, group:)`, which inserts inside a savepoint and returns false on the unique violation; Creator, Joiner, Responder, Redeemer, Adder and the Importer use it | P1b | DONE |
| B4 | Med, unverified | `GroupMemberRemover#legal_at_current_size?` -> `ProjectGroup#confirmable?` -> `Course#unconfirmed_students_count` | For an already-confirmed group, N excludes the group's own members, but `confirmable_size?` subtracts the group's size again, so a valid group can be reverted (remainder can go negative) | Dropped under D7: coordinator removal no longer reverts, so `legal_at_current_size?` is deleted. Reinstate (N = unconfirmed + own size) only if D7 goes the other way | P2 | DROPPED (D7) |
| B5 | Med | `Queries::GroupSizeConfirmabilityCalculator#confirmable_size?` | Does not implement the spec quota model: e.g. N=10, min 2, max 5, spec gives 5+5, code also confirms a group of 2 or 4 (more groups than necessary, unbalanced) | Depends on D2 | P5 | BLOCKED (D2) |
| B6 | Med | `GroupMemberAdder#add!` | `already_grouped` and `group_full` checked before `with_lock`; no enrolment/role check in the service (controller guards with `@course.students.find`); does not clear the student's pending invites/requests | Move checks inside the lock, require enrolled student, call shared invite cleanup (B8). Rev 9 (D31): Responder re-checks at accept time that the student is still enrolled and ungrouped | P3a | TODO |
| B7 | Med | `GroupJoiner#join!` | `group_max.to_i` makes a nil max equal 0, so every group reads as full. All other services use `group_max.present? &&` | Same nil handling everywhere (see D3) | P4 | TODO |
| B8 | Med | Joiner, Redeemer, Responder, Adder | Clearing conflicting invites is implemented three ways: Joiner clears only own requests, Redeemer/Responder clear sent or received, Adder clears nothing. Spec: after joining anywhere, other pending invites and requests disappear | One method, e.g. `ProjectGroupInvite.clear_pending_for!(user, course)`, used by all four. Rev 9 (D31): it also clears a student's pending requests whenever they land in any group, coordinator add included, and it runs when a request into a confirmed group is accepted (D29) | P3a | TODO |
| B9 | Low | `GroupMemberRemover` | `@member` not reloaded inside the lock (Responder reloads its invite); `promote_next_leader!` orders by `created_at` only | Reload member inside lock; order by `created_at, id` (apply in Leaver, Kicker and Coordinator::MemberRemover) | P2 | DONE |
| B10 | Low | `GroupInviteLinkGenerator`, `GroupInviteLinkRedeemer` | Window/confirmed checks outside the lock in the generator; expiry checked outside the lock in the redeemer; generator only replaces links by the same sender (two live links after a leader change); token is 8 bytes | Move checks inside lock, replace all links of the group, 16-byte token | P4 | TODO |
| B11 | Low | `GroupsController#update`, `#destroy`, `GroupLeadersController#update` | `rescue StandardError => e` then `alert: e.message` leaks internals and hides bugs. `GroupDirectInviter`/`Requester` map any `RecordInvalid` to `:already_invited` / `:already_requested` | Remove broad rescues; rescue only `RecordNotUnique`/the specific validation. (`GroupsController#update` and `#destroy` became services under R12, so their rescues go with them; `GroupLeadersController#update` is deleted under D26) | P4 | TODO |
| B12 | Low | `ProjectGroup#has_project?` | Calls `.exists?` on a `has_one` (would raise). Unused. Note: D9 needs a working "group has a project" check, so write the replacement test-first rather than just deleting, or confirm one exists | Delete or replace (see D9, T14) | P4 | TODO |
| B13 | Low | `CoursesController` CSV import (both the grouped and the solo import functions) | The invite mailers are given `group_member[:email]` (and the solo equivalent), but the parsed hash has no `:email` key; the key is `email_address`. The invite emails go to a nil address | Use the `email_address` key. This is a behaviour change (invite emails start sending), so it is its own commit, not part of P1b | P3a (proposed) | OPEN |
| B14 | High | `ProjectsController#create`; `projects` schema (only the non-unique `index_projects_on_owner`) | One project per group is enforced only by `raise 'Your group already has a project' if group.project` inside a transaction, with no lock, no model validation and no unique index. Two members submitting at once, or one double-click, can create two projects for one group. `has_one :project` only means Rails reads the first. Unverified by running: write the failing test first (T25). Production checked 2026-11-02: no group has two projects today | Take the group lock inside project creation (D20, D22) and add the partial unique index `projects(owner_id) WHERE owner_type = 'ProjectGroup'`; rescue `RecordNotUnique` as the friendly error. The same lock serialises it against Reopener (R5). Production has no duplicates, so the index applies cleanly | P1b | DONE |
| B15 | Med | `GroupsController#coordinator?`; `ProjectGroupPolicy#coordinator?` | Both use `enrolments.find_by(user:)` with no role. `enrolments` has no unique index, so a user with both coordinator and lecturer rows is classified by whichever row comes first; the coordinator check can return false | Use `exists?(role: :coordinator)`, matching `GroupMembersController` and `ProjectGroupMemberPolicy`. Cover a lecturer-then-coordinator user in both the policy and the delete route | P2 follow-up | DONE |

### 2b. Ownership and overlap audit

Grouping logic leaks into course, enrolment, project and policy code. Read from the cloned branch and compared with main (FETCH_HEAD, 2026-10-22). Verified by reading unless marked unverified.

Who owns what today:

| Area | Where it lives | Should be owned by |
|---|---|---|
| Formation writes (create, join, invite, link, confirm, leave, kick, coordinator add/remove) | Group* controllers and 11 services | Grouping (`Groups::`, with coordinator actions under `Groups::Coordinator::`, D12) |
| Grouping settings transitions (disable, leave prevent-leftover mode, save min/max/window) | `CoursesController#handle_settings` plus `Course#disable_grouping!`, `#revert_to_default_mode!` | Grouping, called from course settings |
| CSV import of grouped courses | `CoursesController#create_db_entries_grouped`, `Course#parse_csv_grouped` | Not owned by grouping. Course import, but group rows created by Grouping (`Groups::Coordinator::Importer`). Items in 2c |
| Student removed from course | `EnrolmentsController#destroy` calls `GroupMemberRemover` | Enrolments, calling Grouping's coordinator removal (one path, D11) |
| Group list, search, status filter (read side) | `GroupsController#index` + `ParticipantBrowsing`, `PeopleController`, `GroupFormationsController#filtered_groups` | Two surfaces on purpose (ADR 0024); share the name-match predicate only |
| "The user's group in this course" | `current_user.project_groups.find_by(course:)` in courses, projects, topics, lecturers controllers; a join query in `GroupFormationsController` | One method (`Course#group_for(user)`) |
| Proposal needs a confirmed group | `Project#project_group_must_be_confirmed` | Projects, `on: :create` only (D9) |
| Group emails | six templates in `GeneralMailer` | A `GroupMailer` (rename with I5) |

| ID | Sev | Finding | Fix | Phase | Status |
|---|---|---|---|---|---|
| O1 | High | Moved to section 2c (C1) | - | P1b | see C1 |
| O2 | Med | `EnrolmentsController#destroy` passes `dissolve_confirmed: true`, so removing the last student from the course deletes the group and its proposal with no warning. The remove and `enrolment.destroy!` are not in one transaction. The student's pending invites and requests stay behind, and `GroupInviteResponder#accept!` has no enrolment check, so a leader could accept a request from someone no longer enrolled | One transaction. Drop `dissolve_confirmed` so enrolment removal shows the warning (server-side step, D23); coordinator removal and enrolment removal are one path (D11). Call `Groups::Coordinator::MemberRemover`; the current `confirm: true` is the P2 shim and is removed here. Take the course lock first, then group (D20, D21). Clear the student's pending invites with the shared helper (B8). Add the enrolment check inside the lock in Responder and Adder (B6, R10). A removed leader is replaced by the earliest member (T20). Rev 9 (D31): removing a student from the course also deletes their pending requests | P3a | TODO |
| O3 | Med | `handle_settings`: when Prevent leftover students is switched off, the elsif branch only reverts the mode and skips the else update, so min, max, open flag and dates edited in the same save are silently dropped. `Course#enable_auto_confirmability_mode!` is unused. Transitions sit in the controller inside a `rescue StandardError` that shows `e.message` | Grouping settings are saved under the course lock in `handle_settings`, applying the mode switch and the field updates in one update (D21, R11). Test the combined save | P4 | TODO |
| O4 | Med | `ProjectGroupPolicy#confirm?` and `#revert?` return true for anyone with `manage_groups?`, which contradicts the spec (coordinators cannot change group status). I found no staff Confirm or Reopen button in the views I searched, so it is reachable by direct request only; `GroupConfirmer` still blocks when the window is closed | Policies follow D6: coordinator confirm and reopen go through the `Coordinator::` services; lecturers and students cannot call them (T15). `reopen?` (formerly `revert?`) is also false when the group has a project (D9) | P4b | TODO |
| O5 | Low | Spec lists "lecturers manage groups" as a future setting, default disabled. Code has `courses.lecturers_can_manage_groups` default true with no UI, and OPEN_ITEMS.md item [F] says to drop it | D10: delete `manage_groups?` (11 call sites replaced with the coordinator check), migration drops the column, update OPEN_ITEMS.md [F]. A test relies on lecturer-as-staff (`group_formation_page_test.rb` lines 80-81): flip it (T31). Rebuild as a setting only when requested | P4 | TODO |
| O6 | Low | Same lookups written several times: user's group in course (5 places), ungrouped students (3), group/member name search (2) | `Course#group_for(user)`, `Course#ungrouped_students` (I6), one name-match helper | P4 | TODO |
| O7 | Low | Course (229 lines) owns grouping behaviour: `disable_grouping!`, `revert_to_default_mode!`, `unconfirmed_students_count`, `groups_with_status` (Groups-tab filtering), `parse_csv_grouped` (import parsing) | Move only when touched: settings transitions to O3's service, `groups_with_status` next to `ParticipantBrowsing`, CSV parsing with the import. `disable_grouping!` and `revert_to_default_mode!` stop calling `destroy_draft_groups` (D13) | P7 | TODO |
| O8 | Low | `GroupsController` serves the monitoring Groups tab (index, show) and the writes (create, edit, update, destroy). This overlap is intentional (ADR 0024, 0025) | Leave; no action beyond O6. Its writes move to services under R12 | - | WONTFIX |
| O9 | Med | `project_group_must_be_confirmed` runs on every save, not only on create. A confirmed group that already has a proposal and is reopened leaves the proposal owned by a not-confirmed group, so the lecturer's status change and the students' edits then fail with "cannot be a draft group". Unverified by running | D9 decided: groups with a proposal cannot be reopened (service reason `:has_project`, policy false), so the reopen path is closed. Remaining work: scope the validation to `on: :create`. Tests (T14): reopen blocked with a project (service and policy); editing a project still works after a status change | P1b | DONE |
| O10 | Low | Moved to section 2c (C3) | - | P1b | see C3 |
| O11 | Med | After students cannot act, not-confirmed groups can sit around with no student able to confirm them. Leftover groups can also sit around after grouping is off (D13) | Banner and rows, see O11 below | P4b | TODO |
| O14 | Med | Overview's `submission_state_for` returns `:no_proposal` for a student whose group exists but has no project, so a student in an unconfirmed group sees "Create proposal", which the project validation rejects. A student with no group in a closed-window course sees the "Browse groups" CTA, which leads to a closed page. **Rev 4:** `ProjectsController#new` does not stop them either: it only checks for an existing project, and `create` fails later ("not part of a group", or the draft-group validation) | Overview shows "waiting for your group to be confirmed" for that student. CTA reads "Find or create a group" and follows the gates and empty states in 1d. `ProjectsController#new` redirects a student with no confirmed group to Overview with the same message | P4b | TODO |
| O15 | Low | Production has 4 not-confirmed groups that already have a project (course 3: grouping on, `grouping_open` false, no open or close dates; 4 groups with 1, 2, 3 and 3 members). Course 3 is "Sandbox Group Approved Topic", the team's live testing course (about 6 people), so deleting it is not an option. The D9 invariant (a group with a project is confirmed) did not hold for them | **Decided (a), as a general rule:** the backfill confirms every not-confirmed group that already has a project, in every course, because a proposal needs a confirmed group. No course-specific backfill. Existing projects keep working either way, since the validation is `on: :create` | P1b | DONE (backfill step 2 covers groups that already have a project) |

#### O11: banner and rows

- Show the banner when students can't act (window closed or grouping off) and not-confirmed groups exist.
- Coordinators only.
- Copy: "Group formation is closed. 3 groups are not confirmed, so their members cannot submit a proposal. Review and confirm them." The singular form reads "1 group is not confirmed...".
- Yellow rows only in that state, quiet "Not confirmed" pill otherwise.
- Add "Not confirmed" to the existing status filter, since those groups can't have a proposal.
- Add the ungrouped-student count to the banner when closed.
- It also covers leftover groups after grouping is off (D13), not just "window closed".
- The banner flags the imported groups in courses where grouping is on, for the coordinator to confirm (C1 migration). Groups that already have a project are confirmed by the backfill (O15), so the banner never lists them.

Decisions D9 and D10 are recorded in section 1b. Phase additions: P1b (C1 to C3, O9, B3, B14) goes first because it is a possible regression for grouped-CSV courses. O2 joins P3a, O3 to O6 join P4, O7 joins P7, O4, O11 and O14 join P4b.

### 2c. CSV import (not owned by grouping, still blocking)

Ownership: CSV import is not owned by grouping. Because grouping touches it, these items still have to be debugged and are blocking. Items that don't directly break grouping are still bugs, and matter once grouping is enabled. Moved here from O1 and O10.

The importer assumptions apply when a coordinator uploads a CSV in a grouped course, in particular one that already has groups from an earlier upload or from group formation.

| ID | Finding | Fix | Phase | Status |
|---|---|---|---|---|
| C1 | CSV import creates groups that are unconfirmed, leaderless and without `course_group_sequence`. Project now validates `group.confirmed?` on every save (the validation is new on this branch; main's project.rb has none). A grouped-CSV course therefore cannot create a project, and no migration backfills confirmed for groups that existed before. Seeds set `confirmed: true` by hand, which hides it. Leaderless groups also break join requests today (`GroupDirectRequester` refuses a group with no leader). Unverified by running: write the failing test first. Production confirms the shape: 350 leaderless groups have members, and all of them are import-shaped (section 8) | Create imported groups through one grouping-owned entry point (`Groups::Coordinator::Importer`) as confirmed. A1: leader = first member in CSV order (the CSV has no leader column; the leader only changes through succession, D26). No sequence. Contract: coordinator-initiated, no window check. The Importer takes the course lock (D21) and sets `course_id` on the members it creates (B3). Add the P1b backfill migration below, as its own PR. Tests T13, T22, T23 Rev 8: the Importer also sets `origin: import` | P1b | DONE |
| C2 | When a student is already grouped, the import runs `update!(project_group: new_group)` and moves them. It never touches `leader_id` and never deletes the group it empties: a moved leader leaves the old group pointing at a leader who isn't a member, and a moved-out last member leaves an empty group. This breaks grouping rules, not just the CSV. Moving someone silently could pull them out of a group that already has a proposal | A3: leave the student in their group and report "Carol was already in a group and wasn't moved." Skip-and-report is also the conventional behaviour (3b). Test T13, T22 | P1b | DONE |
| C3 | Import quirks: a no-op `ProjectGroupMember.where(user:).pluck(...)` line, and `find_or_create_by!(group_name:)` can duplicate generated G### names. Reuse of an existing group with the same name is existing behaviour and is kept (A2 is not a change) | Fold into the importer. A unique index on `(course_id, group_name)` backs up the importer's reuse-by-name and fixes this (I11, D17). Production has no duplicate names (Q4, checked 2026-11-02) | P1b | DONE |
| C4 | Moodle keeps a separate, unique `idnumber` as a stable external id for imports; ProPro uses the group name as identity (3b) | Suggestion only | - | SUGGESTION |

P1b migration rule:

- Give every group that has members and no leader its earliest member as leader (all courses).
- Confirm imported groups only in courses where grouping is off. Nobody else can confirm them there, and project creation silently fails for those students now.
- In courses where grouping is on, don't change status, because students may be mid-formation. The O11 banner flags those groups for the coordinator to confirm. Exception: a group that already has a project is confirmed in every course (O15), because a proposal needs a confirmed group. This is a general rule, not a course-specific backfill.
- A group created through the app always gets a leader and a sequence number (`GroupCreator` sets both). A group that is unconfirmed with no leader and no sequence is therefore reliably a CSV import, whatever the course setting. Production confirmed this on 2026-11-02.
- Counted in production on 2026-11-02 (`confirmed = false AND leader_id IS NULL AND course_group_sequence IS NULL`, by course): 353 groups in 14 courses. 349 in 13 grouping-off courses will be confirmed. The 4 in course 3 (grouping on) already have a project, so the project rule confirms them too (O15). 350 leaderless groups with members will get a leader. Course 234's 3 fingerprint groups have no members; the backfill confirms them, which is harmless. Re-run the count before deploying, because a new import changes it.
- The migration prints how many imported groups it confirmed, how many groups it confirmed because they already have a project, and how many leaders it assigned, so the output can be compared with the counts above.
- Course 3 is "Sandbox Group Approved Topic", the team's live testing course (about 6 people). Deleting it would mean everyone joins again, so it is kept and the general project rule covers it.
- The backfill migration is its own PR, separate from the Importer, validation, lock and index changes, so it can be reviewed and deployed on its own.
- Don't set `course_group_sequence` for imported groups, in the importer or the migration. Nothing reads it besides `GroupCreator`, so a nil sequence isn't why project creation fails. Setting it also makes imported groups consume G### numbers that don't match their names.

### 2d. Race-condition audit (rev 4)

Scope: grouping writes only. Supervisor capacity and topic races are out of scope (the owner will flag them separately). ProPro was read at `3619ce7c` (Rails 8.0.2 in the branch lockfile, Rails 8.1.4 in production; Postgres, solid_queue; no Redis). Every item is from reading, nothing was run, unless marked.

Vocabulary: **serializing** means making concurrent requests run one at a time. A row lock (`with_lock`) does that: the second request waits, then runs its check against current data. A DB constraint (a unique index) needs no lock because the database refuses the second write itself. Where no constraint can express the rule, the check must be inside the lock; a check before the lock can go stale while the request waits.

Lock rules are D20; the course-lock set is D21. Short form: order course, group, enrolment; checks inside the lock; every group write through a lock-taking service; no external calls inside a lock.

#### Reference apps (cloned 2026-11-02 to `/home/claude/refs/`, sparse, depth 1)

| App | What was read | How it handles the same problem | What it means for ProPro |
|---|---|---|---|
| GitLab (`gitlabhq/gitlabhq`) | `app/models/internal_id.rb`, `app/models/concerns/atomic_internal_id.rb`, `lib/gitlab/exclusive_lease.rb` | `InternalId` keeps one counter row per scope and usage (for example per project and "issues"). It increments with one atomic `UPDATE ... SET last_value = last_value + 1 ... RETURNING`; if the row is missing it inserts it, initialised from `MAX(existing)`, and retries on a unique violation. The file states the sequence is unique, gapless, thread-safe and process-safe, and numbers are never reused. `ExclusiveLease` is a Redis lock with a TTL for cross-process work | The counter pattern is D17. The Redis lock does not fit (no Redis) |
| Canvas LMS (`instructure/canvas-lms`) | `app/models/group_membership.rb`, `app/models/group.rb` | Max size is a model validation (`validate_within_group_limit`, `Group#full?`) with no lock, so it is racy by design. "One group per category" is not a constraint: an `after_save` (`ensure_mutually_exclusive_membership`) destroys the user's other active memberships in sibling groups, so the last write wins and the system heals itself. DB indexes not checked | A useful contrast. Healing afterwards does not fit a "confirmed means final" model, so ProPro uses a constraint (R1) and locks |
| Discourse (`discourse/discourse`) | `lib/distributed_mutex.rb`, `app/models/group_user.rb`, `app/models/group.rb` | `group_users` has unique indexes in both directions, `(group_id, user_id)` and `(user_id, group_id)`; the DB is the real guard. `DistributedMutex` is a Redis mutex for cross-process work. `Group#add` goes through `GroupManager`, which was not read | The unique index is R1. The Redis mutex does not fit |
| Moodle (3b) | see 3b | Name uniqueness in application code, no counter | already recorded |

#### Races

| ID | Race | Current ProPro | Proposed | Phase | Status |
|---|---|---|---|---|---|
| R1 | Student ends up in two groups of one course (create vs join, or joins to two groups) | `exists?` checks under different locks: Creator locks the course row, Joiner, Responder, Redeemer, Adder and Remover lock the group row. No unique index on `project_group_members`. Production has no such student today | `course_id` on `project_group_members`, unique `(course_id, user_id)`; services rescue `RecordNotUnique` as `:already_grouped` (B3) | P1b | DONE |
| R2 | Group exceeds max | Count under the group lock in Joiner, Responder and Redeemer: fine. Adder checks before taking the lock | Adder moves its checks inside the lock (B6). Coordinators can override max anyway (D6), so this is low | P3a | TODO |
| R3 | Two groups confirm at once (write skew) | Confirmer locks only its own group, but `confirmable?` reads the course-wide `unconfirmed_students_count`. Each transaction sees the other group as unconfirmed, so both pass | Course lock first, then group, in every writer of N (D21). Calculator and `confirmable_size?` untouched (D2). In default mode the calculator ignores N, so the lock only matters in prevent-leftover mode, but it is always taken. Rev 8: joins into confirmed groups also change N, so those accepts take the course lock too (D29) | P3a | TODO (decided) |
| R4 | Two projects for one group | `ProjectsController#create` checks `group.project`, then creates. No lock, no unique index | Group lock inside project creation plus partial unique index on ProjectGroup owners (D22, B14) | P1b | DONE |
| R5 | Reopen vs project creation (D9) | Reopener locks the group; project creation does not, and the `confirmed?` validation reads unlocked | Same fix as R4: both take the group lock, so one wins and a project is never created on a group being reopened | P1b | DONE |
| R6 | Group number collision | `MAX(seq)+1` under the course lock, plus unique `(course_id, course_group_sequence)` | Tmp counter (D27); Confirm assigns the lowest free G### under the course lock; Importer also takes the course lock; unique `(course_id, group_name)` | P4 | TODO (decided) |
| R7 | Duplicate pending invite or request | Partial unique indexes (`idx_pgi_unique_pending_*`) plus `rescue RecordNotUnique` | No change. B11 narrows the rescue so a `RecordInvalid` is not mislabeled | - | OK |
| R8 | Checks outside the lock | Generator (window, confirmed), Redeemer (expiry), Adder | B6 and B10 | P3a, P4 | TODO |
| R9 | Waiter on a deleted group | `with_lock` reloads the row, so a Joiner waiting behind a Remover that deletes the group raises `RecordNotFound` (controller handling not checked) | One shared helper rescues it after `with_lock` and returns `:group_gone` | P3a | TODO (decided) |
| R10 | Enrolment removal vs join | Remove and `enrolment.destroy!` are not in one transaction; Adder and Responder have no enrolment check | O2: one transaction, course lock first; joining services check enrolment inside the lock | P3a | TODO |
| R11 | Settings change (min, max, window) vs concurrent join or confirm | Services read the course after taking the group lock; a settings save takes no lock | A join racing a settings save has the same outcome as the action landing a second earlier: accepted. grouping settings saved under the course lock in `handle_settings` so a save cannot land mid-confirm (O3, D21) | P4 | ACCEPTED (lock in `handle_settings`) |
| R12 | Group writes outside services | `GroupsController#update` (the `locked` flag) and `#destroy` write with no lock; destroy races a Joiner (R9) and project creation (R5). `GroupLeadersController#update` also wrote `leader_id` without a lock, but the endpoint is deleted (D26) | Lock-taking services for the approval toggle and group delete (D12, D20); rev 8: the approval-toggle services are deleted in P2b (D28), so only group delete remains. Leader succession already runs inside the group lock (`Leaver`, `Kicker`, `Coordinator::MemberRemover`), so an existing group has no unlocked writer of `leader_id` left | P2 | DONE |
| R13 | Course lock deadlock | `course.with_lock` uses plain `FOR UPDATE`; a join holding the group lock then inserts a member, whose FK needs a key-share lock on the course row. A coordinator write holds the course lock and waits for the group: Postgres aborts one with "deadlock detected" | Course writes use `FOR NO KEY UPDATE`, which does not conflict with the FK key-share lock (D20). A threaded regression races a coordinator removal against a join | P2 follow-up | DONE |

#### Further edge cases found in the same pass

| ID | Sev | Finding | Decision | Phase | Status |
|---|---|---|---|---|---|
| E1 | High | `GroupMembersController#destroy` passes `params[:dissolve_confirmed] == 'true'` straight to the remover. Anyone `ProjectGroupMemberPolicy#destroy?` allows, including the member themselves, can skip the "this deletes the proposal" step by sending that param. The warning is only a modal, not a server rule | D23: the flag leaves the student path. `Leaver` refuses whenever a project exists. Coordinator confirmation is a second, policy-checked request (T28) | P2 | DONE |
| E2 | Med | Coordinator "Delete group" on a confirmed group deletes the project (`has_one :project, dependent: :destroy`) with no warning. D11 only covered the last-member removal path | D23: warn, then delete, same rule as the last-member case (T28) | P2 | DONE |
| E3 | Med | `GroupsController` runs `ensure_grouped` on `index` and `show` only. Students are stopped because `grouping_window_open?` is false when grouping is off, but coordinator and lecturer paths have no window check, so a group can be created in a solo course. The other group controllers have no `grouped?` guard either. Unverified by running | D25: `ensure_grouped` on every group controller action; Creator and Importer check `grouped?`. The other services act on an existing group, so they need no check (T30) | P4 | TODO |
| E4 | Med | Invites sent by a member or leader who has since left or been kicked stay acceptable (the policy checks only the recipient). Accepting adds the student to a group whose inviter is gone. Pending join requests keep the old leader as `recipient_id` and the email went to them, but `accept?` uses the current leader, so the new leader can still accept | D24: `after_destroy` on `ProjectGroupMember` deletes that user's pending `direct_invite` records for the group; it also fires on `dependent: :destroy` paths (T29) | P3a | TODO |
| E5 | - | No way for a sender to withdraw their own invite or request (the policy only has `accept?` and `decline?`) | Not wanted | - | DROPPED |
| E6 | Low | `deliver_later` passes the invite by GlobalID. `clear_conflicting_invites!` and `dissolve!` delete invites, so a queued "new join request" email can fail with `DeserializationError`. Responder also enqueues mail inside `with_lock`. Whether solid_queue enqueues inside the transaction was not checked | Enqueue after the lock block commits; discard the mail job on `DeserializationError` | P3a | TODO (decided) |
| E7 | Low, unverified | `User has_many :project_group_members, dependent: :destroy` (and enrolment deletes) bypass leader succession and empty-group cleanup, and `project_groups.leader_id` has a foreign key to `users` with no `ON DELETE`, so deleting a leader's user record errors. Not checked: whether user deletion exists as a real path | Check for a real deletion path; if it exists, route it through `Coordinator::MemberRemover` | P3a | OPEN |
| E8 | Low, unverified | The window has two sources of truth: the `grouping_open` flag and the opens/closes dates. Nothing flips the flag when `grouping_closes_at` passes, so any code reading `grouping_open?` directly instead of `grouping_window_open?` is wrong after close. Not grepped | Grep for raw `grouping_open` reads and replace them with `grouping_window_open?` | P4 | OPEN |

#### Test infrastructure finding (unverified by running)

The existing thread race tests (Creator, Joiner, Responder, Requester) live in `ActiveSupport::TestCase` classes with Rails' default transactional tests, and `test_helper.rb` has no `use_transactional_tests = false`. With transactional tests Rails shares one DB connection across threads, so both "concurrent" threads sit in one transaction and row locks cannot conflict. These tests may pass without testing concurrency at all. `GroupWriteLockTest` opts out and runs its race against committed rows.

- Canary: remove `with_lock` from `GroupJoiner` (`@group.with_lock do`, line 9) and run its thread test. If it still passes, the test is vacuous.
- Fix: put race tests in non-transactional test classes (`self.use_transactional_tests = false` with DatabaseCleaner truncation, as `ApplicationSystemTestCase` already does). Keep the canary as a written check in the PR description whenever a race test is added (T7).

## 3. Inconsistencies and structure

| ID | Finding | Action | Phase | Status |
|---|---|---|---|---|
| I1 | 11 hand-rolled nested Result classes. Inconsistent API: `blocked?` missing on Confirmer/Reverter, Remover and Responder use an outcome enum. service_classes.md mentions a `ServiceResult` module that does not exist. GitLab uses one shared `ServiceResponse` | One shared result (`success?`, `blocked?`, `reason`, optional data); keep per-service reason symbols | P6 | TODO |
| I2 | User-facing strings live in service `Result#message` and are duplicated (window-closed text in ~8 places, 3 variants of "maximum size") | Move to one locale file keyed by service and reason | P6 | TODO |
| I3 | `Queries::GroupSizeConfirmabilityCalculator` has `def self.feasible_count?` (docs say avoid class methods) and a `Result#message` with view copy ("Enter a student count greater than 0.") | Make instance method; move copy to view/locale | P6 | TODO |
| I4 | `direct_request` / `direct_invite`, `GroupDirectInviter`, `GroupDirectRequester`, mailer `Group_Direct_*`: the `direct_` prefix looks vestigial since links got their own table (`reshape_project_group_invites`). Controllers already say join_requests / invitations | Rename enum to request / invite and services to match (needs data migration of `kind` values: keep integers, rename only) | P7 | TODO |
| I5 | Mailer actions are `Group_Direct_Invite_Notification` etc. (capitalised) | snake_case | P7 | TODO |
| I6 | "Ungrouped students" computed in `GroupFormationsController#show`, `GroupsController#ungrouped_students`, and `groups/edit` | `Course#ungrouped_students` | P4 | TODO |
| I7 | Dead code: `ProjectGroup#revert_to_draft!`, `#pending_requests` (test only) | Delete (and the test) | P4 | TODO |
| I8 | `redirect_back` used in `GroupMembersController`; fragile (Referer dependent). Re-audited with B1: it uses `redirect_back` with a fallback to the formation path, tested via T1 to T3. Acceptable for now. **Residual, unverified:** a coordinator removing the last member from a group's edit page may be redirected back to the deleted group's page. Check it when the action is rewritten in P2 | Re-audited; tests pass. Add one test for the last-member case in P2 | P1 | DONE |
| I9 | `GroupConfirmer` comment typo ("comfirms"); mixed capitalisation of "Not Confirmed" | Fixed by wording pass | P7 | TODO |
| I10 | `GroupFormationsController` loads all groups and filters in Ruby via `helpers.group_size_state` | Leave until pagination/perf is an issue | - | WONTFIX for now |
| I11 | `group_name` has no uniqueness: no DB index, no model validation, although the importer uses the name as identity and Creator generates it. Moodle validates name uniqueness per course in application code (3b). **Rev 4:** names cannot be edited (no rename path exists on this branch; Q8 answered), so there is no rename race to handle | Unique index `(course_id, group_name)` plus `validates :group_name, uniqueness: { scope: :course_id }` on `ProjectGroup`. Production checked 2026-11-02: no duplicates (Q4), so the index applies cleanly. Rev 8 (D27): Confirmer and Reopener rename the group (Tmp### to G### and back) in one transaction under the course lock | P4 | TODO |
| I12 | `course_group_sequence` has exactly one reader: `GroupCreator` (computes the next number and builds `G%03d`). Nothing displays or sorts by it | Keep the column and its unique index as the stored value. Creator now takes the number from the counter (D17). Add a code comment saying nothing else reads it. Importer leaves it nil (C1). Rev 8 (D27): the counter now numbers Tmp groups and Confirm assigns the lowest free G###; how `course_group_sequence` stores the G number is settled in P4 | P4 | TODO |
| I13 | `GroupCreator` uses `MAX(sequence) + 1`, which ignores names held by imported groups: a CSV group named `G003` and a generated `G003` can both exist | Under the course lock, increment the counter; if the generated name is taken, take the next number (T21). Rev 8 (D27): applies to Tmp numbers; G numbers are the lowest free | P4 | TODO |
| I14 | Sequence numbers are reused when the highest group is deleted, and leave gaps otherwise; names already appear in sent emails | **Rev 4:** fixed by the counter column (D17): a number is never reused. After a delete the next group skips the freed number, so the visible list can have gaps (G001, G003). This is intended. Rev 8 (D27): applies to Tmp numbers only; a freed G number can be handed out again | P4 | TODO (decided) |

### 3b. Group naming and sequence audit (rev 3)

Read: ProPro `GroupCreator`, `db/schema.rb` (`project_groups`), `ProjectGroup`, every reader of `group_name` and `course_group_sequence`. Moodle `main` (cloned 2026-11-02): `public/group/lib.php`, `autogroup.php`, `group_form.php`, `import.php`, `public/lib/db/install.xml`, tests `public/group/tests/lib_test.php`, `public/lib/tests/grouplib_test.php`, behat `auto_creation`, `id_uniqueness`, `groups_import`. Group self-selection plugin (BLC-HTWChur/moodle-mod_groupselect): `view.php`, `db/install.xml`. Rev 4 adds GitLab `InternalId` (2d).

Sequence in ProPro, as read:

- `course_group_sequence` has exactly one reader: `GroupCreator`. It computes MAX + 1 inside the course lock and builds `G%03d`. Nothing displays or sorts by it, because the table sorts on the `group_name` string.
- The DB enforces a unique index on `(course_id, course_group_sequence)`. `group_name` has no index or validation, even though the importer treats the name as identity.
- Deleting the highest group frees its number, so the next group reuses it. Deleting a middle one leaves a gap.
- The name is a stored copy of the number, and imported groups carry arbitrary CSV names, so "G001" and "Team Alpha" end up in the same column.
- A per-parent number from `MAX + 1` under a row lock, with a unique index as a backstop, is a recognized pattern, similar to per-project issue numbers. The sturdier variant is a counter column on `courses`, which never reuses numbers. Deriving the name from the id or from list position would be worse: ids are unreadable, and positions renumber on delete. The spec already picks G### names.

| Topic | ProPro today | Moodle core | Group self-selection plugin | Outcome |
|---|---|---|---|---|
| Stored sequence | `course_group_sequence` integer, unique index `(course_id, course_group_sequence)`; one reader (Creator) | None. Autogroup builds names from the loop index with `groups_parse_name`: `#` becomes n+1 (unpadded), `@` becomes A, B, C | None. A blank name becomes the highest numeric group name in the course plus one, read at creation, no lock | ProPro is stricter than both. Keep, now fed by a counter (D17) |
| Name uniqueness | None | Column documented as unique, but no unique DB index (only a non-unique index on `idnumber`). Enforced in application code with `groups_get_group_by_name` in the group form, autogroup preview and creation, and import. `groups_create_group()` itself does not check names | None; students may name groups freely | Add validation and index (I11) |
| Name collision | Not handled (generated vs imported) | Autogroup preview flags "name exists" and creation aborts (`failed = true; break`); it does not renumber | Two concurrent blank-name creates can read the same maximum | Creator takes the next number and retries (I13) |
| Stable external id | The name is the identity for import | Separate `idnumber`, unique, checked in `groups_create_group` (throws `idnumbertaken`); behat `id_uniqueness` covers create and edit | n/a | Suggestion C4 |
| Import of an existing name | Reuses the group, moves students | Import prints "group exists for the course" and creates nothing; a duplicate `idnumber` warns and creates the group without it; behat `groups_import` covers both and unknown courses | n/a | Skip-and-report is the conventional behaviour (C2) |
| Size limits | Min and max; students blocked, coordinators override (D6) | n/a | Min: warning icon and a notice to members of undersized groups. Max: blocks joining; members of a group above the max get a notice, so groups can exceed it | Matches D6 and D15 (warnings for staff overrides) |
| Empty groups | Group deleted when the last member goes (with warning when a proposal exists) | `groups_delete_group` | Option `deleteemptygroups`, default on (`view.php:287`) | Matches D11 |
| Tests | Thread race tests for Joiner, Responder, Creator (may be vacuous, 2d) | Unit tests for events, deleting members and groups, autogroups, name and idnumber lookups; behat for naming scheme, uniqueness, import. I found no concurrent-creation test | No `tests` directory | Add T21, T22, T24 |

Neither Moodle component has a per-course counter or a confirm state, so the sequence is an extra feature, not a Moodle convention. A per-parent number from `MAX + 1` under a lock with a unique index is still a standard, defensible pattern, and the spec chooses `G001` names. **Outcome D17 (DECIDED, rev 4):** counter column on `courses` (GitLab `InternalId` pattern, 2d), numbers never reused; name uniqueness (I11); Creator takes the next number when a generated name is taken (I13); imported groups keep their CSV names and no sequence (C1); the visible list may have gaps after deletes (I14). Our `%03d` padding sorts correctly up to 999; Moodle's unpadded `#` does not. **Rev 8:** D27 supersedes D17. The never-reused counter now numbers Tmp groups only; Confirm gives the lowest free G###, and Reopen releases it and gives a new Tmp###.

## 4. Wording and schema rename map (P7)

Do after D1 is settled. Pure rename, no behaviour change. Postgres `rename_column` keeps data; schedule around the Heroku deploy.

| Current | Spec term | Touches |
|---|---|---|
| `courses.student_list_finalised` | Prevent leftover students (`prevent_leftover_students`) | column, Course validation/methods, calculator `finalised:`, `grouping_settings_controller.js`, `courses/settings.html.erb`, `courses_controller.rb`, ~50 test references |
| `Course#enable_auto_confirmability_mode!`, `revert_to_default_mode!`, "Auto-Confirmability" / "Default mode" in comments and docs | Prevent leftover students on/off | model, controller, docs |
| "draft" (`destroy_draft_groups`, `:already_draft`, `status_filter=draft`, Project validation "cannot be a draft group", comments) | not confirmed | models, services, controller, view option value, tests (`destroy_draft_groups` itself goes away in D13) |
| `project_groups.locked` | (removed, D28) | No rename. The toggle, the services and the column are deleted in P2b |
| "dissolved" in user-facing text ("Group dissolved.", "...was dissolved.") | deleted | remover and groups controller messages (internal `:dissolved` outcome may stay) |
| "The grouping window is closed." | "Group formation is closed." | all services (via locale file) |
| "Not Confirmed Group G001 created.", "already a Not Confirmed Group", "Group status changed to not confirmed." | "Group Tmp001 created." (D27), "already not confirmed", "Group reopened." | creator, reverter |
| revert / `GroupReverter` / `revert?` | Reopen (see D4) | service, policy, controller |
| "Browse groups" (Overview CTA) | "Find or create a group" | `_overview_tab.html.erb` (O14) |
| "Grouping is closed by your coordinator" (formation page empty state) | "Group formation is closed." | `group_formations/show.html.erb` (1d) |

## 5. Test plan

Current: 3 system tests (all real Chrome: htmx search, lazy Manage frame, `<dialog>` confirm; justified), 28 integration tests in `group_write_routes_test.rb` (mostly permission checks, redirects and DB state, never page content), the removal and group-write service tests, and `GroupWriteLockTest`, which is non-transactional and thread-driven. The older Creator/Joiner/Responder/Requester thread tests remain transactional and may not test concurrency (2d).

| ID | Test to add | Type | Phase | Status |
|---|---|---|---|---|
| T1 | After leave, formation page has no own-group panel and the groups table no longer lists the user (B1). Passes against HEAD | rack_test system | P1 | DONE |
| T2 | After coordinator removal, group row count updates; status does not change (B1, D7) | rack_test system | P1 | DONE |
| T3 | Blocked removal shows an alert (B2). | rack_test system | P1 | DONE |
| T4 | Unit tests for the three removal services. **Leaver:** self-leave from a not-confirmed group; blocked when confirmed (leader included); window closed; leader succession; last member deletes the group; stale or already-removed member; refuses when the group has a project whatever the params (D23). **Kicker:** blocked when confirmed or window closed; non-leader blocked. **Coordinator::MemberRemover:** any state and window; status never changes; promotes a leader; last member with a proposal needs the server-side confirmation step and deletes group and proposal only after it. Also the I8 residual: removing the last member from the group's own edit page does not redirect to a deleted page | unit | P2 | DONE |
| T5 | Confirmed-group re-check arithmetic (B4) | unit | P2 | DROPPED (D7) |
| T6 | DB constraint: second membership in same course raises `RecordNotUnique` (trigger with insert/update_column, per testing.md) | model | P1b | DONE |
| T7 | Races, in **non-transactional** test classes (`use_transactional_tests = false`, DatabaseCleaner truncation, as the system tests do): create vs join, join to two groups, Redeemer last slot, Confirmer double submit, Remover double removal, two groups confirming at once (R3, T27). Canary for each new race test: remove the `with_lock` (or the unique index) it relies on and confirm the test fails | unit (threads) | P3a | TODO |
| T8 | Replace the two tests that assert known bugs in `group_member_adder_test.rb` ("this is the bug", "CURRENT BEHAVIOR") with regression tests for the fixed behaviour. Move the existing Joiner, Responder, Creator and Requester thread tests into the non-transactional class and run the canary on each | unit | P3a | TODO |
| T9 | nil `group_max` across Joiner/Redeemer/Responder/Inviter/Adder (per D3) | unit | P4 | TODO |
| T10 | Property test: random confirm orders under prevent-leftover mode never leave a student set that cannot be legally grouped (per D2) | unit | P5 | TODO |
| T11 | Happy-path rack_test system tests: create group, join open group, request and accept, invite and accept, invite link, confirm and reopen, coordinator add. Use text/DOM; add `data-testid` only where markup breaks a test | system | P8 | TODO |
| T12 | Use `with_clues` in the browser tests in `group_formation_test.rb` | system | P8 | TODO |
| T13 | C1 regression: import a grouped CSV, then a member creates a project (fails before the fix). Imported groups are confirmed with a leader and no sequence. Re-import: a student already in another group is not moved, is reported, and no leaderless or empty group results | integration | P1b | DONE |
| T14 | O9 / D9: reopen is blocked for a group with a project (service reason `:has_project` and policy false, coordinator included); editing a project after a status change still works (validation `on: :create`); `has_project?` works | unit + policy | P1b | DONE |
| T15 | D6: `Coordinator::Confirmer` confirms undersized and oversized groups and works with the window closed; `Coordinator::Reopener` works with the window closed and is blocked with a proposal; lecturer and student cannot call them; a student leader still cannot confirm an illegal size | unit + policy | P4b | TODO |
| T16 | `Coordinator::MemberAdder` adds above max; status unchanged; size warning shows | unit | P3a | TODO |
| T17 | D13: `disable_grouping!` and `revert_to_default_mode!` keep not-confirmed groups (flip the two existing "destroys" tests) | model | P4 | TODO |
| T18 | O14: a student in a not-confirmed group sees no "Create proposal"; `ProjectsController#new` redirects a student with no confirmed group; the closed message differs for coordinator, lecturer and student; the CTA shows only when formation is open (gates in 1d) | rack_test system | P4b | TODO |
| T19 | O11: banner and yellow rows appear only when students cannot act and not-confirmed groups exist; singular and plural copy; ungrouped count; "Not confirmed" filter; coordinators only | rack_test system | P4b | TODO |
| T20 | O2 / D11: enrolment removal of a last member with a proposal shows the warning and deletes nothing until confirmed (server-side step, D23); the removal and `enrolment.destroy!` share a transaction; a removed leader is replaced by the earliest member; pending invites are cleared | integration | P3a | TODO |
| T21 | I11, I13, D17: duplicate group name rejected; Creator takes the next number when a generated name is taken by an imported group; two concurrent creates produce two names; after deleting the highest group the next number is not reused. Rev 8: this is the Tmp number; a freed G number can be handed out again (T34) | model + unit (threads, non-transactional) | P4 | TODO |
| T22 | Importer unit tests: confirmed groups with the first member as leader; reuse by name leaves status; student in another group is skipped and reported; no empty group when all members are skipped; works with the window closed; takes the course lock; sets `course_id` on members; sets `origin: import` | unit | P1b | DONE |
| T23 | P1b backfill migration, run on a restored copy of production before deploy: idempotent (a second run changes nothing); leaders given to every group with members and none; only fingerprint groups confirmed, only in grouping-off courses; grouping-on courses untouched except groups that already have a project. On the 2026-11-02 data it prints "Confirmed 349 imported groups and 4 groups that already have a project; assigned a leader to 350 groups"; afterwards no leaderless group has members, no fingerprint group is unconfirmed in a grouping-off course, and no group with a project is unconfirmed. Re-run the counts before deploying | migration (manual) | P1b | OPEN (the owner runs the production dry run before deploy) |
| T24 | D17 migration: `courses.last_group_sequence` is backfilled to `MAX(course_group_sequence)` per course; idempotent; courses with only imported groups start at 0. Rev 8: the column is the Tmp counter and starts at 0 everywhere, since existing groups are all confirmed and keep their G numbers | migration (manual) | P4 | TODO |
| T25 | B14 / R4 / R5: two concurrent project creates for one group produce one project and one friendly error (and the unique index raises if the lock is removed); reopen racing project creation never leaves a project on a not-confirmed group | unit (threads, non-transactional) | P1b | DONE |
| T26 | R12 / R9: a join racing a group delete returns `:group_gone` (with R9, in P3a); the new formation group-write services (approval toggle, delete) take the group lock. The leader-promotion race test is dropped with the endpoint (D26); the approval-toggle part goes with the services in P2b (D28) | unit (threads, non-transactional) | P2 | DONE |
| T27 | R3: two groups confirming at once under prevent-leftover mode are never both confirmed when only one fits; the Reopener, Importer, enrolment removal and grouping settings saved under the course lock in `handle_settings` take the course lock | unit (threads, non-transactional) | P3a | TODO |
| T28 | E1 / E2 / D23: `dissolve_confirmed` in the request no longer changes behaviour; `Leaver` refuses with a project; `Coordinator::GroupDeleter` on a group with a project returns needs-confirmation and deletes only after the second policy-checked request | integration | P2 | DONE |
| T29 | E4 / D24: removing a member by any path (service and `dependent: :destroy`) deletes that user's pending `direct_invite` records for that group, and leaves other groups' invites alone | model | P3a | TODO |
| T30 | E3 / D25: every group controller returns 404 on a non-grouped course; Creator and Importer return blocked | integration | P4 | TODO |
| T31 | D10: flip `group_formation_page_test.rb` lines 80-81: a lecturer sees no Manage controls | integration | P4 | TODO |
| T32 | D7: `ProjectGroupMemberPolicy#destroy?` is false for self-leave and leader kick on a confirmed group, true for a coordinator; the formation page shows no Leave button on a confirmed group | policy + rack_test system | P2 | DONE |
| T33 | R13 / B15: a coordinator removal racing a join completes without a deadlock because the course lock is `FOR NO KEY UPDATE`; the group-write lock test covers `Leaver` and `Kicker`; a lecturer-then-coordinator user can delete a confirmed group and passes the policy | unit (threads, non-transactional) + policy + integration | P2 follow-up | DONE |
| T34 | D27: a new group is named Tmp### from the per-course counter and the number is never reused after a delete; Confirm gives the lowest free G###; Reopen releases it and gives a new Tmp###; imported groups keep their CSV name and take no number; links and tokens resolve by group id, not name | model + unit (threads, non-transactional) | P4, P4b | TODO |
| T35 | D28 / D29: a not confirmed group takes direct joins; a confirmed group takes requests, invites and links, and accepting any of them reopens it and notifies every member; a group with a project takes no new members and its pending requests and invites are cleared; imported groups are closed to students | unit + integration | P4c | TODO |
| T36 | Origin: an imported group has no student action (service and policy refuse, UI hides the buttons); coordinators can still add, remove and delete it; nobody can reopen it. The reopen refusal is done in P1b; the other guards come with P4c | unit + policy + integration | P1b, P4c | WIP (reopen part DONE) |
| T37 | D28: no join request can be created (`request_to_join?` is false for everyone; the requester refuses a not confirmed group with `:group_not_confirmed`); the migration deletes only pending requests and is a no-op the second time (manual dry run); the Manage page has no approval switch and the table never says "Request to join"; `PATCH` on the group path is gone | unit + policy + integration + migration (manual) | P2b | TODO |
| T38 | D31: a student's pending requests are deleted when they land in any group (coordinator add included), when they leave the course, and when a project is created on the group; a group's are deleted on reopen; accept re-checks enrolment and ungrouped state; expiry once decided | unit + model | P3a, P4b, P4c | TODO |

## 6. Phases (in order)

| Phase | Scope | Depends on | Done when | Status |
|---|---|---|---|---|
| P0 | Settle D1-D5 | - | Decisions recorded in section 1 | DONE |
| P0b | Advisor questions: D6, D11 and D12 are recorded in rev 3. D7 decided in rev 5 | - | D7 recorded | DONE |
| P1b | C1, C2, C3, O9, **B3 (R1)**, **B14 (R4, R5)**, T6, T13, T14, T22, T23, **T25**. Builds `Groups::Coordinator::Importer`, adds `course_id` to `project_group_members` with unique index `(course_id, user_id)`, the D9 reopen block, and the project group lock plus unique index (D22). All member inserts go through `ProjectGroupMember.add`. The backfill migration is a separate PR so it can be reviewed and deployed on its own. Runs first: possible regression for grouped-CSV courses | Rebase onto main first (production runs Rails 8.1.4, the branch lockfile has 8.0.2) | Grouped-CSV course can create a project; imported groups are confirmed with the first member as leader and no sequence; a grouped student is not moved by import; reopen blocked with a project; a group cannot get two projects; member uniqueness enforced by DB; failing tests written first | DONE (rev 9) |
| P1 | B1, B2, I8, T1-T3. Re-audited against HEAD; T1-T3 pass | - | Tests pass | DONE |
| P2 | Remover split (`Leaver`, `Kicker`, `Coordinator::MemberRemover`), B9, T4 (B4 and T5 dropped under D7). **Rev 4:** the R12 services (approval toggle, delete; leader promotion dropped in rev 6, D26) with T26, and the server-side confirmation (E1, D23) with T28. **Rev 5:** the `ProjectGroupMemberPolicy#destroy?` change with T32, and the I8 residual. Also E2, and `ProjectGroupPolicy#destroy?` lets coordinators delete a group in any state. The new services that change N (`Coordinator::MemberRemover`, `Coordinator::GroupDeleter`) take the course lock first (D21). **Rev 6:** the promote-leader endpoint and promoter services built here are deleted in a follow-up commit (D26). **Rev 7:** R13 (course `FOR NO KEY UPDATE`), B15 (unambiguous coordinator checks), and the threaded/course-lock test hardening (T33) | D7 (decided) | Removal services fully covered; no controller writes a group directly; nobody can self-leave a confirmed group; no course/group lock deadlock | DONE |
| P2b | D28 cleanup, two PRs (brief `D28_APPROVAL_TOGGLE_REMOVAL.md`). **Part 1:** delete both `ApprovalToggler` services, `GroupsController#update` and its route, the Manage switch, the table's request button and the lock gates in Joiner and the requester; close join requests (`request_to_join?` false, the requester refuses a not confirmed group with `:group_not_confirmed`); a data migration deletes every pending join request (D31); T37. **Part 2:** drop `project_groups.locked` | P1b | Nothing reads or writes `locked`; no join request can be created; pending requests deleted; the column is dropped in its own PR | TODO (brief written) |
| P3a | B6, B8, O2, T7-T8, T16, T20. **Rev 4:** R3 (course lock in the confirmers, T27), R9 (`:group_gone`), R10, E4 (T29), E6, and the non-transactional race test class. **Rev 5:** B13 (proposed, own commit). B3 moved to P1b. **Rev 9 (D31):** the shared cleanup also clears a student's pending requests when they land in any group (coordinator add included) and when they leave the course, project creation clears the group's pending requests and invites, and Responder re-checks enrolment and ungrouped state at accept time (T38) | P2b | One shared invite-cleanup method; coordinator removal and enrolment removal are one path, with the warning and a transaction; race tests really run concurrently | TODO |
| P4 | B7, B10, B11, B12, I6, I7, I11-I13, O3, O5, O6, D13 (delete `destroy_draft_groups`), T9, T17, T21. **Rev 4:** name index (I14, T24). **Rev 8:** the Tmp counter replaces the D17 counter (D27), E3 (T30), E8, R11 (grouping settings saved under the course lock in `handle_settings`), T31 | D3 | Small backend fixes in; dead code gone; `manage_groups?` and the column gone (D10); numbers never reused | TODO |
| P4b | D6 `Coordinator::Confirmer` and `Coordinator::Reopener`, O4 policies (with the D9 condition), O11 banner, O14 Overview, T15, T18, T19. **Rev 8:** numbering: Confirm gives the lowest free G### and Reopen releases it and gives a new Tmp### (D27, T34). **Rev 9:** reopen deletes the group's pending requests (D31) | D6, D13, P4 | Coordinator confirm and reopen in place; banner and gates behave as in 1d and O11 | TODO |
| P4c | D29 and requests reopen: `JoinRequester` and its policy allow confirmed groups (the P2b policy line flips); accepting a request, invite or link into a confirmed group reopens it under the course lock, notifies every member and runs the shared cleanup; a project freezes membership; the `origin` guards in every student write service (imported groups closed to students); request expiry once decided; T35, T36, T38 | P3a, P4, P4b, request expiry decided (1h) | Confirmed groups take members as in D29; imported groups stay closed; no stale request can add a student | TODO |
| P5 | B5, T10 | D2 | Calculator matches the chosen model; spec doc updated if D2 chose (b) | BLOCKED (D2) |
| P6 | I1-I3 | P1-P5 | One shared result class; messages in one locale file; behaviour unchanged | TODO |
| P7 | Section 4 rename map (the `locked` rename is gone, D28), I4 (the `direct_` prefix), I5, I9, O7 | D1, D4, P6 | No old terms in app/, db/schema.rb, test/, docs/; suite green | TODO |
| P8 | T11, T12 | P1 | Core flows covered at the system level | TODO |

## 7. Verified correct against the spec

- Leader can remove members only while not confirmed. (The spec also says self-leave from a confirmed group reopens it for everyone, and the code does that today. D7 replaces it: nobody can self-leave a confirmed group. The spec line must change.)
- Leader leaving promotes the earliest remaining member; last member leaving deletes the group and surfaces the proposal title first.
- Invite link expires after 24 hours. There is no approval step any more (D28): a not confirmed group takes direct joins, and a confirmed group takes requests, invites and links (D29, built in P4c).
- Group names: not confirmed groups are `Tmp###` from a per-course counter that never reuses a number; Confirm gives the lowest free `G%03d` and Reopen releases it (D27). Imported groups keep their CSV names. `group_name` has no uniqueness today (I11); the unique index and validation come in P4. Today the number is `course_group_sequence`, enforced unique per course by the DB.
- Duplicate pending invites and requests are blocked by partial unique indexes (R7).
- Disabling grouping or leaving prevent-leftover mode no longer deletes not-confirmed groups (D13). The spec line changes.

## 8. Not audited

JS controllers, mailer views, courses/settings grouping UI, the Groups tab view templates (`groups#index`), the full `ProjectPolicy` and `CoursePolicy` beyond `manage_groups?`, and whether the current suite passes. Rev 4 read the group, member, invite and invite-link policies and all group controllers. Supervisor capacity and topic races are out of scope (the owner will flag them separately).

Not checked:

- The canary for the existing thread tests (2d): whether they still pass with `with_lock` removed.
- E7: whether user deletion exists as a real path.
- E8: raw reads of `grouping_open` outside `grouping_window_open?`.
- Whether solid_queue enqueues inside the surrounding transaction (E6).
- Whether controllers rescue `RecordNotFound` from a `with_lock` on a deleted group (R9).
- The Canvas DB indexes and Discourse `GroupManager` (2d reference apps).
- Rev 9, before deploying P1b: the read-only fingerprint check (groups with no sequence that are not fingerprint groups should be 0; it was 353 fingerprint groups on 2026-11-02) and T23, the backfill dry run on a restored copy. Course 3's 4 groups are fingerprint groups, so they become `import`.
- Rev 9, before deploying P2b: locked groups (and locked groups that are not confirmed) and pending join requests on confirmed versus not confirmed groups; the migration deletes all pending requests silently.
- Rev 9: whether the suite passes, and whether any group route looks a group up by name (unverified). P1b also touched `db/seeds.rb` and three views the brief did not list; they were not reviewed.
- Production runs Rails 8.1.4 and the branch `Gemfile.lock` has 8.0.2. Rebase onto main and run the migrations there before deploying (deferred by the owner in rev 9: do it before merging to main, not before P2b).

Answered in rev 5 (production, read-only, 2026-11-02, plus course 3 on 2026-11-03):

- **Duplicate projects per group:** none. The D22 partial unique index will apply.
- **Q4, duplicate `group_name` per course:** none. The I11 index is safe.
- **Students in two groups of one course:** none. The B3 index is safe.
- **Import-fingerprint groups** (not confirmed, no leader, no sequence): 353 in 14 courses.
  - 349 are in 13 grouping-off courses (courses 1, 133, 170, 232, 233, 234, 235, 298, 364, 399, 430, 463, 496; course 298 has 110). The backfill confirms these.
  - 4 are in course 3, where grouping is on. They already have a project, so the project rule confirms them too (O15).
- **Leaderless groups with members:** 350 in 13 courses. Every one of them is a fingerprint group, so the fingerprint rule (C1) is reliable and no app-created group is leaderless.
- **Course 234:** its 3 fingerprint groups have no members. The backfill confirms them, which is harmless. They are leftovers from the old importer.
- **Course 3:** grouping on, `grouping_open` false, no open or close dates. Its 4 groups have 1, 2, 3 and 3 members, and all 4 have a project (O15). The course is "Sandbox Group Approved Topic", the team's live testing course (confirmed by the owner).
- **Expected migration output on this data:** "Confirmed 349 imported groups and 4 groups that already have a project; assigned a leader to 350 groups", if course 3 holds the only not-confirmed groups with a project. Re-run the counts before deploying, because a new import changes them.

Answered in rev 4 (were "not checked" in rev 3):

- Whether any test relies on a lecturer acting as staff by default (D10, O5): yes, `group_formation_page_test.rb` lines 80-81 (T31).
- Whether the new-project page stops a student in an unconfirmed group (O14): no.
- What the formation page shows today after close (1d): a read-only empty state with the wrong copy.
- Q8: whether group names can be edited (I11): no, rename does not exist.

## 9. Code conventions and quality

Applies to every PR from rev 5. Rubocop (`.rubocop.yml`) and `docs/Abstraction/service_classes.md` still apply. This adds what they do not cover.

### Comments

1. Say why, not what. If a better name or a smaller method removes the need for a comment, do that instead.
2. No comment that restates the next line or the method name. Simple methods get none.
3. At most 1 to 3 lines per comment. Longer reasoning goes in the PR description or an ADR in `docs/adr`.
4. No plan IDs (D17, B14, R3, T25), revision numbers, counts or "added for..." history in code or tests. They go stale. The PR description and commit message link the plan.
5. A comment is required for: why a check sits inside a lock, the DB constraint a rescue relies on, an intentional deviation from convention, and a non-obvious parameter or return contract.
6. A class header is one to three lines: what it is, plus any non-obvious contract.

GitLab examples (`gitlabhq/gitlabhq`, MIT). Copy the pattern, not every instance: some of their comments do restate the code.

A class header states what the thing is in one breath (`app/models/internal_id.rb`):

```ruby
# An InternalId is a strictly monotone sequence of integers
# generated for a given scope and usage.
```

An inline comment explains a line that looks pointless without it (`app/services/groups/destroy_service.rb`):

```ruby
# reload the relation to prevent triggering destroy hooks on the projects again
group.projects.reset
```

The same file's simple delegators (`track_greatest`, `generate_next`, `reset`) have no comment at all.

ProPro example, the first draft of the `Groups::Coordinator::Importer` header versus the trimmed one:

```ruby
# Before: 5 lines, plan IDs, restates the code
# Places students from a grouped CSV into groups. Coordinator-initiated: it ignores
# the grouping window. New groups are created confirmed, with the first member in
# CSV order as leader and no sequence number (C1). A student who is already in a
# different group is left there and reported, never moved (C2). A group is only
# saved when someone is placed in it, so an import never leaves an empty group.

# After: 3 lines, no IDs; the empty-group rule moved next to the line that does it
# Places students from a grouped CSV into groups. New groups are created confirmed,
# led by the first member in CSV order. Students already in another group are
# reported, not moved.
```

### Code

- Controllers never write a group or its members directly. They call a lock-taking service (D20).
- Lock order is course, then group, then enrolment. Checks without a DB constraint behind them happen inside the lock. No external calls inside a lock. Mail is enqueued after commit.
- No broad `rescue StandardError` that shows `e.message` to the user (B11). Rescue the specific error.
- Use the D1 vocabulary in code, copy and tests. New user-facing text never says draft, revert, locked or dissolved.
- No new abstractions beyond what an item asks for. One concern per PR. A rename never shares a PR with a behaviour change.

### Tests

- Name tests by behaviour. Every fix has a regression test that fails before the fix.
- Race tests are non-transactional, and the PR description records the canary result (T7).

### Migrations

- One person writes migrations at a time, so `schema.rb` does not conflict.
- Data migrations use raw SQL, not models, and are idempotent.
- If existing data would make an index fail, abort with a message naming the offending rows.

### Review checklist

- Does the diff match one plan item, with no extra scope?
- Does the regression test fail without the fix?
- Are locks taken in order, with checks inside them?
- Any comment that restates the code, or any plan ID in code?
- Any D1 term violation in code, copy or tests?
- Any controller writing a group directly, or a broad rescue?