# ProPro Grouping: Master Implementation Plan

Branch `feat/student-grouping-crud`. Revision 17: P4e (P4c backend follow-up) landed: D33 (`ProjectGroup#clear_invite_links!` called from both Confirmers, `#reopen!` and project creation), D34 (`Kicker` reopens a confirmed group under course-then-group locks, mails every remaining member with the removed-user variant, `ProjectGroupMemberPolicy#destroy?` exception), U4 (`Groups::InviteLinkDisabler`, `DELETE invite_link`, leader policy), U5 (requester runs under the group lock, replaces the sender's expired pending request, mails after the lock), U1 (`:group_full` in the requester; responder/redeemer already had it), and the named policy changes (`request_to_join?`, `edit?`/`update?`, `revert?`); T39/T40/T42 DONE, T41 and T43 service/policy halves DONE (buttons in P4f). Full suites green: `bin/rails test` 615 runs / 2009 assertions, `bin/rails test:system` 115 runs / 576 assertions, rubocop clean on touched files except pre-existing offences. Revision 16: P4d (D36 rename) landed in its own PR: the course columns are `group_formation_enabled`/`group_formation_closes_at`, the derived predicate is `Course#group_formation_open?`, the blocked reason is `:formation_closed` with copy "Group formation is closed.", and formation open/closed wording replaced the old term throughout code, comments, docs and this plan; migration `20261112090000` renames the columns; T45 DONE. Revision 15: owner click-through of the P4c backend (2026-11-12) recorded: D33 (invite links deleted on confirm, reopen and project creation), D34 (leaders can kick from confirmed groups, which reopens them; amends D7), D35 (request surfaces; the bell stays on the formation page), D36 (formation open/closed; renamed in P4d); UI findings U1 to U6 added (section 2e); the rest of P4c is split into P4d, P4e and P4f; E9 moved to P4f. Revision 14: P4c backend landed (request expiry 24 hours derived from `created_at`; join requests into confirmed groups; accepting a request, invite or link into a confirmed group reopens it under the course lock and notifies every member via the new `GeneralMailer::Group_Reopened_Notification`; `origin` guards in every student write service; `ProjectGroup#reopen!` shared by both reopen paths and now clears pending requests in the student path too; T35/T36/T38 covered; full suites and rubocop green on the P4c tree). The P4c UI half still waits for the P4c UX surfaces. Revision 13: P4 close-out landed (B11, F5, E6 regression test, E7 checked console-only, T27/T7 canaries recorded, full suites and rubocop green on the close-out tree; statuses updated in the same PR). Revision 12: statuses reconciled at `d4d1d4b` (P4b and the settings UI pass are committed; B10, B12, I6, O3, O6 found done in code); D2 and Q5 closed (the current confirmability algorithm stays, B5 dropped); F5 decided (D32); D29 reopen-notification copy decided. Revision 11: records the Grouping settings UI pass (ADR 0027 — derived formation open/closed, switch-based Grouping section, no mode cards). Revision 10: records the UI gap analysis answers (`docs/Grouping/UI_GAP_ANALYSIS.md`), D30 adopted (ADR 0026), D27 amended to lowest-free naming, D31 expiry set to 24 hours; statuses reconciled at `4bb76b57`. Requirements/wording source of truth: the "ProPro: Grouping" spec doc. Service conventions: `docs/Abstraction/service_classes.md`. Test conventions: `docs/testing.md`. Code conventions: section 9.

**Statuses reconciled at `d4d1d4b`** (earlier pass `4bb76b57`). Commits `cc99ea0` + `7b4fb2b` (D28, both parts, migrations included), `ffe8c9a` + `78953f3b` (P3a locks/services), `1a81641` (D10: column dropped, `manage_groups?` kept as the coordinator-only check), `13f5a33` (D27 amended: lowest-free naming, sequence column dropped, unique `(course_id, group_name)` index; D13 also landed) already shipped the work below. The P4b UI pass (coordinator Confirmer/Reopener, O11, O14, D30 UI) landed in `1ae5cef`, with the PostHog commit `a7a1b0b`, the settings UI pass `e53fa0f` (ADR 0027), the test updates `c2d5ed5` and the B16 fix `d4d1d4b`. The 2026-11-11 reconciliation to `d4d1d4b` was done by reading the code; no tests were run for it (last recorded runs are in the snapshot).

## 0. Snapshot

- DONE: P0, P0b, P1, P1b (origin column, Importer, backfill, reopen guard), P2 (+B15, R13), P2b, P3a, P4b, and the P4 items below. P4b is committed: `Groups::Coordinator::Confirmer`/`Reopener`, O4 policies, O11, O14, the D30 Overview/Groups-tab UI, audit fixes F1–F4 and F6, and the Grouping settings UI pass (ADR 0027: derived formation open/closed, switch-based section, no mode cards, closes E8). B16 (PostHog `NameError` in `ProjectsController#create`) is fixed.
- P4 landed: B7, B10, B12, I6, I7, I11–I14, O3, O5, O6, E3, E8, R6, D13, D27 naming. R11 is accepted.
- P4 close-out DONE (2026-11-11, PR grounded at `d4d1d4b`): B11 (`handle_settings` no longer has a broad `rescue StandardError`; `update!` + `rescue ActiveRecord::RecordInvalid` → `render_invalid_settings`, capacity-updater failure renders its errors after rollback); F5 (D32: the grouping switch dropped from the proposal gate in `ProjectsController#new` and `#create`); E6 (regression test added — the `discard_on` initializer itself had already landed in `ffe8c9a`); E7 (console-only, WONTFIX — see row E7). T27 and T7 canaries recorded. Full suites green on the close-out tree: `bin/rails test` 549 runs / 1806 assertions, `bin/rails test:system` 115 runs / 576 assertions (twice, single worker), rubocop clean on every touched file (pre-existing offences elsewhere untouched).
- P4c backend DONE (2026-11-11, same PR as the P4 close-out): request expiry 24 hours derived from `created_at` (`ProjectGroupInvite#expired?`, `unexpired` scope, accept refuses, incoming lists hide stale requests); `ProjectGroupPolicy#request_to_join?` flipped for students on confirmed formation groups; accepting a request, invite or link into a confirmed group reopens it under the course lock, runs the shared cleanup and notifies every member via `GeneralMailer::Group_Reopened_Notification` ("Group reopened because X joined."); confirmed groups take direct invites and links again (D28), direct joins stay not-confirmed only; `origin` guards in every student write service and in `direct_invite?`/`generate_invite_link?`; a group with a proposal refuses requests, invites and links; `ProjectGroup#reopen!` is shared by `GroupReverter` and `Groups::Coordinator::Reopener`. Full suites green: `bin/rails test` 576 runs / 1900 assertions, `bin/rails test:system` 115 runs / 576 assertions, rubocop clean on touched files (pre-existing offences untouched).
- P4e backend DONE (2026-11-12): D33 links deleted on both confirms, every reopen path (`#reopen!`) and project creation, with a confirm-vs-redeem canary; D34 leader kick from a confirmed group reopens it under course-then-group locks, clears links/requests and mails remaining members ("Group reopened because X was removed."); U4 `Groups::InviteLinkDisabler` + `DELETE invite_link`; U5 requester under the group lock with expired-request replacement and post-lock mail; U1 `:group_full` on requests (responder/redeemer already had it); U2/U3/U1 policy exceptions. Full suites green: `bin/rails test` 615 runs / 2009 assertions, `bin/rails test:system` 115 runs / 576 assertions, rubocop clean on touched files (pre-existing offences untouched).
- TODO (in order): P4f (P4c UI half: U1 to U4 UI, U6, E9), then P5 (spec edit and T10, no calculator change), then P6, P7, P8.
- Decisions: nothing blocks. D2/Q5 closed (the current algorithm stays), F5 decided (D32), D29 notification copy decided. D33 to D36 decided (revision 15); the P4c UX surfaces are settled (D35). One assumption for the owner to confirm: coordinators see no bell (U6, section 1h). "Tmp" label stays.
- Last recorded test runs (2026-11-10, before the 2026-11-11 reconciliation by reading): targeted P4b and settings-pass suites green (overview presenter, overview-tab, grouping-display, formation, groups-tab manage, groups/projects/courses controllers, coordinator Confirmer/Reopener, course model, Grouping switches/end-date browser tests). Broad grouping run after B16: 334 runs, 0 failures, 0 errors. The full suite and the app are otherwise unrun. Read-only production checks and T23 are the owner's, before deploy.

## How agents use this doc

- Status values: TODO, WIP, DONE, BLOCKED, DECISION, DECIDED, PROVISIONAL, PROPOSED, OPEN, DROPPED, ACCEPTED, UNVERIFIED. Update the Status column in the same PR that does the work.
- Never `git add` or `git commit`; the user stages and commits.
- One PR per phase. Never mix a rename with a behaviour change.
- Minimal targeted edits. No new abstractions beyond what an item asks for.
- Every bug fix lands with a regression test that fails before the fix.
- Don't change Pundit policies unless an item says so. Named exceptions: D7 `ProjectGroupMemberPolicy#destroy?` (P2); `ProjectGroupPolicy#destroy?` lets coordinators delete a group in any state (P2); D26 deletes `promote_leader?`; P2b sets `ProjectGroupPolicy#request_to_join?` false and P4c flips it. P4e (revision 15) names four more: `ProjectGroupMemberPolicy#destroy?` (leader kick on a confirmed group, D34), `ProjectGroupPolicy#edit?`/`#update?` (leader of a confirmed, non-imported group without a project, U2), and `#revert?` and `#request_to_join?` (formation open for non-coordinators, U3, U1). Audited policies: group, member, invite, invite-link, `CoursePolicy#manage_groups?` only.
- Unverified items are suspected from reading, not reproduced. Write the failing test first; if it passes, mark DONE (not a bug).
- Concurrency (D20): lock order course, group, enrolment; checks without a DB constraint happen inside the lock; every write to a group or its members goes through a lock-taking service, never `@group.update!` in a controller.
- Follow section 9 in every PR.

## 1. Decision register

D1 to D36 are decided (D33 to D36 are revision 15 and D7 is amended by D34; D30 via ADR 0026; D27 amended to lowest-free naming; D31 expiry is 24 hours; D32 is the F5 proposal gate). D2 was confirmed by the other reviewer (the current algorithm stays). D17 is superseded by D27 and D14, D16 do not exist.

| ID | Decision | Status |
|---|---|---|
| D1 | Vocabulary: the user-flow set everywhere (Prevent leftover students / Not confirmed / Reopen; internal enum/column names follow it). Retire "Auto-Confirmability", "Default mode" and "draft" from code comments, docs and spec 1.x/3.0; remove stale spec text outside the overview tab. Add "Tmp group" and "group number" to the glossary | DECIDED |
| D2 | Confirmability model in prevent-leftover mode: the code's feasibility check (any size in min..max whose remainder is still splittable), not the strict quota the spec described. The other reviewer reported the current algorithm is fine (2026-11-11), including the cap for a confirmed group in prevent-leftover mode (the old Q5): current behaviour stands. `confirmable_size?` is not changed (pure renames only) and the spec is updated to describe the feasibility check (section 7). Handover facts: staff-confirmed groups outside limits change head-count N; not-confirmed groups survive leaving prevent-leftover mode (D13); student joins into confirmed groups change N (D29); the race on N is fixed by the course lock (D21), not by changing the model | DECIDED |
| D3 | "No limit" is the default: nil min = 1, nil max = unlimited. Remove the "required when grouping enabled" validations on Course and update `course_grouping_settings_test`. Prevent leftover students requires both min and max. One shared helper for effective min/max used by every service. B7 is this work | DECIDED |
| D4 | Revert becomes Reopen: `GroupReverter` to `Groups::Reopener#reopen!` (coordinator: `Groups::Coordinator::Reopener`), `revert?` to `reopen?`, `:already_draft` to `:already_not_confirmed`, copy "Group reopened.", route stays `confirmation#destroy` | DECIDED |
| D5 | `Groups::` namespace (map in section 1b). Tests move to `test/services/groups/`. `Queries::` stays | DECIDED |
| D6 | Coordinators confirm and reopen (below) | DECIDED |
| D7 | Self-leave only while not confirmed and formation open; in a confirmed group nobody self-leaves, leader included; a leader can kick from a confirmed group (D34) (below) | DECIDED (amended) |
| D8 | Name services by user action, Moodle-style (map in 1b) | DECIDED |
| D9 | A group with a proposal can never be reopened, coordinators included (below) | DECIDED |
| D10 | Drop `lecturers_can_manage_groups`; `manage_groups?` becomes the coordinator-only check (below) | DECIDED |
| D11 | Coordinator removal and enrolment removal are one path (below) | DECIDED |
| D12 | Formation (student) vs coordinator service layers (below) | DECIDED |
| D13 | Mode switches no longer delete not-confirmed groups (below) | DECIDED |
| D15 | Illegal sizes show as warnings ("below minimum"); coordinators can override size limits (D6) | DECIDED |
| D18 | Drop "Move a member" from the spec; coordinators remove and re-add. No `Coordinator::Mover` | DECIDED |
| D19 | Prevent leftover students can be turned back on after being switched off; remove the "can only be turned on once" spec rule | DECIDED |
| D20 | Lock convention: order course, group, enrolment; never take an earlier lock while holding a later one. Checks without a DB constraint happen inside the lock. Every write to a group row or its members goes through a lock-taking service. No external calls inside a lock; mail enqueued after commit (E6). Course lock is `FOR NO KEY UPDATE`, never plain `FOR UPDATE` (plain conflicts with the FK key-share lock a member insert needs and deadlocks against a join holding the group lock, R13) | DECIDED |
| D21 | Course lock for everything that changes N (students minus members of confirmed groups): Confirmer and Coordinator::Confirmer, Reopener and Coordinator::Reopener, add/remove a member of a confirmed group, group delete, enrolment add/remove, the Importer, and grouping settings saved in `handle_settings` (min, max, prevent-leftover flag). Always taken, not conditional on mode (mode can flip mid-request). Joins into not-confirmed groups stay on the group lock only; accepting a request, invite or link into a confirmed group reopens it and takes the course lock (D29). Calculator and `confirmable_size?` untouched (D2) | DECIDED |
| D22 | One project per group in the DB: partial unique index `projects(owner_id) WHERE owner_type = 'ProjectGroup'` (lecturers own several topics, so no general index). Project creation takes the group lock, which also serialises it against Reopener (R4, R5, B14) | DECIDED |
| D23 | Destructive confirmations are server-side: the remover never reads `dissolve_confirmed` from params (E1). `Groups::Leaver` refuses whenever the group has a project. `Coordinator::MemberRemover` and `Coordinator::GroupDeleter` return needs-confirmation and act only on a second, policy-checked request. Coordinator delete of a group with a project warns first, then deletes (E2) | DECIDED |
| D24 | `ProjectGroupMember` `after_destroy` deletes that user's pending `direct_invite` records for that group (also fires on `dependent: :destroy`). No withdraw feature for invites/requests (E4, E5) | DECIDED |
| D25 | `ensure_grouped` on every group controller action. `Groups::Creator` and `Groups::Coordinator::Importer` check `grouped?` (the only places groups are created); other services act on an existing group (E3) | DECIDED |
| D26 | No promote-leader. The leader changes only by succession (earliest remaining member by `created_at, id`) when the leader leaves, is kicked or is removed. Staff choose the leader at group creation; an imported group's leader is its first CSV member (C1). Deleted: `GroupLeadersController`, the `resource :leader` route, `ProjectGroupPolicy#promote_leader?`, both promoter services, their tests, the routing-test row, and the two integration tests using `course_group_leader_path` (follow-up commit to P2, done). T26's promotion race test dropped. ADRs 0022/0025 still list `promote_leader` as history | DECIDED |
| D27 | Naming (amended; supersedes the counter): not-confirmed groups are `Tmp###`, confirmed groups `G###`, both **lowest free in the course**, assigned under the course lock in one transaction with the status change. Confirm gives the lowest free `G###`; Reopen releases it and gives a new `Tmp###`. Imported groups keep CSV names and take no number. Names are display only: every URL, invite, request and link token uses the group id. Unique `(course_id, group_name)` index (I11); if a generated name is taken (imported CSV `G003`), Creator takes the next number. No naming migration (existing groups are all confirmed and keep G numbers). "Tmp" label stays for now | DECIDED (amended) |
| D28 | Joining: not-confirmed groups take direct joins; confirmed groups take requests, invites and links. No approval toggle; `locked` column dropped as its own PR (below) | DECIDED |
| D29 | Accepting a request, invite or link into a confirmed group reopens it and notifies every member. A project freezes membership and clears pending requests and invites. Imported groups are never reopened by students (below) | DECIDED |
| Origin | `origin` column on groups, values `formation` / `import`, default `formation` (below) | DECIDED |
| D30 | Groups tab lists unconfirmed groups only while formation is not open (ADR 0026) | DECIDED |
| D31 | Lifecycle of pending join requests (below); expiry is 24 hours | DECIDED |
| D32 | Proposal gate (F5): a student needs a confirmed group to start a proposal whether or not grouping is currently enabled. `ProjectsController#new` and `#create` drop the grouping switch condition so the gate matches `Project#project_group_must_be_confirmed`. Leftover not-confirmed groups in a grouping-off course (D13) are confirmed by a coordinator through the O11 banner | DECIDED |
| D33 | Invite links: confirm (student or coordinator), reopen (student, coordinator, and the reopen an accepted request, invite or link triggers) and project creation delete every link of the group. A disable-link button exists (U4). Links on a not-confirmed group stay multi-use until they expire, are disabled or are replaced | DECIDED |
| D34 | Leaders can kick members from a confirmed group (amends D7): formation open, no project, not imported. The kick reopens the group, for the same reason D29 does. Students still cannot self-leave a confirmed group | DECIDED |
| D35 | Request surfaces: the "Request to join" button on the formation table, the leader's Join requests section in the Manage dialog, and the existing bell on the formation page. The bell stays on the formation page (`content_for :header_actions`) until group formation ships and is not moved into `application.html.erb`; app-wide notifications for other features come after | DECIDED |
| D36 | Formation closed is one concept. The stored course columns and the derived predicate use formation terms, and the predicate is the only definition of open. Own pure-rename PR (P4d) | DECIDED |

### D6: coordinators and status

Editing min/max does not clean up bad groups: confirmed groups are not rechecked and a leader must still press Confirm. The gap is a not-confirmed group after formation closes: students cannot act, staff cannot confirm, and a confirmed group is required to start a proposal. This overrides the advisor's "coordinators cannot change status"; spec text saying so is stale.

- `Coordinator::Confirmer` confirms undersized and oversized groups and works with formation closed. `Coordinator::Reopener` works with formation closed and is blocked with a proposal (D9).
- Lecturers and students cannot call them. A student leader still cannot confirm an illegal size.
- Coordinator add, remove and delete never change status (T2, T4, T16).
- Leftover not-confirmed groups (formation closed, or grouping turned off, D13) are flagged by the O11 banner.
- Both services take the course lock first (D21) and include numbering (D27), so P4b depends on P4.

### D7: self-leave and staff removal on a confirmed group

- Self-leave works only while not confirmed and formation open. Otherwise "confirmed" means nothing.
- Only the leader can Reopen, and not at all with a proposal (D9) or for an imported group. A leader who wants out of a confirmed group must reopen first. A group with a proposal can only be changed by a coordinator.
- A leader can kick while formation is open, from a not-confirmed group or a confirmed one (D34); a kick from a confirmed group reopens it. Not with a proposal (D9) or for an imported group.
- `Leaver` has no reopen branch and returns `:group_confirmed`; `legal_at_current_size?` is deleted from the remover (B4, T5 dropped). The Leave control is hidden on a confirmed group (formation view renders it only when `policy(membership).destroy?`).
- Policy exception: `ProjectGroupMemberPolicy#destroy?` is false for self-leave on a confirmed group and true for coordinators (T32). Amended by D34: a leader kick on a confirmed group is true while formation is open, with no project and not imported.
- Spec lines "Remove a member" and "self-leave from a confirmed group reopens it" must change. Unchanged by D28/D29.

### D9: groups with a proposal are never reopened

Reopening a group that owns a project blurs formation vs management and leaves the proposal owned by a not-confirmed group (O9).

- Reopener returns blocked `:has_project`; `reopen?` is false. The UI hides the Reopen button with no explanation line.
- `Project#project_group_must_be_confirmed` runs `on: :create` only, so a status change never blocks editing an existing project.
- Project creation takes the group lock (D22), so a project cannot be created on a group being reopened (R5).
- A group with a project cannot take new members (D29). Membership changes there are a management concern (D11, D12).

### D10: drop `lecturers_can_manage_groups`, delete `manage_groups?`

- `manage_groups?` is grouping-only with 11 call sites: staff `groups#create`, staff `group_members#create`, the manage UI in the formation page, table and `groups/edit`, four in `ProjectGroupPolicy` (`create?`, `confirm?`, `revert?`, `edit?`), and `ProjectGroupMemberPolicy#destroy?`. The lecturer flag is read only in `CoursePolicy#manage_groups?`; no test references the column.
- Replace the 11 sites with the coordinator check and drop the column. Update OPEN_ITEMS.md [F]. A "lecturers manage groups" setting is rebuilt only when requested (spec lists it as a future setting).
- A test relies on lecturer-as-staff: `test/integration/group_formation_page_test.rb` lines 80-81 (and a re-sign-in near 127). Flip it (T31).
- Already landed in P2: `ProjectGroupMemberPolicy#destroy?` denies lecturers. Remaining work is P4.
- Lecturers get the same read-only closed message as students (1d).
- `ProjectGroupPolicy#update?` stays until this removal (only `edit?` uses it).
- Landed in `1a81641`: column dropped (migration `20261108090000`), OPEN_ITEMS updated, tests flipped. Amendment: `CoursePolicy#manage_groups?` stays as the coordinator-only gate instead of being deleted — every call site now means "coordinator".

### D11: one removal path

Today `EnrolmentsController#destroy` passes `dissolve_confirmed: true`, so removing the last student silently deletes the group and its proposal, and the removal and `enrolment.destroy!` are not in one transaction.

- Coordinator removal and enrolment removal share `Coordinator::MemberRemover`. Drop `dissolve_confirmed`; wrap in a transaction; the warning is a server-side step (D23).
- Non-last member: remove, promote a leader if needed, show a size warning. Last member, no project: delete the group. Last member with a project: nothing silent; server-side confirm, then delete group and proposal.
- A removed leader is replaced by the earliest member; the student's pending invites and requests are cleared (T20, D31). Enrolment removal takes the course lock, then the group lock (D20, D21).
- Legacy not-confirmed groups with a project: 4 in course 3 (O15), which the backfill confirms.

### D12: service layers

- **Formation services** are student actions and check formation open/closed and status. **Coordinator services** (`Groups::Coordinator::`) ignore formation being closed, never change status from membership actions, and account for projects and enrolments.
- Separate small coordinator services, not one service with an override flag (a flag makes it easy to pass the bypass from a student path). Both namespace levels kept on purpose: the permission belongs in the policy, the folder shows the split, and flat `Groups::CoordinatorConfirmer` gives six similar names.
- Leader kick is a formation service, `Groups::Kicker#kick!`. `MemberRemover` is coordinator-only. Shared steps (remove membership, promote next leader, delete group if empty) stay a private helper, not a new abstraction.
- `Importer` is the first coordinator service and sets the pattern.
- Group writes that bypassed services become services: group delete (R12). The approval-toggle services built in P2 are deleted in P2b (D28).

### D13: mode switches keep not-confirmed groups

`disable_grouping!` and `revert_to_default_mode!` no longer call `destroy_draft_groups`; delete it and flip the two "destroys" tests in `course_grouping_settings_test.rb` (lines 112, 140) (T17). Leftover groups can sit around after grouping is off, so the O11 banner covers that. They keep Tmp names (D27). Where they show is settled by D30. Landed in `13f5a33` (mode methods and `destroy_draft_groups` deleted; tests updated). Spec line and plan text change.

### D28: joining (built in P2b, two PRs)

- Gone: the "Require approval to join" toggle (`locked` column) and Leader #2 "Choose who can join". `Groups::Joiner` stays for direct joins into not-confirmed groups.
- **Part 1:** delete both `ApprovalToggler` services, `GroupsController#update` and its route, the Manage switch, the table's request button, and the lock gates in `Groups::Joiner` and the requester. **Part 2:** drop `project_groups.locked`. No `ignored_columns` step. The `locked` rename is removed from P7.
- Join requests are closed for every group until P4c. The requester refuses a not-confirmed group with `:group_not_confirmed` (final rule stays in the service). `ProjectGroupPolicy#request_to_join?` returns false (explicit policy exception); P4c flips this one line.
- Request plumbing stays for D29: `join_requests` route, `GroupJoinRequestsController`, the requester, `GroupInviteResponder`, the leader's incoming-requests list, the "Request sent" table branch.
- A data migration in P2b deletes every pending request (D31).
- `direct_` renames stay in P7 (I4).

### D29: confirmed groups taking members (built in P4c)

- Accepting a request, invite or link into a confirmed group reopens it and notifies every member. It takes the course lock (D21) and runs the shared invite/request cleanup (B8).
- Copy (decided): "Group reopened because X joined.", X being the joining student's name. It is the notification every member receives (a new `GeneralMailer` action until the `GroupMailer` rename, I5) and the confirmation the accepting leader sees. It still has to be wired up in P4c.
- A project freezes membership and clears pending requests and invites (on project creation).
- Imported groups cannot be reopened, so they are closed to students for requests, invites and links. Coordinators still add, remove and delete.
- Misuse is blocked in the service and the policy; the button is hidden. Student joins into confirmed groups change N (D2).
- Depends on P3a (shared cleanup, enrolment re-check), P4 (Tmp naming), P4b (Reopener).
- Rationale (owner): any student-driven membership change leaves confirmability unenforced, so the group reopens and the leader re-confirms. Coordinator changes never reopen (D6). A reopened group is not confirmed and takes direct joins until it is confirmed again (D28).
- A full confirmed group refuses requests, invites and links (`:group_full`), and the formation table shows "Full" (U1). Links are deleted on confirm, reopen and project creation (D33). A leader kick from a confirmed group reopens it too (D34).

### Origin column

- When behaviour depends on where a record came from, store it; don't derive it from side effects (the fingerprint "no leader, no sequence" only worked until the backfill gave imported groups a leader). String column, not boolean, so a third source (API sync) needs no migration. No DB check constraint, for the same reason.
- Backfill stamps `import` using the fingerprint, once, in the same migration that assigns leaders (before its confirm step, because the fingerprint reads `confirmed`). The Importer sets `origin: import` on every group it creates. Built in P1b: column, enum (`origin_import?`, `origin_formation?`), Importer stamp, backfill stamp, Reopen guard.
- Imported groups are always confirmed and have no student actions at all. Coordinators can still add, remove and delete; nobody can reopen. Course 3's 4 groups are fingerprint groups, so they become `import`.
- Guards so far: only Reopen (service `:imported_group`, policy `reopen?` false). Every other student write service already refuses a confirmed group. The rest arrive with P4c. The UI hides the buttons.
- UX decided: students in imported groups see the normal confirmed-group rendering (slim My Group line, read-only formation view); no special copy. P4c's origin-hiding pass may revisit.

### D30: Groups tab content (DECIDED, ADR 0026)

Unconfirmed groups appear on the Groups tab only while formation is not open (closed by date or grouping disabled). While formation is open the tab is confirmed-only; coordinators manage unconfirmed groups on the formation page. Built in P4b:

- O11 banner, amber rows, quiet "Not confirmed" pill and "Not confirmed" filter apply only while formation is not open; unconfirmed groups are hidden while it is open (both sentences — unconfirmed groups and ungrouped students — share one banner).
- A student in an unconfirmed group no longer sees it on the Groups tab while formation is open; My Group on the Overview keeps their context.
- The Groups-tab Manage dialog gains a coordinator Status section (Confirm / Reopen); the tab is read-only for students and lecturers.
- O11, O14, O7, O8 are settled on this; `groups_with_status` changed; ADR 0024's read-mostly characterisation is amended by ADR 0026.

### D31: lifecycle of pending join requests

Why: nothing cleared a pending request when a coordinator adds the student, a group is confirmed/reopened, formation closes, or the student leaves the group/course. A leader could later accept a stale request; after D29 that would also reopen a group and notify everyone.

- A request exists only for a confirmed group (D28). Nothing can create one until P4c.
- A pending request is deleted silently (no email) when: the student lands in any group (direct join, accepted invite/request, redeemed link, coordinator add; one shared method, B8, P3a); the group is reopened (P4b); a project is created on the group (P3a); the student leaves the course (O2, P3a); the group is deleted (already true, `dependent: :destroy`).
- At accept time the responder re-checks the student is still enrolled and ungrouped (B6, R10, P3a).
- Declining keeps its row with status declined. No withdraw feature (E5).
- **Expiry DECIDED:** 24 hours, matching invite links; an expired request cannot be accepted. Needed before P4c (now unblocked). Mechanism DECIDED (revision 15): derived from `created_at`, no column. The requester deletes the sender's expired pending request for that group inside the group lock before creating a new one, because the pending-request unique index ignores expiry. Every request list (the student's "Request sent", the leader's incoming list, the formation bell) filters with `unexpired`, so after 24 hours the student sees "Request to join" again (U5).
- At the D28 deploy a data migration deletes every pending request (P2b); otherwise a student with a pending request on a not-confirmed group would see "Request sent" where Join should be.

### D33 to D36: details (revision 15)

**D33: invite links.**

- Confirm (student and coordinator), reopen (student, coordinator, and the reopen an accepted request, invite or link triggers) and project creation delete every link of the group, silently, through one shared call inside the existing lock.
- A link redeemed into a confirmed group reopens it, and that reopen deletes the link, so on a confirmed group a link works once. On a not-confirmed group it stays multi-use until it expires, is disabled or is replaced.
- Pending direct invites are not touched by D33.
- Disable link (U4) deletes every link of the group; "Generate new link" keeps replacing them. A stale expired link showing in the Manage dialog is accepted (E10 WONTFIX).

**D34: leader kick from a confirmed group (amends D7).**

- Allowed when the caller is the leader, formation is open, the group has no project and is not imported. Everything else stays coordinator-only (D7, D9).
- Not-confirmed group: unchanged, no status change.
- Confirmed group: course lock then group lock in one transaction (N changes, D21). Remove the member, then the shared `ProjectGroup#reopen!` (new `Tmp###`, pending requests cleared per D31, links per D33). Mail is enqueued after commit (D20, E6) to every remaining member: "Group reopened because X was removed." (X is the removed student); the leader sees the same line as the flash. Reuse the P4c reopen notification with a removed variant rather than a second mailer, unless the template cannot express it.
- The kick button on a confirmed group opens a confirm dialog: "Remove X? The group will be reopened and renamed to a Tmp number, and you'll need to confirm it again."
- The reopened group takes direct joins until the leader confirms again. That is inherent to D28 and already true after a request, invite or link reopen.
- Unchanged: students cannot self-leave a confirmed group; coordinator removal never changes status (T2, T4, T16); the leader cannot kick themselves.

**D35: where requests appear.** Three surfaces and no others: the "Request to join" button on the formation table (U1), the leader's Join requests section in the Manage dialog on a confirmed group (U2), and the existing bell on the formation page (U6). Overview and the Groups tab get none. The bell lists actionable items only (a leader's incoming requests, an ungrouped student's invites), has no read/unread state, and the reopen notice stays email-only. A bell in `application.html.erb` for features outside group formation comes after group formation ships.

**D36: formation open/closed.** One concept. Stored: `group_formation_enabled`, `group_formation_closes_at`. Derived: `Course#group_formation_open?` (enabled and not past the close date), the only definition of open. P4d renamed the code and updated this prose. Student-facing buttons (Manage, Reopen, Request to join) are hidden when formation is closed and the policies agree; coordinators are unaffected (D6).

## 1b. State model and service map

Formation open/closed (course) and status (group: not confirmed/confirmed) are separate axes. Size (below min, ok, above max) is a derived warning, not a state. Formation actions need formation open. Coordinator membership actions never check formation being closed and never change status (D7). Coordinator Confirm/Reopen are separate explicit actions (D6). Status means the leader locked membership and may start the proposal.

| | Formation open | Formation closed |
|---|---|---|
| **Not confirmed** | Students: create, join, invite, link, leave, leader kick, confirm. No join requests (D28). Coordinator: add, remove, delete, confirm | Students: read only. Coordinator: add, remove, delete, confirm. O11 banner flags these groups |
| **Confirmed** | Students: leader reopens (no proposal, not imported). Nobody self-leaves, leader included (D7); the leader can kick, which reopens the group (D34). New members by request/invite/link reopen the group (D29). Coordinator: add, remove, delete, reopen (no proposal, not imported) | Students: read only. Coordinator: same |

Imported groups (`origin: import`): always confirmed, no student actions.

| Current | Proposed | Notes |
|---|---|---|
| `GroupCreator` | `Groups::Creator#create!` | Course lock, names Tmp### lowest free (D27), checks `grouped?` (D25) |
| `GroupJoiner` | `Groups::Joiner#join!` | Direct joins, not-confirmed groups |
| `GroupDirectRequester` | `Groups::JoinRequester#request!` | Confirmed groups only; closed by policy P2b to P4c |
| `GroupDirectInviter` | `Groups::Inviter#invite!` | Drops `direct_` (I4) |
| `GroupInviteResponder` | `Groups::InviteResponder#accept!` / `#decline!` | Requests and invitations |
| `GroupInviteLinkGenerator` / `Redeemer` | `Groups::InviteLinkGenerator#generate!` / `Groups::InviteLinkRedeemer#redeem!` | |
| `GroupConfirmer` | `Groups::Confirmer#confirm!` | Student leader. Course lock then group; lowest free G### |
| `GroupReverter` | `Groups::Reopener#reopen!` | Blocked `:has_project`, `:imported_group` (done). Course lock; releases G number, new Tmp### |
| new | `Groups::Coordinator::Confirmer`, `::Reopener` | D6, T15 |
| `GroupMemberAdder` | `Groups::Coordinator::MemberAdder#add!` | Coordinator only |
| `GroupMemberRemover` | `Groups::Leaver#leave!`, `Groups::Kicker#kick!`, `Groups::Coordinator::MemberRemover#remove!` | Below |
| new | `Groups::Coordinator::Importer` | C1: coordinator, no formation-open check, confirmed groups, first CSV member leader, no sequence, `origin: import`, course lock, sets `course_id` on members (B3) |
| new | `Groups::Coordinator::GroupDeleter`, enrolment-removal handler | Names tentative. Enrolment removal shares MemberRemover. GroupDeleter warns before deleting a group with a project |
| `GroupLeadersController#update` | deleted (D26) | |
| `GroupsController#update` (locked) | deleted (D28, P2b) | |
| `GroupsController#destroy` | `Groups::Deleter#delete!` | Formation open, not confirmed, group lock |
| grouping settings in `handle_settings` | saved under the course lock | O3, D21 |
| `Queries::GroupSizeConfirmabilityCalculator` | unchanged | Renames only (D2) |

- **Leaver (self):** formation open required, not-confirmed only (`:group_confirmed` otherwise, leader included), promotes leader, last member deletes the group, refuses whenever a project exists.
- **Kicker (leader):** formation open, no project, not imported; a kick from a confirmed group reopens it under the course lock (D34).
- **Coordinator::MemberRemover:** any state, no formation-open check, no status change, promotes a leader; last member with proposal needs the server-side confirm step; enrolment removal shares it.
- The controller picks by `current_user == member.user` and role.

## 1c. Settled answers not captured above

- Students keep the Groups tab (they need projects and supervisors); formation and Groups pages stay separate (but see D30).
- Supervisor capacity and topic races are out of scope (owner will flag separately).
- Group rename does not exist and is not planned (I11).
- Moodle comparison: copy naming by user verb, not its model.
- App-wide in-app notifications (a bell in `application.html.erb` for features outside group formation) come after group formation ships (D35).
- Rebase onto main is deferred by the owner: do it before merging to main (production Rails 8.1.4, lockfile 8.0.2), not before P2b.

## 1d. Entry points, gates, empty states

Entry points: the Groups tab is the only nav entry; a "Group formation" button on the Groups tab while formation is open; Overview says "Find or create a group" (students) or shows a static Group formation block (coordinators and lecturers, not a summary card), linking straight to formation; keep the normal tab strip on the formation page; no formation entry after close.

| State | What shows |
|---|---|
| Grouping off | No button. Students see the closed message; the staff formation block is hidden |
| Open, student without group | "Find or create a group" to formation, plus Groups tab button |
| Open, student in a group | Group status line with a link to formation |
| Formation ended | Closed message, no formation button. Coordinators get the banner if groups are unconfirmed |

Overview empty states: `_project_details_card` already splits coordinator/non-coordinator copy (coordinator has a Settings button); the formation block follows the same split.

- Coordinator: "Group formation is closed." + Settings button; the attention banner replaces the block when unconfirmed groups or ungrouped students exist. No "Enable it" copy.
- Student: "Group formation is closed. Contact your coordinator if you are not in a group yet."
- Lecturer: the formation block with the non-coordinator copy, no Settings, no banner.
- "Closed" has two causes (grouping off, formation closed); both end at the settings page, so one message works. This also fixes the "Browse groups" CTA that led to a closed page.

Formation page after close: `group_formations/show.html.erb` (~lines 101-105) already renders a read-only empty state ("Grouping is closed by your coordinator", "Your existing groups are still visible on the Groups tab"). Gaps: wrong heading when formation simply closed by date, and no status for the student's own group. Replace with the closed message and add the own-group status line.

## 1h. Open decisions and unfinished checks

Resolved and recorded above: D2 and the old Q5 (the current algorithm stays, B5 dropped), F5 (D32), the D29 reopen-notification copy, D30 (ADR 0026), request expiry (D31, 24 hours), imported-group UX (normal confirmed-group rendering), the D27 naming amendment, and the UI questions settled in `docs/Grouping/UI_GAP_ANALYSIS.md`. "Tmp" label stays.

Still for the owner:

1. **Coordinator view of the bell** (U6): the bell renders only for students today (`is_student`); confirm that coordinators need no bell, or say what they should see. The P4c UX surfaces themselves are settled (D35): the "Request to join" button on the formation table, the leader's Join requests section in the Manage dialog, and the existing bell on the formation page.

Unfinished, not decisions:

- Read-only production checks in section 8 and the T23 backfill dry run (owner, before deploy).
- Full-suite and rubocop run (the settings UI pass changed about 44 test files and only targeted runs are recorded).
- Rebase onto main (production Rails 8.1.4, lockfile 8.0.2) before merging to main.

## 2. Bug register

Done items (kept for reference, no action):

| ID | What was done |
|---|---|
| B1, B2, I8 | Re-audited against HEAD; T1 to T3 pass; no change needed (I8 residual: coordinator removing the last member from the group's edit page, covered in T4) |
| B3 (High) | `course_id` on `project_group_members`, unique `(course_id, user_id)`; all inserts go through `ProjectGroupMember.add(user:, group:)` (inserts in a savepoint, returns false on unique violation; services map it to `:already_grouped`; `exists?` kept for the friendly message). Used by Creator, Joiner, Responder, Redeemer, Adder, Importer |
| B4 | DROPPED under D7 (`legal_at_current_size?` deleted) |
| B9 | Member reloaded inside the lock; successor ordered by `created_at, id` |
| B14 (High) | Group lock in project creation plus partial unique index (D22); friendly error on `RecordNotUnique` |
| B15 | Coordinator detection uses `exists?(role: :coordinator)` in `GroupsController` and `ProjectGroupPolicy` |
| B16 (High) | `ProjectsController#create` PostHog payload read the block-local `topic`, so every successful create raised `NameError` after commit; now reads `@instance.source_topic_id`. Regression tests cover own and topic-based proposals and assert the redirect plus `source_topic` |
| O9 | `project_group_must_be_confirmed` is `on: :create`; reopen blocked with a project (T14) |
| O15 | Backfill confirms every not-confirmed group that already has a project, in every course (general rule). Covers course 3's 4 groups |
| C1 to C3 | Importer, backfill, skip-and-report (section 2c) |

Open:

| ID | Sev | Where / problem | Fix | Phase | Status |
|---|---|---|---|---|---|
| B5 | Med | `Queries::GroupSizeConfirmabilityCalculator#confirmable_size?` does not implement the quota model the spec described (N=10, min 2, max 5: spec gave 5+5, code also confirms a 2 or 4) | No code change: D2 kept the feasibility check; the spec is updated to match (section 7) | P5 | DROPPED (not a bug) |
| B6 | Med | `GroupMemberAdder#add!`: `already_grouped`/`group_full` checked before `with_lock`; no enrolment/role check in the service (controller guards with `@course.students.find`); does not clear pending invites/requests | Checks inside the lock, require enrolled student, call shared cleanup (B8). Responder re-checks enrolment and ungrouped at accept (D31, R10) | P3a | DONE (`ffe8c9a`) |
| B7 | Med | `GroupJoiner#join!`: `group_max.to_i` makes nil max 0, so every group reads full; others use `group_max.present? &&` | Same nil handling everywhere (D3) | P4 | DONE (`Course#group_full?`) |
| B8 | Med | Clearing conflicting invites done three ways: Joiner clears only own requests, Redeemer/Responder sent or received, Adder none. Spec: after joining anywhere, other pending invites/requests disappear | One method (e.g. `ProjectGroupInvite.clear_pending_for!(user, course)`) in all four; also clears a student's pending requests whenever they land in any group (coordinator add included); runs when a request into a confirmed group is accepted (D29) | P3a | DONE (`ProjectGroupInvite.clear_pending_for!`) |
| B10 | Low | Generator: formation-open/confirmed checks outside lock; Redeemer: expiry outside lock; generator replaces only same-sender links (two live links after leader change); token 8 bytes | Checks inside lock, replace all links of the group, 16-byte token | P4 | DONE (generator replaces every link of the group and uses a 16-byte token; formation-open, confirmed and expiry checks are inside the lock) |
| B11 | Low | `rescue StandardError => e` then `alert: e.message` leaks internals; `GroupDirectInviter`/`Requester` map any `RecordInvalid` to `:already_invited`/`:already_requested` | Remove broad rescues; rescue `RecordNotUnique` or the specific validation. (Controller rescues went with R12/D26/D28.) | P4 | DONE (inviter and requester narrowed to the specific validation and `RecordNotUnique`; `handle_settings` in the P4 close-out: `update!` + `rescue ActiveRecord::RecordInvalid` → `render_invalid_settings`, capacity-updater failure renders its errors after rollback, unexpected errors propagate) |
| B12 | Low | `ProjectGroup#has_project?` calls `.exists?` on a `has_one` (raises); unused. D9 needs a working check (T14 says `has_project?` works: verify before touching) | Delete or replace, test-first | P4 | DONE (`has_project?` removed; D9 checks use `project.present?`) |
| B13 | Low | CSV import (grouped and solo functions) passes `group_member[:email]` to invite mailers; the parsed key is `email_address`, so mail goes to nil | Use `email_address`. Behaviour change (emails start sending), so its own commit | P3a | DONE (`ffe8c9a`: both import paths read `email_address`; it shipped inside the P3a commit, not its own) |
| F5 | Med | `ProjectsController#new` and `#create` require a confirmed group only when the grouping switch is on; `Project#project_group_must_be_confirmed` requires it always. In a grouping-off course with a leftover not-confirmed group (D13), `#new` shows the form and `#create` fails with "cannot be a draft group" | D32: drop the grouping switch condition in both places. Test first: a grouping-off course with a not-confirmed group redirects from `#new` and `#create` is refused | P4 | DONE (D32 landed in the P4 close-out; both tests fail-first then green; `OverviewPresenter#show_my_submission?` and `CoursesController#submission_state_for` checked — no grouping-switch mismatch there) |

### 2b. Ownership and overlap

| Area | Lives in today | Should be owned by |
|---|---|---|
| Formation writes | Group* controllers, 11 services | `Groups::` (coordinator under `Groups::Coordinator::`) |
| Grouping settings transitions | `CoursesController#handle_settings`, `Course#disable_grouping!`, `#revert_to_default_mode!` | Grouping, called from course settings |
| CSV import of grouped courses | `CoursesController#create_db_entries_grouped`, `Course#parse_csv_grouped` | Course import, with group rows created by `Groups::Coordinator::Importer` (2c) |
| Student removed from course | `EnrolmentsController#destroy` | Enrolments, calling `Coordinator::MemberRemover` (D11) |
| Group list/search/status filter (read) | `GroupsController#index` + `ParticipantBrowsing`, `PeopleController`, `GroupFormationsController#filtered_groups` | Two surfaces on purpose (ADR 0024); share only the name-match predicate |
| "User's group in this course" | `current_user.project_groups.find_by(course:)` in 4 controllers; a join query in `GroupFormationsController` | `Course#group_for(user)` |
| Proposal needs a confirmed group | `Project#project_group_must_be_confirmed` | Projects, `on: :create` |
| Group emails | six templates in `GeneralMailer` | A `GroupMailer` (rename with I5) |

| ID | Sev | Finding | Fix | Phase | Status |
|---|---|---|---|---|---|
| O2 | Med | `EnrolmentsController#destroy` passes `dissolve_confirmed: true`: removing the last student silently deletes group and proposal; removal and `enrolment.destroy!` not in one transaction; the student's pending invites/requests stay; `GroupInviteResponder#accept!` has no enrolment check | One transaction; drop `dissolve_confirmed` (server-side warning, D23); call `Groups::Coordinator::MemberRemover` (the current `confirm: true` is a P2 shim, remove it); course lock then group (D20, D21); clear pending invites and requests with the shared helper (B8, D31); enrolment check inside the lock in Responder and Adder (B6, R10); removed leader replaced by earliest member (T20) | P3a | DONE (`ffe8c9a`: `Groups::Coordinator::EnrolmentRemover`, confirm-removal step) |
| O3 | Med | `handle_settings`: when Prevent leftover students is switched off, the elsif branch only reverts mode and skips the else update, so min, max, open flag and dates edited in the same save are dropped. `Course#enable_auto_confirmability_mode!` unused. Transitions live in the controller inside `rescue StandardError` showing `e.message` | Save grouping settings under the course lock in `handle_settings`, mode switch and field updates in one update (D21, R11). Test the combined save | P4 | DONE (`handle_settings` saves mode and field changes in one update under the course lock; combined-save tests in `courses_controller_test.rb`) |
| O4 | Med | `ProjectGroupPolicy#confirm?`/`#revert?` true for anyone with `manage_groups?`, contradicting the old spec; no coordinator Confirm/Reopen button found in searched views (reachable by direct request); `GroupConfirmer` still blocks when formation is closed | Policies follow D6 (coordinator via `Coordinator::` services; lecturers/students cannot call, T15); `reopen?` false with a project (D9) | P4b | DONE (`1ae5cef` and follow-ups) |
| O5 | Low | `courses.lecturers_can_manage_groups` default true, no UI, OPEN_ITEMS.md [F] says drop | D10: delete `manage_groups?` (11 sites), migration drops column, update OPEN_ITEMS.md; flip the lecturer test (T31) | P4 | DONE (`1a81641`; `manage_groups?` stays as the coordinator-only gate) |
| O6 | Low | Same lookups written several times: user's group (5 places), ungrouped students (3), name search (2) | `Course#group_for(user)`, `Course#ungrouped_students` (I6), one name-match helper | P4 | DONE (`Course#group_for`, `Course#ungrouped_students`) |
| O7 | Low | Course (229 lines) owns `disable_grouping!`, `revert_to_default_mode!`, `unconfirmed_students_count`, `groups_with_status`, `parse_csv_grouped` | Move only when touched: settings transitions to O3's service, `groups_with_status` next to `ParticipantBrowsing`, CSV parsing with import. `disable_grouping!`/`revert_to_default_mode!` stop calling `destroy_draft_groups` (D13) | P7 | TODO |
| O8 | Low | `GroupsController` serves the Groups tab and the writes (ADR 0024, 0025) | Intentional; no action beyond O6 | - | WONTFIX |
| O11 | Med | After students cannot act, not-confirmed groups can sit with no student able to confirm them, also after grouping is off (D13) | Banner and rows (below) | P4b | DONE (`1ae5cef` and follow-ups) |
| O14 | Med | Overview `submission_state_for` returns `:no_proposal` for a student whose group has no project, so they see "Create proposal", which validation rejects. A student with no group in a formation-closed course sees "Browse groups" leading to a closed page. `ProjectsController#new` only checks for an existing project; `create` fails later | Overview hides My Submission for a not-confirmed group; the My Group card carries the hint. CTA reads "Find or create a group" and follows 1d. `ProjectsController#new` redirects a student with no confirmed group to Overview with an explanatory flash | P4b | DONE (`1ae5cef` and follow-ups) |

**O11 banner and rows:** show when students can't act (formation not open: closed or disabled) and not-confirmed groups exist; coordinators only. Copy: "Group formation is closed. 3 groups are not confirmed, so their members cannot submit a proposal. Review and confirm them." Singular: "1 group is not confirmed...". Add the ungrouped-student count when closed. Yellow rows only in that state, quiet "Not confirmed" pill otherwise. Add "Not confirmed" to the existing status filter. Also flags imported groups in grouping-on courses for the coordinator to confirm (groups with a project are confirmed by the backfill, so never listed).

### 2c. CSV import (not owned by grouping, still blocking)

| ID | Finding | Fix | Status |
|---|---|---|---|
| C1 | Import created unconfirmed, leaderless groups; `Project` validates `group.confirmed?`, so a grouped-CSV course could not create a project; leaderless groups also broke join requests. Seeds set `confirmed: true`, hiding it | `Groups::Coordinator::Importer` creates confirmed groups, leader = first member in CSV order (no leader column), no sequence, `origin: import`, course lock, `course_id` on members. Backfill migration as its own PR (below). T13, T22, T23 | DONE |
| C2 | Already-grouped student was moved by `update!`, leaving a stale `leader_id` or an empty group, and could pull someone out of a group with a proposal | Leave the student, report "Carol was already in a group and wasn't moved." (matches Moodle skip-and-report). T13, T22 | DONE |
| C3 | No-op `ProjectGroupMember.where(user:).pluck(...)` line; `find_or_create_by!(group_name:)` can duplicate generated names. Reuse by name is existing behaviour and kept | Folded into the Importer; unique `(course_id, group_name)` (I11) | DONE |
| C4 | Moodle uses a separate unique `idnumber` as stable external id; ProPro uses the name | Suggestion only | SUGGESTION |

P1b backfill rule (migration is its own PR):

- Give every group with members and no leader its earliest member as leader (all courses).
- Confirm imported (fingerprint) groups only in grouping-off courses (nobody else can confirm them; project creation silently fails there). In grouping-on courses leave status alone (students may be mid-formation; the O11 banner flags them). Exception: a group that already has a project is confirmed in every course (O15).
- Fingerprint: `confirmed = false AND leader_id IS NULL AND course_group_sequence IS NULL`. App-created groups always got a leader and a sequence, so this is reliably a CSV import. Do not set `course_group_sequence` for imported groups (nothing reads it besides Creator; it would make them consume G numbers that don't match their names).
- The migration prints: imported groups confirmed, groups confirmed because they have a project, leaders assigned. Data migrations: raw SQL, idempotent. Re-run counts before deploying (a new import changes them).

### 2d. Race-condition audit

Scope: grouping writes only. Vocabulary: a row lock serialises concurrent requests (the second waits, then checks current data); a DB constraint needs no lock; where no constraint can express the rule, the check must be inside the lock. Reference apps (read 2026-11-02): GitLab `InternalId` (one counter row, atomic `UPDATE ... RETURNING`, never reused: the pattern behind D17/D27); Canvas (size as a racy model validation, one-group-per-category healed after the fact: doesn't fit "confirmed means final"); Discourse (unique indexes both directions, the DB is the guard: R1). Redis mutexes don't fit (no Redis).

| ID | Race | Fix | Phase | Status |
|---|---|---|---|---|
| R1 | Student in two groups of one course | Unique `(course_id, user_id)` (B3) | P1b | DONE |
| R2 | Group exceeds max: only Adder checks outside the lock (coordinators can override max anyway, so low) | Adder checks inside the lock (B6) | P3a | DONE (`ffe8c9a`) |
| R3 | Two groups confirm at once (write skew on N): Confirmer locks only its group but `confirmable?` reads the course-wide `unconfirmed_students_count` | Course lock first, then group, in every writer of N (D21); calculator untouched (D2). Only matters in prevent-leftover mode but always taken. Accepts into confirmed groups also take it (D29) | P3a | DONE (`ffe8c9a`) |
| R4, R5 | Two projects for one group; Reopen vs project creation | Group lock in project creation plus partial unique index (D22, B14) | P1b | DONE |
| R6 | Group number collision | Lowest-free naming under the course lock (D27 amended); unique `(course_id, group_name)` index; Importer also takes the course lock | P4 | DONE (`13f5a33`) |
| R7 | Duplicate pending invite/request | Partial unique indexes plus `rescue RecordNotUnique`; B11 narrows the rescue | - | OK |
| R8 | Checks outside the lock (Generator, Redeemer, Adder) | B6, B10 | P3a, P4 | DONE (Adder `ffe8c9a`; Generator and Redeemer checks are inside the lock, B10) |
| R9 | Waiter on a deleted group: `with_lock` reloads and raises `RecordNotFound` (controller handling not checked) | One shared helper rescues it after `with_lock`, returns `:group_gone` | P3a | DONE (`Groups::GroupLocking::GROUP_GONE`) |
| R10 | Enrolment removal vs join: not one transaction; Adder and Responder have no enrolment check | O2: one transaction, course lock first; joining services check enrolment inside the lock | P3a | DONE (Adder, Responder and Redeemer check enrolment inside the lock; enrolment removal is one transaction, O2) |
| R11 | Settings change vs concurrent join/confirm | A join racing a settings save equals the action landing a second earlier: accepted. Settings saved under the course lock in `handle_settings` (O3, D21) | P4 | ACCEPTED |
| R12 | Group writes outside services (`GroupsController#update`/`#destroy`) | Group delete service; the toggle services are deleted in P2b | P2 | DONE |
| R13 | Course lock deadlock (plain `FOR UPDATE`) | `FOR NO KEY UPDATE` (D20); threaded regression racing coordinator removal vs join | P2 follow-up | DONE |

| ID | Sev | Edge case | Decision | Phase | Status |
|---|---|---|---|---|---|
| E1, E2 | High, Med | `dissolve_confirmed` param skipped the warning; coordinator delete of a confirmed group deleted the project silently | D23 (T28) | P2 | DONE |
| E3 | Med | `ensure_grouped` only on `GroupsController#index`/`#show`; coordinator/lecturer paths have no formation-open check, so a group could be created in a solo course (unverified) | D25: `ensure_grouped` on every group controller action; Creator and Importer check `grouped?` (T30) | P4 | DONE (`78953f3b`: `RequiresGroupedCourse` concern + service checks) |
| E4 | Med | Invites from a member/leader who has left or been kicked stay acceptable (policy checks only the recipient). Pending requests keep the old leader as `recipient_id`, but `accept?` uses the current leader | D24 callback (T29) | P3a | DONE (`ProjectGroupMember` `after_destroy`) |
| E5 | - | No withdraw for invites/requests | Not wanted | - | DROPPED |
| E6 | Low | `deliver_later` passes the invite by GlobalID; `clear_conflicting_invites!` and `dissolve!` delete invites so a queued "new join request" email can fail with `DeserializationError`; Responder enqueues mail inside `with_lock`; whether solid_queue enqueues inside the transaction was not checked | Enqueue after the lock block commits; discard the mail job on `DeserializationError` | P4 (close-out) | DONE (initializer `config/initializers/action_mailer.rb` — `MailDeliveryJob.discard_on ActiveJob::DeserializationError` — landed with `ffe8c9a`; regression test added in the P4 close-out PR: enqueue a group mail, destroy the invite, `perform_enqueued_jobs` — canary without the initializer raises `DeserializationError`, with it the job is discarded) |
| E7 | Low | `User has_many :project_group_members, dependent: :destroy` (and enrolment deletes) bypass succession/empty-group cleanup; `project_groups.leader_id` FK to users has no `ON DELETE`, so deleting a leader's user errors. Unverified whether user deletion is a real path | Check; if real, route it through `Coordinator::MemberRemover` | P4 (close-out) | DONE (no in-app path: `user#destroy` route/action, admin panel, Devise registrations and user-deleting rake tasks all absent — console-only. Empirically: deleting a leader or any user with a pending invite/request row raises `ActiveRecord::InvalidForeignKey` (loud); only a plain member deletes silently, bypassing cleanup — acceptable for a console-only path, WONTFIX) |
| E8 | Low | Formation open had two sources (`grouping_open` flag, opens/closes dates); nothing flipped the flag when `group_formation_closes_at` passed. Raw reads of `grouping_open?` were wrong after close (not grepped) | Grep and replace with `group_formation_open?` | P4 | DONE (ADR 0027: `grouping_open`/`grouping_opens_at` dropped, formation open/closed derived; no raw reads remain) |
| E9 | Med | Every CamelCase `GeneralMailer` group action cannot find its lowercase template on a case-sensitive filesystem (Rails 8 uses `action_name` verbatim), and `Subject:` (capital S) is ignored so the subject falls back to the humanized action name. Verified in the test env: `Group_Direct_Invite_Notification.deliver_now` raises `ActionView::MissingTemplate`; it would only appear to work on a case-insensitive macOS checkout. The P4c `Group_Reopened_Notification` avoids both traps (`subject:`, action-matching template names) | Rename the existing templates to match their action names (or pass `template_name:`) and use lowercase `subject:` | P4f | TODO (owner: keep the existing template content, rename only; requests mail leaders again from P4c, so this ships with the UI half) |

**Test infrastructure finding (unverified by running).** Thread race tests for Creator, Joiner, Responder and Requester live in transactional `ActiveSupport::TestCase` classes; Rails shares one connection across threads, so row locks cannot conflict and the tests may pass without testing concurrency. `GroupWriteLockTest` opts out and runs against committed rows. Canary: remove `with_lock` from `GroupJoiner` (`@group.with_lock do`, line 9) and run its thread test; if it still passes it is vacuous. Fix: race tests go in non-transactional classes (`self.use_transactional_tests = false` with DatabaseCleaner truncation, as `ApplicationSystemTestCase` does); record the canary result in the PR description for every race test (T7).

### 2e. P4c follow-ups from the owner's click-through (2026-11-12)

Found by clicking through the P4c backend. U1 to U4 and U6 are the UI half; U5 and the policy parts are backend. The pushed branch did not contain the P4c backend when these were written, so UNVERIFIED rows were read from the pre-P4c code.

| ID | Sev | Finding | Fix | Phase | Status |
|---|---|---|---|---|---|
| U1 | Med | `group_formations/_groups_table.html.erb` renders a disabled "Join" on every confirmed group; the request button went in P2b and never came back. The "Full" branch sits after the `confirmed?` branch, so a full confirmed group never shows "Full". The pre-P4c requester has no `group_full` check | For an ungrouped student on a confirmed group, in this order: "Full", "Request sent" (pending and unexpired), "Request to join" (button to `join_requests`) when `request_to_join?` allows. Nothing when the group has a project, is imported or formation is closed. Requester refuses `:group_full` (verify test-first against the P4c tree); the responder re-checks fullness at accept, so a leader accepting into a now-full group gets the `:group_full` message | P4e (service, policy), P4f (view) | P4e DONE, P4f TODO |
| U2 | Med | A leader loses Manage on a confirmed group. Three gates: `leader_edit = !staff && !@group.confirmed?` in `groups/edit.html.erb`, `group_formations/show.html.erb` renders Manage only in the not-confirmed branch, and `ProjectGroupPolicy#update?`/`#edit?` are false once confirmed. The Join requests section uses the same flag, so a leader cannot see requests on a confirmed group | `edit?`/`update?` true for the leader of a non-imported group with no project while formation is open (named policy exception). `leader_edit` follows `policy(@group).update?` instead of `!confirmed?`. The dialog on a confirmed group has members (kick per D34), Join requests, invite link and invite student; Delete and Leave stay policy-gated (false when confirmed) | P4e (policy), P4f (view) | P4e DONE, P4f TODO |
| U3 | Low | A confirmed group shows only an outline "Reopen group" for the leader | Manage group (filled, `GROUP_FILL_BUTTON`) beside Reopen group (outline), placed like Confirm group and Manage on a not-confirmed group; the emphasis flips because Manage is the primary action once confirmed. Both hidden with a project, for imported groups and when formation is closed. `revert?` gains formation-open for non-coordinators (named exception) | P4e (policy), P4f (view) | P4e DONE, P4f TODO |
| U4 | Med | No way to disable an invite link; only "Generate new link" replaces it, and the section is hidden on a confirmed group | `Groups::InviteLinkDisabler#disable!` under the group lock deletes every link of the group; `DELETE` on the existing `invite_link` route; policy reuses the leader check with formation open. "Disable link" button next to Copy in the Manage dialog, flash "Invite link disabled." A redeemed disabled or replaced link shows the existing no-longer-valid message | P4e (service, route, policy), P4f (button) | P4e DONE, P4f TODO |
| U5 | Med | An expired request keeps `status: pending`, and `idx_pgi_unique_pending_sender_group_kind` ignores expiry, so after 24 hours the student cannot re-request (`:already_requested`) and "Request sent" lists show it indefinitely | D31 mechanism: the requester deletes the sender's expired pending request for that group inside the group lock, then creates the new one. Every request list and the bell filter with `unexpired`. Test first: request, travel 25 hours, request again succeeds | P4e (service; lists already filtered and now tested) | DONE |
| U6 | Low | The bell lives on the formation page only (`content_for :header_actions`) and renders only for students. The header's mobile cluster also holds the coordinator settings and project-template icons | Bell stays where it is (D35). Check the coordinator view of the formation page on mobile and desktop: the bell never collides with the settings and template icons and sits in a sensible position. The bell filters with `unexpired` (U5). Whether coordinators need a bell is an owner question (section 1h) | P4f | PROPOSED |
| E10 | Low | A leader can be shown an expired link token in the Manage dialog | Owner: not a problem. U4 gives the leader a disable button | - | WONTFIX |

## 3. Inconsistencies and structure

| ID | Finding | Action | Phase | Status |
|---|---|---|---|---|
| I1 | 11 hand-rolled nested Result classes; `blocked?` missing on Confirmer/Reverter; Remover and Responder use an outcome enum; service_classes.md mentions a nonexistent `ServiceResult` (GitLab uses one `ServiceResponse`) | One shared result (`success?`, `blocked?`, `reason`, optional data); keep per-service reasons | P6 | TODO |
| I2 | User-facing strings in service `Result#message`, duplicated (formation-closed text in ~8 places, 3 variants of "maximum size") | One locale file keyed by service and reason | P6 | TODO |
| I3 | Calculator has `def self.feasible_count?` (docs say avoid class methods) and a `Result#message` with view copy | Instance method; copy to view/locale | P6 | TODO |
| I4 | `direct_request`/`direct_invite`, `GroupDirectInviter`/`Requester`, mailer `Group_Direct_*`: `direct_` looks vestigial since links got their own table | Rename enum to request/invite and services to match (keep integers, rename only) | P7 | TODO |
| I5 | Mailer actions capitalised (`Group_Direct_Invite_Notification`) | snake_case | P7 | TODO |
| I6 | "Ungrouped students" computed in `GroupFormationsController#show`, `GroupsController#ungrouped_students`, `groups/edit` | `Course#ungrouped_students` | P4 | DONE (`Course#ungrouped_students`) |
| I7 | Dead code: `ProjectGroup#revert_to_draft!`, `#pending_requests` (test only) | Delete (and the test) | P4 | DONE (`78953f3b`) |
| I9 | `GroupConfirmer` typo ("comfirms"); mixed "Not Confirmed" capitalisation | Wording pass | P7 | TODO |
| I10 | `GroupFormationsController` loads all groups and filters in Ruby via `helpers.group_size_state` | Leave until perf matters | - | WONTFIX for now |
| I11 | `group_name` has no uniqueness (no index, no validation) though the importer uses it as identity. Production has no duplicates | Unique index `(course_id, group_name)` plus `validates :group_name, uniqueness: { scope: :course_id }`; Confirmer/Reopener rename in one transaction under the course lock (D27) | P4 | DONE (`13f5a33`: index + validation) |
| I12 | `course_group_sequence` had exactly one reader (`GroupCreator`); nothing displays or sorts by it (table sorts on the `group_name` string) | Column removed in `13f5a33` (D27 amended to lowest-free naming) | P4 | DONE |
| I13 | `GroupCreator` used `MAX(sequence)+1`, ignoring names held by imported groups (CSV `G003` vs generated `G003`) | Lowest-free naming (D27 amended); if the generated name is taken, Creator takes the next number (T21) | P4 | DONE (`13f5a33`) |
| I14 | Numbers reused when the highest group is deleted, gaps otherwise; names already appear in sent emails | Lowest-free naming (D27 amended): a freed number is taken by the next group that needs it; names stay display-only | P4 | DONE (`13f5a33`) |

### 3b. Naming audit outcome

Checked ProPro, Moodle core, the Moodle group self-selection plugin and GitLab. Neither Moodle component has a per-course counter or a confirm state, so the counter is an extra feature, but a per-parent number from a lock-protected counter plus a unique index is a standard pattern and the spec chooses `G001`-style names. Moodle enforces name uniqueness in application code, not the DB (ProPro adds both, I11), aborts autogroup on a name collision rather than renumbering (ProPro's Creator takes the next number), and skips-and-reports existing names on import (C2). `%03d` padding sorts correctly to 999. Deriving names from ids or list position is worse (unreadable, or renumbers on delete).

## 4. Wording and schema rename map (P7)

Do after D1. Pure rename, no behaviour change. Rows marked P4d shipped early, in their own PR, ahead of P7 (D36). `rename_column` keeps data; schedule around the Heroku deploy.

| Current | Spec term | Touches |
|---|---|---|
| `courses.student_list_finalised` | Prevent leftover students (`prevent_leftover_students`) | column, Course validation/methods, calculator `finalised:`, `grouping_settings_controller.js`, `courses/settings.html.erb`, `courses_controller.rb`, ~50 test references |
| `Course#enable_auto_confirmability_mode!`, `revert_to_default_mode!`, "Auto-Confirmability"/"Default mode" | Prevent leftover students on/off | model, controller, docs |
| "draft" (`:already_draft`, `status_filter=draft`, Project validation "cannot be a draft group", comments; `destroy_draft_groups` is deleted in D13) | not confirmed | models, services, controller, view option value, tests. The new Overview/Groups-tab banner and filter links keep the existing `draft` param value until this pass |
| "dissolved" in user text ("Group dissolved.", "...was dissolved.") | deleted | remover and groups controller messages (internal `:dissolved` may stay) |
| "Not Confirmed Group G001 created.", "already a Not Confirmed Group", "Group status changed to not confirmed." | "Group Tmp001 created.", "already not confirmed", "Group reopened." | creator, reverter |
| revert / `GroupReverter` / `revert?` | Reopen (D4) | service, policy, controller |
| "Browse groups" (Overview CTA) | "Find or create a group" | `_overview_tab.html.erb` (O14) |
| "Grouping is closed by your coordinator" | "Group formation is closed." | `group_formations/show.html.erb` (1d) |

`project_groups.locked` has no rename; it is deleted (D28).

## 5. Test plan

Existing: 3 system tests (real Chrome: htmx search, lazy Manage frame, `<dialog>` confirm), 28 integration tests in `group_write_routes_test.rb` (permissions, redirects, DB state, never page content), removal and group-write service tests, `GroupWriteLockTest` (non-transactional, threaded). Older thread tests are transactional and may be vacuous (2d).

DONE: T1 to T3 (rack_test: after leave/removal the pages update; blocked removal alerts), T4 (removal services incl. I8 residual), T6 (second membership in a course raises `RecordNotUnique`), T9, T13, T14, T17, T21, T22, T25, T26 (leader-promotion race dropped, D26; approval-toggle part goes with P2b), T28, T30, T31, T32, T33, T37. T5 DROPPED (D7). T24 DROPPED (D27 amended: counter removed). T36 WIP (reopen refusal DONE). Since revision 12 also DONE: T8, T15, T16, T18, T19, T20, T29, T34.

| ID | Test | Type | Phase | Status |
|---|---|---|---|---|
| T7 | Races in **non-transactional** classes: create vs join, join to two groups, Redeemer last slot, Confirmer double submit, Remover double removal, two groups confirming at once (R3, T27). Canary per race test: remove the `with_lock` or unique index it relies on, confirm the test fails | unit (threads) | P3a | DONE (canaries recorded, P4 close-out: confirmer race without the course lock fails on `PG::UniqueViolation` picking the same G number; member-remover race without the group lock still passes (the course lock alone serializes — defence in depth) and without both locks fails "Expected: 1 removed, Actual: 2"; both project races without `group.lock!` in `ProjectsController#create` fail with `Timeout::Error` at `wait_for_lock_waits` — the creates no longer block on the group row; `index_projects_on_group_owner` (partial unique) is the DB backstop for double creates) |
| T8 | Replace the two tests in `group_member_adder_test.rb` that assert known bugs ("this is the bug", "CURRENT BEHAVIOR") with regression tests; move the Joiner, Responder, Creator, Requester thread tests into the non-transactional class and run the canary on each | unit | P3a | DONE (the two bug-asserting adder tests are gone; the Creator, Joiner, Responder, Requester and Redeemer thread tests use the non-transactional class) |
| T9 | nil `group_max` across Joiner/Redeemer/Responder/Inviter/Adder (D3) | unit | P4 | DONE (all use `Course#group_full?`) |
| T10 | Property test: random confirm orders under prevent-leftover never leave an ungroupable student set (D2) | unit | P5 | TODO (unblocked: D2 kept the feasibility check, so this tests that it never strands students) |
| T11 | Happy-path rack_test system tests: create, join open group, request and accept, invite and accept, invite link, confirm and reopen, coordinator add. Text/DOM; `data-testid` only where markup breaks a test | system | P8 | TODO |
| T12 | Use `with_clues` in browser tests in `group_formation_test.rb` | system | P8 | TODO |
| T15 | D6: `Coordinator::Confirmer` confirms undersized/oversized groups with formation closed; `Coordinator::Reopener` works with formation closed and is blocked with a proposal; lecturer and student cannot call them; student leader still cannot confirm an illegal size | unit + policy | P4b | DONE |
| T16 | `Coordinator::MemberAdder` adds above max; status unchanged; size warning shows | unit | P3a | DONE (`group_member_adder_test.rb`: above max, status unchanged, enrolment checks, cleanup) |
| T17 | D13: `disable_grouping!` and `revert_to_default_mode!` keep not-confirmed groups (flip the two "destroys" tests) | model | P4 | DONE (`13f5a33`) |
| T18 | O14: student in a not-confirmed group sees no "Create proposal"; `ProjectsController#new` redirects a student with no confirmed group; closed message differs for coordinator, lecturer, student; CTA only when formation is open | rack_test system | P4b | DONE |
| T19 | O11: banner and yellow rows only when students cannot act and not-confirmed groups exist; singular/plural; ungrouped count; "Not confirmed" filter; coordinators only | rack_test system | P4b | DONE |
| T20 | O2/D11: enrolment removal of a last member with a proposal warns and deletes nothing until confirmed (server-side); removal and `enrolment.destroy!` share a transaction; removed leader replaced by earliest member; pending invites cleared | integration | P3a | DONE (`enrolment_remover_test.rb`, `member_remover_test.rb`) |
| T21 | I11, I13: duplicate group name rejected; Creator takes the next number when a generated name is taken by an imported group; two concurrent creates give two names (lowest-free under the course lock, D27 amended) | model + unit (threads, non-transactional) | P4 | DONE (naming tests, `13f5a33`; threads part covered by `GroupWriteLockTest`) |
| T23 | P1b backfill on a restored production copy: idempotent; leaders given to every group with members and none; only fingerprint groups confirmed, only in grouping-off courses; grouping-on courses untouched except groups with a project. On the 2026-11-02 data it prints "Confirmed 349 imported groups and 4 groups that already have a project; assigned a leader to 350 groups"; afterwards no leaderless group has members, no fingerprint group is unconfirmed in a grouping-off course, no group with a project is unconfirmed. Re-run counts before deploying | migration (manual) | P1b | OPEN (owner, before deploy) |
| T24 | Tmp counter migration: column starts at 0 everywhere (existing groups are all confirmed and keep G numbers); idempotent | migration (manual) | P4 | DROPPED (D27 amended: counter removed, `13f5a33`) |
| T27 | R3: two groups confirming at once under prevent-leftover are never both confirmed when only one fits; Reopener, Importer, enrolment removal and settings saved in `handle_settings` take the course lock | unit (threads, non-transactional) | P3a | DONE (P4 close-out added the missing assertions to `group_write_lock_test.rb`: coordinator `Reopener` course-then-group, and `EnrolmentRemover` course lock on the no-membership path — the membership path is covered by `MemberRemover`'s own assertion; Importer was already covered under 'group-creating services', student reopen (`GroupReverter`) under 'confirmers', `handle_settings` in `courses_controller_test.rb`; canaries: removing `with_group_lock` fails the group/course-then-group lock-order tests, removing `Course#with_no_key_update_lock`'s lock fails the course ones, removing `handle_settings`' lock fails its test) |
| T29 | E4/D24: removing a member by any path (service and `dependent: :destroy`) deletes that user's pending `direct_invite` records for that group, leaves other groups' invites alone | model | P3a | DONE (`project_group_member_test.rb`) |
| T30 | E3/D25: every group controller returns 404 on a non-grouped course; Creator and Importer return blocked | integration | P4 | DONE (`78953f3b`) |
| T31 | D10: flip `group_formation_page_test.rb` lines 80-81: a lecturer sees no Manage controls | integration | P4 | DONE (`1a81641`) |
| T34 | D27: new group named Tmp### (lowest free); Confirm gives lowest free G###; Reopen releases it and gives a new Tmp###; imported groups keep CSV name and take no number; links and tokens resolve by group id | model + unit (threads, non-transactional) | P4, P4b | DONE (naming `13f5a33`; reopen numbering with the P4b commits) |
| T35 | D28/D29: not-confirmed group takes direct joins; confirmed group takes requests, invites, links, and accepting any reopens it and notifies every member; a group with a project takes no new members and its pending requests/invites are cleared; imported groups closed to students | unit + integration | P4c | DONE (`group_invite_responder_test`, `group_invite_link_redeemer_test`, `group_direct_requester_test`, `group_direct_inviter_test`, `group_invite_link_generator_test`, `group_joiner_test`, `general_mailer_test`, `group_write_routes_test`) |
| T36 | Origin: imported group has no student action (service and policy refuse, UI hides buttons); coordinators can still add, remove, delete; nobody can reopen. Reopen refusal done in P1b; other guards with P4c | unit + policy + integration | P1b, P4c | DONE (service guards in requester/inviter/generator/joiner/responder/redeemer; policy guards in `request_to_join?`/`direct_invite?`/`generate_invite_link?`; reopen refusal P1b; UI buttons are the P4c UI half) |
| T37 | D28: no join request can be created (`request_to_join?` false for everyone; requester refuses a not-confirmed group with `:group_not_confirmed`); migration deletes only pending requests and is a no-op the second time (manual dry run); Manage page has no approval switch; table never says "Request to join"; `PATCH` on the group path is gone | unit + policy + integration + migration (manual) | P2b | DONE (`cc99ea0`) |
| T38 | D31: a student's pending requests are deleted when they land in any group (coordinator add included), leave the course, or a project is created on the group; a group's are deleted on reopen; accept re-checks enrolment and ungrouped; expiry once decided | unit + model | P3a, P4b, P4c | DONE (`ProjectGroup#reopen!` clears pending requests for both reopen paths; `ProjectGroupInvite#expired?`/`unexpired`; accept re-checks enrolment and ungrouped) |
| T39 | D33: confirm, coordinator confirm, student and coordinator reopen, a reopen triggered by an accepted request, invite or link, and project creation all delete every link of the group; a link redeemed into a confirmed group reopens it and is gone afterwards; a link on a not-confirmed group stays multi-use | unit + integration | P4e | DONE (both Confirmers, `#reopen!`, `ProjectsController#create`; confirm-vs-redeem canary) |
| T40 | D34: leader kick from a confirmed group reopens it (Tmp name, requests and links cleared, every remaining member mailed after commit, course lock then group lock; threaded, non-transactional, canary per T7); refused with a project, for an imported group and with formation closed; a non-leader cannot kick; self-leave on a confirmed group still refused; coordinator removal never reopens. Flips the T32 leader-kick expectation | unit + policy + integration | P4e | DONE (kick-vs-redeem canary; coordinator removal unchanged) |
| T41 | U4: the leader disables the link; redeeming it afterwards refuses; another group's leader, a member and a student cannot disable it; takes the group lock | unit + policy + integration | P4e, P4f | P4e DONE, P4f button TODO |
| T42 | U5: an expired pending request does not block a new one (old row deleted inside the lock); request lists and the bell hide it; accepting an expired request refuses; fail-first | unit + model | P4e | DONE (lists already filtered; `.unexpired` tests added) |
| T43 | U1: full confirmed group refuses requests (`:group_full`) and the table shows "Full"; "Request to join" shows only for an ungrouped student on a confirmed, non-imported group without a project while formation is open; "Request sent" while pending and unexpired | unit + rack_test system | P4e, P4f | P4e service/policy DONE, P4f view TODO |
| T44 | U2, U3: the leader of a confirmed, non-imported group without a project sees Manage group (filled) beside Reopen group (outline) and, in the dialog, members with kick, Join requests, invite link and invite student; none of it with a project, for an imported group or with formation closed; Delete and Leave stay hidden | integration + rack_test system | P4f | TODO |
| T45 | D36: schema has `group_formation_enabled` and `group_formation_closes_at`; no pre-rename grouping column or predicate names remain in app/, test/ or db/schema.rb (old migrations excluded); full suite and rubocop green | grep + suite | P4d | DONE (2026-11-12: app/test/db/docs greps clean; `bin/rails test` 576 runs, `bin/rails test:system` 115 runs; rubocop clean on touched files) |

## 6. Phases (in order)

| Phase | Scope | Depends on | Done when | Status |
|---|---|---|---|---|
| P0, P0b | Settle D1 to D5; advisor questions (D6, D7, D11, D12) | - | Decisions recorded | DONE |
| P1 | B1, B2, I8, T1 to T3 | - | Tests pass | DONE |
| P1b | C1 to C3, O9, B3 (R1), B14 (R4, R5), T6, T13, T14, T22, T25; `Groups::Coordinator::Importer`, `course_id` + unique index, D9 reopen block, project group lock + unique index, `origin` column; all member inserts via `ProjectGroupMember.add`. Backfill migration is a separate PR (T23 pending) | Rebase onto main (deferred) | Grouped-CSV course can create a project; imported groups confirmed with first member as leader and no sequence; import doesn't move grouped students; reopen blocked with a project; no group gets two projects; member uniqueness in DB | DONE |
| P2 | `Leaver`, `Kicker`, `Coordinator::MemberRemover`, B9, T4; group delete service (R12, T26); server-side confirmation (E1, E2, D23, T28); `ProjectGroupMemberPolicy#destroy?` change (D7, T32); I8 residual; `ProjectGroupPolicy#destroy?` for coordinators; course lock in `Coordinator::MemberRemover` and `GroupDeleter` (D21); D26 deletions; R13, B15, T33 | D7 | Removal services fully covered; no controller writes a group directly; nobody self-leaves a confirmed group; no lock deadlock | DONE |
| P2b | D28 cleanup in two PRs (brief `D28_APPROVAL_TOGGLE_REMOVAL.md`). **Part 1:** delete both `ApprovalToggler` services, `GroupsController#update` and route, Manage switch, table request button, lock gates in Joiner and requester; close join requests (`request_to_join?` false; requester refuses a not-confirmed group with `:group_not_confirmed`); data migration deletes every pending request (D31); T37. **Part 2:** drop `project_groups.locked` | P1b | Nothing reads or writes `locked`; no request can be created; pending requests deleted; column dropped in its own PR | DONE (`cc99ea0`, `7b4fb2b`; T37) |
| P3a | B6, B8, O2, R2, R3 (course lock in confirmers, T27), R9 (`:group_gone`), R10, E4 (T29), E6, E7 check, T7, T8, T16, T20, non-transactional race test class; B13 (proposed, own commit). D31: shared cleanup clears a student's pending requests when they land in any group (coordinator add included) or leave the course, project creation clears the group's pending requests and invites, Responder re-checks enrolment and ungrouped at accept (T38) | P2b | One shared invite-cleanup method; coordinator removal and enrolment removal are one path with warning and transaction; race tests truly concurrent | DONE (services/locks/cleanup landed `ffe8c9a`, `78953f3b`; E6's discard step and E7 moved to the P4 close-out; B13 fixed in code; race-test canary results not recorded) |
| P4 | B7, B10, B11, B12, I6, I7, I11 to I14, O3, O5, O6, E3, E8, F5, R6, R11; D13 (delete `destroy_draft_groups`); D27 naming; name index; settings under the course lock; T9, T17, T21, T24, T30, T31 | D3 | Small backend fixes in; dead code gone; `manage_groups?` and its column gone (D10); numbers never reused | DONE (landed: B7, B10, B12, I6, I7, I11–I14, O3, O5, O6, E3, E8, R6, D13, D27 naming, T9/T17/T21/T30/T31; R11 accepted; close-out landed 2026-11-11: B11 `handle_settings` rescue, F5 (D32), E6 regression test, E7 console-only WONTFIX, T27/T7 canaries recorded, full suites and rubocop green) |
| P4b | D6 `Coordinator::Confirmer`/`Reopener`, O4 policies (with D9 condition), O11 banner, O14 Overview; numbering (lowest-free, D27 amended); reopen deletes the group's pending requests (D31); T15, T18, T19, T34, T38; D30 UI (`UI_GAP_ANALYSIS.md` work list) | D6, D13, P4 | Coordinator confirm/reopen in place; banner and gates behave as in 1d and O11 | DONE (`1ae5cef`, `a7a1b0b`, `e53fa0f`, `c2d5ed5`, `d4d1d4b`) |
| P4c | D29: `JoinRequester` and its policy allow confirmed groups (flip the P2b policy line); accepting a request, invite or link into a confirmed group reopens it under the course lock, notifies every member, runs the shared cleanup; project freezes membership; `origin` guards in every student write service; request expiry (24 hours, D31; prefer deriving it from `created_at`); the "Group reopened because X joined." notification to every member (D29); T35, T36, T38 | P3a, P4, P4b | Confirmed groups take members per D29; imported groups stay closed; no stale request can add a student | WIP — backend DONE (PR B); the follow-ups from the owner's click-through are P4d to P4f, and P4c closes when P4f lands |
| P4d | D36 rename: the course columns and the derived predicate moved to formation terms; formation open/closed wording throughout code, comments, docs and the plan prose; section 4 rows; T45. Pure rename in its own PR, no behaviour change | P4c backend | No old names in app/, test/, db/schema.rb or docs (ADRs keep their history); suite green; `rename_column` scheduled around the Heroku deploy (course 3 is the only production course with formation on) | DONE (2026-11-12; migration `20261112090000`; deploy sequencing raised with the owner) |
| P4e | P4c backend follow-up (PR C): D33 link deletion (both Confirmers, `ProjectGroup#reopen!` for every reopen path, project creation); D34 (`Kicker`, `ProjectGroupMemberPolicy#destroy?`, reopen on kick, mail, T32 flipped); U4 backend (`InviteLinkDisabler`, route, policy); U5 requester expiry; `:group_full` on requests and at accept; the named policy changes (`edit?`/`update?`, `revert?`, `request_to_join?`); T39 to T43 | P4d | A leader can kick from a confirmed group; no stale link or request can add a student; the backend offers everything U1 to U4 need | DONE (2026-11-12; T41/T43 view halves in P4f) |
| P4f | P4c UI half (PR D): U1 request button and "Full", U2 leader Manage on a confirmed group, U3 Manage beside Reopen, U4 disable button, U6 bell layout for the coordinator view, E9 template rename (no new template content); T43, T44, T18 and T19 stay green | P4e | Section 1h surfaces exist and the owner's click-through passes | TODO |
| P5 | T10 and the spec edit (B5 dropped) | - | The spec describes the feasibility check (D2); the property test shows random confirm orders never strand students; no calculator change | TODO (unblocked) |
| P6 | I1 to I3 | P1 to P5 | One shared result class; messages in one locale file; behaviour unchanged | TODO |
| P7 | Section 4 renames (the D36 rows ship earlier in P4d), I4, I5, I9, O7, `Groups::` move | D1, D4, P6 | No old terms in app/, db/schema.rb, test/, docs/; suite green | TODO |
| P8 | T11, T12 | P1 | Core flows covered at system level | TODO |

## 7. Spec edits required

Update the spec doc for: D1 vocabulary (stale 1.x/3.0 text); D2 (the prevent-leftover rule is the feasibility check, not the strict quota; the confirmed-group cap stays as the code has it); D3 (No limit default); D6 (coordinators can confirm and reopen; the "no Confirm or Reopen" text is stale); D7 ("Remove a member"; self-leave from a confirmed group no longer reopens it); D13 (mode switches no longer delete not-confirmed groups); D18 (drop "Move a member"); D19 (drop "can only be turned on once"); D26/D28 (no promote-leader, no approval toggle); D27 (Tmp/G naming); D29 (reopen notification copy "Group reopened because X joined."); D33 (links deleted on confirm, reopen and project creation); D34 (a leader can kick from a confirmed group, which reopens it; "Remove a member" text); D36 (formation open/closed). Spec facts already matching the code: invite link expires after 24 hours; leader leaving promotes the earliest member and the last member leaving deletes the group (surfacing the proposal title first); duplicate pending invites/requests blocked by partial unique indexes (R7).

## 8. Not audited, and production data

Audit scope: static read of models, schema, routes, group services, group controllers, group and policy files named above, `GeneralMailer` group actions, `ProjectsController#new/#create`, `Project` validation, `CoursesController` CSV import, `User` associations, every `manage_groups?` call site, `submission_state_for` on Overview, the P1b commit (`6ae59ea9`), the request lifecycle, every use of `locked`. Not done: running the suite or app, most JS controllers, mailer views, courses/settings grouping UI, the Groups tab view templates (`groups#index`), `ProjectPolicy`/`CoursePolicy` beyond `manage_groups?`. Revision 12 re-read the code at `d4d1d4b` for status reconciliation only; no tests were run.

Not checked:

- Whether the older thread tests pass with `with_lock` removed (canary, 2d).
- R9 (controller rescue of `RecordNotFound` from `with_lock`). (E6 and E7 were checked by the P4 close-out; see their rows.)
- Canvas DB indexes and Discourse `GroupManager`.
- Whether any group route looks a group up by name.
- Whether the suite passes. P1b also changed `db/seeds.rb` and `_group_row`, `_groups_table`, `_size_warning_icon`, which the brief did not list; not reviewed.
- Before deploying P1b: read-only fingerprint check (groups with no sequence that are not fingerprint groups should be 0; was 353 fingerprint groups on 2026-11-02) and T23. Course 3's 4 groups are fingerprint groups, so they become `import`.
- Before deploying P2b: locked groups (and locked not-confirmed groups) and pending join requests on confirmed vs not-confirmed groups; the migration deletes all pending requests silently.
- Before deploying ADR 0027: course 3 is the only production course with grouping on. Its `grouping_open` was false and it had no dates, so it is closed before the drop and open after. The owner accepts this and may delete the course; do not add a data migration or `ignored_columns` to preserve the old state.
- Production runs Rails 8.1.4, the branch lockfile has 8.0.2: rebase onto main and run migrations there before merging to main.

Production, read-only (2026-11-02; course 3 on 2026-11-03):

- No group has two projects (D22 index safe); no duplicate `group_name` in a course (I11 index safe); no student in two groups of one course (B3 index safe).
- Import-fingerprint groups: 353 in 14 courses. 349 in 13 grouping-off courses (1, 133, 170, 232, 233, 234, 235, 298, 364, 399, 430, 463, 496; course 298 has 110), confirmed by the backfill. 4 in course 3 (grouping on), which already have a project, so the project rule confirms them (O15).
- Leaderless groups with members: 350 in 13 courses, all fingerprint groups, so the fingerprint rule is reliable and no app-created group is leaderless.
- Course 234: 3 fingerprint groups with no members (old importer leftovers); the backfill confirms them, harmless.
- Course 3 "Sandbox Group Approved Topic": the team's live testing course (about 6 people). Grouping on, `grouping_open` was false and there were no dates (closed before ADR 0027, open after); the owner accepts this and may delete the course. 4 groups with 1, 2, 3 and 3 members, all with a project.

## 9. Code conventions and quality

Applies to every PR. Rubocop and `docs/Abstraction/service_classes.md` still apply.

### Comments

1. Say why, not what. If a better name or smaller method removes the need, do that instead.
2. No comment that restates the next line or method name. Simple methods get none.
3. At most 1 to 3 lines. Longer reasoning goes in the PR description or an ADR in `docs/adr`.
4. No plan IDs (D17, B14, R3, T25), revision numbers, counts or "added for..." history in code or tests; they go stale. The PR description and commit message link the plan.
5. A comment is required for: why a check sits inside a lock, the DB constraint a rescue relies on, an intentional deviation from convention, a non-obvious parameter or return contract.
6. A class header is one to three lines: what it is, plus any non-obvious contract.

Examples (GitLab, copy the pattern, not every instance). Class header in one breath (`app/models/internal_id.rb`): `# An InternalId is a strictly monotone sequence of integers generated for a given scope and usage.` Inline comment for a line that looks pointless without it (`app/services/groups/destroy_service.rb`): `# reload the relation to prevent triggering destroy hooks on the projects again`. Simple delegators there have no comment. ProPro Importer header, trimmed from 5 lines with plan IDs to 3:

```ruby
# Places students from a grouped CSV into groups. New groups are created confirmed,
# led by the first member in CSV order. Students already in another group are
# reported, not moved.
```

The empty-group rule moved next to the line that does it.

### Code

- Controllers never write a group or its members directly; they call a lock-taking service (D20).
- Lock order course, group, enrolment. Checks without a DB constraint inside the lock. No external calls inside a lock. Mail enqueued after commit.
- No broad `rescue StandardError` showing `e.message` (B11); rescue the specific error.
- D1 vocabulary in code, copy and tests; new user-facing text never says draft, revert, locked or dissolved.
- No new abstractions beyond what an item asks for. One concern per PR. A rename never shares a PR with a behaviour change.

### Tests

Name tests by behaviour. Every fix has a regression test that fails before the fix. Race tests are non-transactional and the PR description records the canary result (T7).

### Migrations

One person writes migrations at a time (no `schema.rb` conflicts). Data migrations use raw SQL, not models, and are idempotent. If existing data would make an index fail, abort with a message naming the offending rows.

### Review checklist

- Does the diff match one plan item, with no extra scope?
- Does the regression test fail without the fix?
- Locks taken in order, checks inside them?
- Any comment restating the code, or any plan ID in code?
- Any D1 term violation in code, copy or tests?
- Any controller writing a group directly, or a broad rescue?