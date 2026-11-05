# D28 cleanup: remove the approval toggle, close join requests, drop `locked`

Branch: `feat/student-grouping-crud`, from `acaae256` (P1b merged). Plan: `docs/Grouping/MASTER_IMPLEMENTATION_PLAN.md`, rev 8, D28. Code conventions: plan section 9.

D28 in one line: not confirmed groups take direct joins, so the "Require approval to join" switch and the `locked` column are gone. This is a behaviour change, not a rename.

Join requests are **closed for every group** in this phase and reopen later, for confirmed groups only. Stale requests are a real risk (a request that outlives a window close, a group reopening, or a student being added elsewhere), so nothing may create one until the later phase brings the cleanup rules with it.

Two PRs, in this order:

- **Part 1:** remove everything that reads or writes `locked`, close join requests, delete existing pending requests. The column stays, unused.
- **Part 2:** drop the column. Starts only after Part 1 is merged.

## Rules for this phase

- Never run `git add` or `git commit`. The user stages and commits.
- Minimal, targeted edits. No new abstractions. Deleting is the job; do not "improve" neighbouring code.
- No plan IDs or revision numbers in code or tests (section 9).
- Do not touch the plan doc. Report which items you finished and the user updates it.
- Policies: the only policy change allowed is the one in task 5.
- Do not rename anything. The `direct_` names (`GroupDirectRequester`, `GroupDirectInviter`, the `direct_request` and `direct_invite` kinds) stay as they are until the rename phase; a rename never ships in the same PR as a behaviour change. The new reason symbol deliberately avoids the word.

## Decisions already made for this brief

- **Join requests are closed for every group.** A not confirmed group takes direct joins, so a request there is refused. A confirmed group cannot accept a request yet, so the policy refuses it for now. The service already holds the final rule (requests only for confirmed groups); the policy line is the single switch the later phase flips.
- **The request plumbing stays.** The `join_requests` route, `GroupJoinRequestsController`, `GroupDirectRequester`, `GroupInviteResponder`, the leader's incoming-requests list and the "Request sent" branch in the table are reused when requests reopen. Do not delete them.
- **Every existing pending request is deleted** by a data migration. Each one is stale by the time requests reopen, and a student with a pending request on a not confirmed group would otherwise see "Request sent" where the Join button should be.
- **`ProjectGroupPolicy#update?` stays.** It is now only used by `edit?`; cleaning it up belongs with the `manage_groups?` removal.
- **No `ignored_columns` step** before the column drop. The earlier column removals in this repo did not use one.

## Out of scope (do not start)

The rules that keep requests from going stale belong to the phase that reopens requests: clearing a student's requests when they land in any group (coordinator add included), clearing a group's requests on reopen and on project creation, clearing a student's requests when they leave the course, request expiry, and the accept-time enrolment and ungrouped re-check. Also out of scope: Tmp naming, the Coordinator Confirmer/Reopener, the rebase.

## Part 1

### 1. Delete the services and their tests

- `app/services/groups/approval_toggler.rb`
- `app/services/groups/coordinator/approval_toggler.rb`
- `test/services/groups/approval_toggler_test.rb`
- `test/services/groups/coordinator/approval_toggler_test.rb`
- In `test/services/groups/group_write_lock_test.rb`, the two `ApprovalToggler` lines in `group-write services lock the group row`.

### 2. Remove the update action

- `GroupsController`: delete `update` and `update_approval`. Check the `before_action ... only:` lists for `:update`. Keep `coordinator?` (the delete path uses it).
- `config/routes.rb`: remove `update` from `resources :groups`.
- `test/routing/group_routes_test.rb`: remove the `PATCH` assertion in `groups expose the write routes`.
- `test/integration/group_write_routes_test.rb`: the two tests that patch `locked` (`the leader can edit and lock the group`, `another student cannot edit or lock the group`). Keep the edit-page assertions, drop the patch-and-lock parts, rename them so they no longer mention locking, and assert that `PATCH` on the group path now returns 404 (the route is gone; confirm what the test environment returns and assert that).

### 3. Views

- `app/views/groups/edit.html.erb`: remove the whole "Settings: approval switch" section (the `policy(@group).update?` block with the auto-submit form). Leave the Stimulus `auto-submit` controller in place even if nothing else uses it; deleting it is a separate cleanup.
- `app/views/group_formations/_groups_table.html.erb`: delete the `label` ternary (the label is always "Join") and the `elsif group.locked?` request button. Leave the confirmed, full and "Request sent" branches alone.
- Run `grep -rn -i "require approval\|approval to join\|Request to join" app` and remove any remaining copy that describes the toggle. (The course settings text about lecturer topics needing approval is unrelated; leave it.)

### 4. Services

- `GroupJoiner`: delete `return blocked(:group_locked) if @group.locked?`, the `:group_locked` message, and fix the header comment (it mentions locked groups).
- `GroupInviteLinkGenerator`: fix the header comment ("can join if locked").
- `GroupDirectRequester`: delete both `return blocked(:group_confirmed) if @group.confirmed?` and `return blocked(:group_unlocked) unless @group.locked?`, and put one line in their place:

  ```ruby
  return blocked(:group_not_confirmed) unless @group.confirmed?
  ```

  Messages: remove `:group_confirmed` and `:group_unlocked`; add `:group_not_confirmed` with "Requests are for confirmed groups. Join this group instead." Update the header comment to "Student requests to join a confirmed group." The rest of the method is unchanged.

### 5. Policy: close requests

`ProjectGroupPolicy#request_to_join?` returns `false`, with a one-line comment that requests stay closed until confirmed groups can accept them. This is an explicit exception to the no-policy-change rule; say so in the PR description. `GroupJoinRequestsController#create` is unchanged: it authorizes, so every request now redirects as unauthorized.

### 6. Data migration: delete pending requests

New migration (generate it so the timestamp is current), raw SQL, idempotent, irreversible like the backfill:

```ruby
class DeletePendingJoinRequests < ActiveRecord::Migration[8.0]
  def up
    deleted = execute('DELETE FROM project_group_invites WHERE kind = 0 AND status = 0')
    puts "Deleted #{deleted.cmdtuples} pending join requests."
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

`kind = 0` is `direct_request` and `status = 0` is `pending`. Direct invites and requests that were already accepted or declined are untouched. The first line of the file explains why: no request can be sent until requests reopen, so any pending one is stale.

Verify on a scratch database, not committed: seed a pending request, an accepted request, a declined request and a pending direct invite; run the migration twice; report the output. Only the pending request goes, and the second run deletes nothing.

### 7. Tests that mention `locked` or the old request rule

- `test/services/group_joiner_test.rb`: delete `blocked when group locked`.
- `test/services/group_direct_requester_test.rb`: change the setup to a **confirmed** group with a leader (drop `locked: true`, add `confirmed: true`). Rename the first test to say "confirmed". Replace `blocked when group already confirmed` with `blocked when the group is not confirmed` (reason `:group_not_confirmed`). Delete `blocked when group is unlocked`. Rename `blocked when locked group has no leader`. The duplicate and concurrent-request tests keep working on the confirmed setup.
- `test/services/group_invite_responder_test.rb`: drop `locked: true` from setup. Its accept tests need an unconfirmed group; keep them as they are, since the responder is unchanged.
- `test/services/group_direct_inviter_test.rb` and `test/services/group_invite_link_redeemer_test.rb`: delete the tests that exist only to show invites and links ignore the lock (`inviting works on a locked group`, the redeemer one).
- `test/policies/project_group_policy_test.rb`: `request_to_join?` is false for a student, a leader and a coordinator.
- `test/integration/group_write_routes_test.rb`: `a student can request to join a locked group` becomes `nobody can post a join request while requests are closed`: the POST redirects as unauthorized and creates no `ProjectGroupInvite`. `an outsider cannot request to join a group` stays as it is.
- `test/factories/project_groups.rb`: remove `locked { false }`.

### 8. New tests

Two small rack_test assertions (DOM/text only, per `docs/testing.md`):

- the Manage page (`edit`) for a leader has no "Require approval to join" text;
- the groups table shows "Join" on a not confirmed group and never "Request to join".

### 9. Docs

- `docs/Grouping/FRONTEND.md` and `docs/Grouping/OPEN_ITEMS.md`: edit the lines that describe the approval switch or the lock/unlock PATCH as current behaviour. Leave the ADRs, `GROUPING_ROUTES_REFACTOR.md` and the plan alone.

### Part 1 is done when

- [ ] `grep -rn "locked" app test db/seeds.rb` finds only unrelated words (the lock-test queue variable, the "project is locked" message in `ProjectsController`). Nothing references `ProjectGroup#locked`.
- [ ] No `ApprovalToggler` anywhere in `app/` or `test/`.
- [ ] A student can still join a not confirmed group directly; the Manage page and the table render without the switch.
- [ ] A join request cannot be created for any group: not through the route (policy), not through the service on a not confirmed group.
- [ ] The migration deletes only pending requests and is a no-op on the second run; the output is in the report.
- [ ] Rubocop clean; grouping tests pass; no comment contains a plan ID.

## Read-only production check (for the user, before deploying)

```sql
SELECT
  count(*) FILTER (WHERE locked) AS locked_groups,
  count(*) FILTER (WHERE locked AND NOT confirmed) AS locked_and_not_confirmed
FROM project_groups;

SELECT
  count(*) FILTER (WHERE g.confirmed) AS pending_on_confirmed,
  count(*) FILTER (WHERE NOT g.confirmed) AS pending_on_not_confirmed
FROM project_group_invites i
JOIN project_groups g ON g.id = i.project_group_id
WHERE i.kind = 0 AND i.status = 0;
```

`locked_and_not_confirmed` is how many groups switch from request-to-join to direct join on deploy. The second query is how many pending requests the migration will delete; the not-confirmed ones are students who would otherwise be stuck on "Request sent". Deleted requests are silent: nobody is emailed. If either number is large, tell the leaders first.

## Part 2: drop the column (separate PR, after Part 1 is merged)

- New migration (generate it so the timestamp is current):

```ruby
class RemoveLockedFromProjectGroups < ActiveRecord::Migration[8.0]
  def change
    remove_column :project_groups, :locked, :boolean, default: false, null: false
  end
end
```

- `db/schema.rb` changes only by the column and the version. No model, view, service or test edits; if you find you need one, Part 1 missed something, so stop and report it.
- Done when: the migration runs forward and back on a scratch database, the grouping suite passes, and `grep -rn "locked" app test db/seeds.rb` is still clean.

## Report back with

- Anything you changed that this brief did not list, and why.
- The result of the `PATCH` assertion (what the test environment returns).
- The migration dry-run output (both runs).
- Any place outside the files named above that still referenced `locked`.