# topics/show Redesign — Audit & Workflow (Design-Only Pass)

Grounded against `hackerspacemmu/ProPro` @ `main` (`244ef6d`). All identifiers
and line numbers below were verified against the actual repo. File:line
references included for re-verification.

**Approach (per Alex, revised from the first draft of this doc):** don't
redesign topics/ from a style guide — **copy the exact partials already
built for `projects/` on `refactor/design`, then swap out the
guards/gates/policies/logic for topics' own.** The only structural
subtraction is the **Progress Updates** tab, which doesn't apply — `Topic`
has no `progress_updates` association (unlike `Project`, `project.rb:10`).
Everything else in the new projects/ shell (two-pane layout, sticky tabs,
Compare Versions tab, split-button status control, version `<select>`,
comments panel, mobile drawer + pinned action bar) gets copied, then
re-wired to topics' data and gates.

**Reference sources:**
- **Behavior/gates/policies source of truth:** `main` branch —
  `app/views/topics/*`, `app/controllers/topics_controller.rb`,
  `app/policies/topic_policy.rb`, `app/models/topic.rb`.
- **Structure/styling source to copy from:** `refactor/design` branch's
  `app/views/projects/*` (local working tree — not pushed to origin, which
  is fine; the agent just needs to run in that same local checkout).

**Scope for this pass:** views + partials + JS controllers only. No changes
to `app/controllers/topics_controller.rb`, `app/models/topic.rb`,
`app/policies/topic_policy.rb`, or any migration.

---

## 1. Why this copy-then-swap approach works cleanly

`Topic` and `Project` are two Ruby classes backed by the **same database
table** (`self.table_name = 'projects'` on `Topic`, `topic.rb:2`, split from
`Project` by `ownership_type` default scope). Same shape, same instance
concepts (versions, statuses, comments) — which is exactly why a literal
partial copy is a sound move here, not just a shortcut.

One real friction point to know about before copying: `Project` has
`owner_name` and `editable?` (`project.rb:61-69`, per the earlier projects
audit); **`Topic` has neither**, and this pass isn't adding them (no model
changes). So when copying `_project_overview.html.erb` → `_topic_overview.html.erb`,
don't call `topic.owner_name` — reuse the inline owner-rendering branch that
already exists in the current `_topic_header.html.erb:107-145` (`owner.is_a?(User)`
vs. iterating `topic.owner.users`), since that's the topic-side logic that
currently does what `owner_name` does for projects. This is the concrete
example of "swap the logic, keep the markup."

---

## 2. File inventory — what exists today

`app/views/topics/`:

| File | Lines | In scope for `show`? |
|---|---|---|
| `show.html.erb` | 282 | Yes — gets rebuilt on the copied shell |
| `_topic_header.html.erb` | 366 | Yes — splits into context header + overview, same as projects' Ticket 3 |
| `_topic_fields.html.erb` | 335 | Yes — field list + inline HTMLDiff (lines 182-290) that moves into a Compare Versions tab |
| `_topic_actions.html.erb` | 112 | Yes |
| `_topic_comments.html.erb` | 216 | Yes |
| `_source_topic_diff.html.erb` | 111 | Yes, rendered from `show.html.erb:158` — **topic-only, no projects/ equivalent, needs a placement decision (§5)** |
| `_copy_topic_details.html.erb` | 130 | **No** — only rendered from `TopicsController#new` (`topics_controller.rb:77`), not `show` |
| `_copy_topic_overlay.html.erb` | 85 | **No** — only rendered from `new.html.erb:67` |
| `_topbar.html.erb` | 17 | Check first — need to confirm it isn't also used by `index`/`new` before restyling |

Correction from the first draft of this doc: `_copy_topic_details` and
`_copy_topic_overlay` are **not** part of `show` at all — they belong to the
topic-cloning flow on the `new` page. Drop them from this pass entirely;
don't let them get pulled into the show.html.erb rework.

---

## 3. File-to-file copy map

| Copy from (`projects/`, on `refactor/design`) | Copy to (`topics/`) | Swap in |
|---|---|---|
| `_context_header.html.erb` | `_context_header.html.erb` | Topic status enum/colors (same values as Project's, see §4), version data from `@instances`/`@current_version` |
| `_project_overview.html.erb` | `_topic_overview.html.erb` | Topic's fields: Type (static "Topic"), Owner (inline `owner.is_a?(User)` branch — see §1), Group Name (`topic.owner.is_a?(ProjectGroup)`). **No Supervisor row** — `Topic#supervisor` exists (`topic.rb:31-33`) but nothing in the current UI surfaces it; confirm with Alex whether to add one or omit, don't assume |
| `_compare_versions_tab.html.erb` | `_compare_versions_tab.html.erb` | Move the HTMLDiff block out of `_topic_fields.html.erb:182-290`, same locals (`fields`, `next_fields`, `index`, `instances`) |
| `_review_actions.html.erb` + `_review_action_bar.html.erb` | same names | Topic's single-condition status gate (§4) instead of projects' supervisor+latest gate; `_topic_actions.html.erb`'s existing action set (Edit/Delete/Jump-to-latest/Propose) folds in here |
| `_project_comments.html.erb` | `_topic_comments.html.erb` | Keep the `!@is_student` restriction (§4) — **projects/ has no equivalent of this**, so it's an addition to the copied chrome, not a swap |
| `dropdown_controller.js`, `version_select_controller.js`, `tabs_controller.js`, `comments_drawer_controller.js` | same, no copy needed | These are already resource-agnostic — reference directly, don't duplicate |
| *(no equivalent)* | `_source_topic_diff.html.erb` stays, needs a home in the new tab structure | Topic-only — suggest placing it inside the Details tab, below the overview card, matching where it sits today (`show.html.erb:154-163`), unless Alex wants a dedicated tab for it |
| *(dropped — doesn't apply)* | — | `_progress_updates.html.erb`, `_record_update_modal.html.erb`, `record_update_modal_controller.js` — not copied |

Resulting tab bar: **Topic Details | Compare Versions** — two tabs, not
three, comments persistent in the right pane exactly as projects has it.

---

## 4. Full gate/policy inventory, by file, with use case

Every conditional and policy call currently in the `show` render path.
Preserve every one of these exactly — restyle the markup around them, don't
change what they evaluate.

**`show.html.erb`:**
- `has_actions = @members.include?(current_user) || @current_version != @latest_version || policy(Project.new(course: @course)).create? || (@project.present? && policy(@project).update?)` (lines 14-17) — decides whether the Actions section renders at all. Note this checks a **`Project`** policy, not `TopicPolicy` — it's asking "could this viewer act on *their own project* in this course," a separate lookup (`@project`, set in `topics_controller.rb:32-37`) from the topic being viewed. Used twice (line 74 mobile, line 178 desktop) — same condition, don't let the two copies drift when merged into the new shell.
- `(@is_coordinator || @topic.owner == current_user) && @topic.source_topic.present?` (line 154) — gates whether `_source_topic_diff` renders at all.
- `source_instance.present?` (line 156) — nested under the above; the source topic must have at least one instance to diff against.
- `!@is_student` (line 215) — gates `_topic_comments` vs. the "Comments Restricted" empty state.

**`_topic_header.html.erb`** (splits into `_context_header` + `_topic_overview`):
- `topic.source_topic.present? && (coordinator || topic.owner == current_user)` (line 53) — shows the "Copied from X" badge under the title.
- `topic.source_topic.course != @course` (line 61) — nested under the above; adds "in <course name>" when the source topic is from a different course.
- `owner.is_a?(User)` / else (line 108) — display branch for solo owner vs. group owner (this is the logic to reuse for `_topic_overview`, see §1).
- `topic.owner.is_a?(ProjectGroup)` (line 148) — shows the "Group Name" row.
- `@is_coordinator && @course.require_coordinator_approval && current_version == latest_version` (line 189) — **the flagged gate**: shows the interactive status control vs. a static badge. This is hand-rolled, not calling `TopicPolicy#change_status?`, and the controller's `change_status` action calls no `authorize` at all (`topics_controller.rb:188-207`, compare `projects_controller.rb:51`). Preserve this exact condition; do not fix the missing `authorize` call this pass — flag it as its own follow-up ticket.
- `current_version != latest_version` (line 301) — "(older)" label on the version card.
- `current_version > 1` (line 308) / `current_version < instances.size` (line 330) — back/next arrow enabled state. **These go away** once the version `<select>` replaces the arrows (see §6 on tests) — a dropdown doesn't have a "disabled direction," it just lists all versions.

**`_topic_actions.html.erb`** (folds into `_review_actions.html.erb`):
- `is_member = members.include?(current_user)` (line 1)
- `is_history = current_version != latest_version` (line 2)
- `has_actions = is_member || is_history` (line 3) — **computed but never referenced again in this file.** This is a second, narrower `has_actions` that's dead code inside the partial — the one that actually controls rendering is `show.html.erb`'s broader version (§ above). Don't carry this redundant local into the new partial; note it as a small cleanup while you're in there (still no logic change — it's simply unused).
- `is_member` (line 9) — wraps the whole Edit/Delete block (lecturer/owner-only actions).
- `(topic.status != "approved" && !is_history) || (!course.require_coordinator_approval)` (line 11) — Edit button active vs. "Unable to Edit Topic" locked state.
- `!is_history` (line 13) — shows the "Latest Version" pulse label above Edit.
- `!is_history` (line 45) — Delete Topic button only shown on the latest version.
- `is_history` (line 62) — shows "Jump To Latest Version".
- `policy(Project.new(course: @course)).create?` (line 78) — shows "Propose Based on This Topic" (create-a-new-project-from-this-topic).
- `@project.present? && policy(@project).update?` (line 96) — shows "Update Proposal Based on This Topic" (update the viewer's existing project to reference this topic).

**`_topic_comments.html.erb`** (restyles onto `_project_comments.html.erb`'s chrome):
- `!@is_student` (line 1) — **a second, redundant copy** of the same check `show.html.erb:215` already does before rendering this partial at all. Not a bug exactly (belt-and-suspenders), but if the partial is ever rendered from anywhere else this guard is the only thing protecting it — keep it when copying, don't assume the caller-side check makes it safe to drop.
- `comments&.any?` (line 18) — shows the comment-count badge in the header.
- `comments&.any?` (line 39) — gates the grouped comment list vs. empty state.
- `Current.user == comment.user` (line 75) — shows edit controls on your own comment.
- `comment.created_at > 3.days.ago` (line 82) — time-limited edit window.
- `Current.user == comment.user && !comment.deleted` (line 92) — shows delete control.
- `!comment.deleted` (line 108) — hides content of a deleted comment / shows placeholder.
- `(current_version == latest_version) && (@current_user.id == @topic.owner_id || @is_coordinator)` (line 144) — gates the comment composer: only on the latest version, and only for the topic's owner or a coordinator. Note this is **narrower than** projects' comment-posting gate (worth a side-by-side check once you have the projects partial open — don't assume they're the same rule).
- `data-scroll-to-bottom-enabled-value="<%= current_version == latest_version %>"` (line 31) — not a Ruby conditional but a real behavioral gate: auto-scroll-to-bottom only activates when viewing the latest version.

**`_source_topic_diff.html.erb`** (topic-only, no projects/ source to copy from):
- `has_changes` (line 19) — gates the diff view vs. a "no changes" state.
- `old_val != new_val` (line 37) — per-field highlight in the diff.

---

## 5. Open decision — placement of `_source_topic_diff`

Everything else in this doc has a clear home because it's either a direct
copy-and-swap or a drop (Progress Updates). This one doesn't, because
projects/ has nothing like it. Current behavior renders it inline, right
after the field list, gated as in §4. Simplest option: keep it in the same
relative spot — bottom of the Details tab, below `_topic_overview` and the
field list. A dedicated third tab is the alternative but adds a tab that
only sometimes has content (only when `source_topic.present?`), which reads
oddly next to the always-present Details/Compare pair. Flagging for Alex's
call, not deciding it here.

---

## 6. System tests — modify, don't defer

Both existing system test files hard-depend on UI elements the redesign
removes. Unlike the projects/show plan (which deferred equivalent breakage
to a follow-up), **these need to be updated in this pass** since the
underlying interaction model is changing, not just styling.

**`test/system/topics/topic_versioning_test.rb`** (5 tests, uses
`data-testid="current-version"`, `"version-back"`, `"version-next"` —
all of which come from the arrow-based version card at
`_topic_header.html.erb:306-341`, which is being replaced by the `<select>`
+ `version_select_controller.js` from the copied `_context_header.html.erb`):

- `'defaults to latest version on page load'` — swap the `current-version`
  assertion for whatever the copied version `<select>` exposes (check the
  actual testid/markup on the copied `_context_header.html.erb` — likely the
  selected `<option>`'s text, per the projects plan's "1 of 3 (Current)"
  label format). Keep the same assertion intent: latest version shown by
  default.
- `'clicking back navigates to previous version'` / `'...next version'` —
  rewrite as Capybara `select` calls against the new dropdown instead of
  `find(...).click` on an arrow, then assert the same resulting version.
- `'back button is disabled on version 1'` / `'next button is disabled on
  latest version'` — **these two don't have a direct equivalent.** A
  dropdown doesn't have a disabled direction — it just lists every version
  and highlights the current one. Options: drop these two tests as
  no-longer-meaningful, or rewrite them to assert the dropdown's option list
  is bounded correctly (e.g., "on version 1, the dropdown shows versions 1
  and 2, with 1 selected"). Flagging this as a call for whoever implements
  it — don't silently delete without deciding which.

**`test/system/topics/change_status_test.rb`** (3 tests, uses
`data-testid="status-select"` and `"change-status-submit"` — from the
`<select>`-based status form at `_topic_header.html.erb:191-221`, which
the copy brings in as the split-button component from `_context_header.html.erb`
— Approve primary button, dropdown for Request Changes/Reject):

- `'coordinator can change topic status...happy path'` — the
  `select 'Approved', from: 'status'` + click `change-status-submit` flow
  needs to become a click on the copied split-button (or its dropdown, for
  the redo/reject options), asserting against whatever testids the copied
  `_context_header.html.erb` actually uses. Since topics' status values
  (`pending/approved/redo/rejected/not_submitted`) match projects' exactly,
  the split-button's three actions (Approve/Request Changes/Reject) map
  cleanly — no logic change needed, just new interaction + selectors.
- Both sad-path tests (`'lecturer cannot change...'`,
  `'...approval not required...'`) — update the `assert_no_selector` calls
  to whatever testid replaces `status-select`/`change-status-submit`, same
  assertion intent (control absent when the gate in §4 is false).

---

## 7. Prompt for the implementation agent

> You are refactoring `app/views/topics/` in the ProPro Rails app to match
> the already-built `app/views/projects/` redesign on this same
> `refactor/design` branch. **Copy the actual partial files** listed in the
> file-to-file map in `TOPICS_SHOW_REDESIGN_AUDIT.md` §3 — don't redesign
> from scratch, don't approximate. After copying, swap in topics' own data
> and the gates listed in §4, one for one — every gate in that list must
> still evaluate to the same thing it does on `main` today. Drop everything
> Progress-Updates-related; `Topic` has no such feature. `_source_topic_diff.html.erb`
> has no projects/ source to copy from — it's topic-only, keep it, place it
> per §5.

>
> You are not the policy/controller agent: do not modify
> `app/controllers/topics_controller.rb`, `app/models/topic.rb`,
> `app/policies/topic_policy.rb`, or any migration. Where a copied partial
> would need a `Topic` model method that doesn't exist (e.g. `owner_name`),
> don't add it — inline the equivalent logic instead, per §1's example.
>
> Update `test/system/topics/topic_versioning_test.rb` and
> `test/system/topics/change_status_test.rb` per §6 — these need real
> changes, not a follow-up ticket, since the interaction model (arrows →
> dropdown, `<select>` → split-button) is changing under them. Flag rather
> than silently resolve the two "disabled arrow" tests that have no clean
> dropdown equivalent.
>
> Before writing code: confirm you've accounted for every line item in §4
> and every row in §3's copy map, and get sign-off before touching files.

---

## 8. Still true from before

- Push status of `refactor/design` doesn't block this — the agent just
  needs the same local checkout.
- Hold off on promoting anything to `app/views/shared/` until after this
  ships and clears its own regression check against `main`. This pass
  produces topics-owned copies of the projects partials, not shared files —
  the `shared/` consolidation is a deliberate follow-up, not a side effect
  of this one.