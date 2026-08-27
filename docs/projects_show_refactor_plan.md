# ProPro Redesign — projects/show Refactor & Redesign — Master Plan

Grounded against `hackerspacemmu/ProPro` @ `main` (`0d9e1e8`). All
identifiers and queries verified against actual controller/model/view code.
File:line references included for re-verification.

**Prerequisite:** assumes `courses/show` Tickets 1 & 2 (`shared/_header`,
`shared/_sidebar` rendered unconditionally from `layouts/application.html.erb`)
are merged. This doc wires `projects/show` into that layout.

---

## 1. Query / Path Audit

| Claimed correct form | Status | Evidence |
|---|---|---|
| `current_user.courses` | ✅ | `User` has `has_many :courses, through: :enrolments` (`user.rb:9`). |
| `user_profile_path` | ✅ | `get 'user/profile'` (`routes.rb:9`) auto-names to `user_profile_path`. |
| `settings_course_path(@course)` | ✅ | `get 'settings'` under member block (`routes.rb:37`). |
| `proposal.owner_name` | ✅ **already exists** | `Project#owner_name` (`project.rb:61-69`). The other agent's plan was wrong about this not existing — it does. The card partials just inline-duplicate it. `Topic` does NOT have `owner_name` yet — that's genuinely new work for a follow-up. |
| `proposal.current_status` | ✅ | `Project#current_status` (`project.rb:53-55`). |
| `proposal.current_instance&.updated_at` | ✅ | `Project#current_instance` (`project.rb:49-51`). `projects.updated_at` is stale (nothing `touch:`es the parent). |

**Net:** all six are available. `owner_name` already exists on `Project`
and just needs to be called from the card partials instead of inlined.
`Topic#owner_name` is new work but out of scope for this ticket.

---

## 2. What's already correct — do not rebuild

`ProjectsController#show` (`projects_controller.rb:5-48`) computes
everything the new design needs. **No controller changes required.**

Already correct and reusable as-is:
- Comments pane (`_project_comments.html.erb`) — groups by version,
  gates composer behind policy, uses locals only.
- Version diff engine — `HTMLDiff`-based comparison in
  `_project_details.html.erb:141-375`. Needs to be **moved**, not written.
- Version navigation — prev/next arrows in `_project_header.html.erb:307-348`.
- Status change endpoint — `change_status_course_project_path` +
  `ProjectPolicy#change_status?` already work.

---

## 3. Ticket List

### Ticket 1 — Shared tab-shell controller

**Files:**
- Reuse the existing generic `tabs_controller.js` from courses/show. It is
  already index-based with `data-tabs-target="tab"` / `"panel"` and
  `data-tabs-index-param`. No changes needed to it.
- **Do NOT delete `mobile_tabs_controller.js`** — `topics/show.html.erb:43`
  also uses `data-controller="mobile-tabs"`. It stays until topics/show
  is migrated. Only `projects/show` stops referencing it.

### Ticket 2 — Extract "Compare Versions" into its own tab

**Files:**
- New `app/views/projects/_compare_versions_tab.html.erb` — **move**
  (cut/paste) the `VERSION DIFF COMPARISON` block from
  `_project_details.html.erb:141-375`. Same locals: `fields`, `next_fields`,
  `index`, `instances`.
- Modify `app/views/projects/_project_details.html.erb` — delete the moved
  block. What's left is purely the field list + "Based on Topic" footer.
- No controller changes.

**Decision (open item 1):** When there's nothing to compare (single
version), show the tab with an empty state message: "Only one version
exists — nothing to compare yet." The tab is always visible; the empty
state prevents confusion about why the panel is blank.

### Ticket 3 — Restyle project header, convert status control to split-button

**Files:**
- Modify `app/views/projects/_project_header.html.erb` — visual restyle
  (Material palette, pill badges). Same locals.
- Replace the inline `<select>` + submit ("Coordinator Approval Form",
  `_project_header.html.erb:191-221`) with three explicit `button_to`
  actions hitting the **same** existing endpoint:
  ```erb
  <%= button_to "Approve",
      change_status_course_project_path(course, project, status: "approved"),
      method: :patch %>
  <%= button_to "Request Changes",
      change_status_course_project_path(course, project, status: "redo"),
      method: :patch %>
  <%= button_to "Reject Proposal",
      change_status_course_project_path(course, project, status: "rejected"),
      method: :patch %>
  ```
- New `app/javascript/controllers/dropdown_controller.js` — generic
  open/close menu on click, close on outside-click/Escape. Needed for
  the split-button caret dropdown. **Not** CSS `group-hover` (breaks on
  touch).
- Version selector: **build the `<select>` dropdown** per the mockup.
  New tiny `app/javascript/controllers/version_select_controller.js` —
  navigates to `course_project_path(course, project, version: N)` on
  change. Replaces the prev/next arrows.

### Ticket 4 — Restyle Comments pane

**Files:**
- Modify `app/views/projects/_project_comments.html.erb` — visual
  restyle only. No behavior or local changes.
- On mobile, Comments becomes a 4th tab in the shared tab shell
  (confirmed decision, open item 4).

### Ticket 5 — Restyle Progress Updates tab

**Files:**
- Modify `app/views/projects/_progress_updates.html.erb` — visual
  restyle only.
- No controller change (`@progress`/`@weeks` already only set when
  `@course.use_progress_updates`, `projects_controller.rb:44-47`).

### Ticket 6 — Wire the new shell into `show.html.erb`

**Files:**
- Modify `app/views/projects/show.html.erb`:
  - Replace `data-controller="mobile-tabs"` + two-column layout with
    single-column layout using `data-controller="tabs"`.
  - Tab "Project Details" → `render "project_header"` +
    `render "project_details"` + `render "project_actions"`
  - Tab "Compare Versions" → `render "compare_versions_tab"` (Ticket 2)
  - Tab "Progress Updates" → `render "progress_updates"` (conditional on
    `@course.use_progress_updates`)
  - Tab "Comments" → `render "project_comments"` (always present,
    becomes a 4th tab on all viewports)
  - Drop `content_for :hide_toggler, true` once the header/sidebar
    ticket's final shape makes it dead code.
- `_project_actions.html.erb` stays unchanged — just fit into the new
  shell's density.

**No Settings link** — confirmed: the projects mockup has no Settings
tab/link. Projects don't have a separate settings page like courses do.

### Ticket 7 — `Project#owner_name` cleanup (cross-cutting, independent)

**Files:**
- `Project#owner_name` already exists (`project.rb:61-69`). No model
  change needed.
- Update `app/views/courses/_project_card_contents.html.erb:18-24` to
  call `project.owner_name` instead of inlining the ternary.
- Update `app/views/courses/_topic_card_contents.html.erb:52-58` to
  call `topic.owner_name` — but `Topic` doesn't have this method yet.
  Either add `Topic#owner_name` (same implementation) or leave the
  inline logic for now. Recommend adding the method for consistency,
  flagged as a small follow-up.
- Not used by `projects/show` itself — this is cleanup while we're
  touching the codebase.

### Ticket 8 — Delete dead partials

**Files:**
- Delete `app/views/projects/_project_fields.html.erb` — confirmed only
  referenced at `show.html.erb:160`. Desktop-only Turbo tab wrapper,
  replaced by unified Stimulus tabs.
- Delete `app/views/projects/_comments_panel.html.erb` — dead code.
  Legacy Google-Material panel, never rendered from show.html.erb.
  References non-existent methods (`project.current_version_number`,
  `comment.body`, `comment.author`).
- **Do NOT delete `mobile_tabs_controller.js`** — still used by
  `topics/show.html.erb:43`.

---

## 4. File Operations Summary

### New files (5)
1. `app/views/projects/_compare_versions_tab.html.erb`
2. `app/javascript/controllers/dropdown_controller.js`
3. `app/javascript/controllers/version_select_controller.js`
4. (reuse existing `app/javascript/controllers/tabs_controller.js` — no new file)

### Modified files (4)
5. `app/views/projects/show.html.erb` — rewrite (unified tab shell)
6. `app/views/projects/_project_header.html.erb` — restyle, split-button
7. `app/views/projects/_project_comments.html.erb` — restyle
8. `app/views/projects/_progress_updates.html.erb` — restyle
9. `app/views/projects/_project_details.html.erb` — remove version diff
   block (moved to _compare_versions_tab)

### Deleted files (2)
10. `app/views/projects/_project_fields.html.erb`
11. `app/views/projects/_comments_panel.html.erb`

### Untouched files
- `app/views/projects/_project_actions.html.erb` — no changes
- `app/views/projects/_comment.html.erb` — no changes
- `app/controllers/projects_controller.rb` — no changes
- `app/javascript/controllers/tabs_controller.js` — no changes
- `app/javascript/controllers/scroll_to_bottom_controller.js` — no changes
- `app/javascript/controllers/field_expand_modal_controller.js` — no changes
- `app/javascript/controllers/textarea_resize_controller.js` — no changes
- `app/javascript/controllers/mobile_tabs_controller.js` — NOT deleted
  (still used by topics/show)
- `app/views/projects/edit.html.erb` — no changes
- `app/views/projects/new.html.erb` — no changes

---

## 5. Target Architecture

```
┌──────────────────────────────────────────────────────────┐
│ Tab bar (Stimulus tabs#show)                             │
│ [Project Details] [Compare Versions] [Progress*] [Comments] │
├──────────────────────────────────────────────────────────┤
│ Panel 0: Project Details                                 │
│  ┌──────────────────────────────────────────────────────┐│
│  │ _project_header (title, props, status split-button,  ││
│  │                  version select dropdown)             ││
│  │ _project_details (fields, expand modal, topic footer)││
│  │ _project_actions (edit, jump-to-latest)              ││
│  └──────────────────────────────────────────────────────┘│
├──────────────────────────────────────────────────────────┤
│ Panel 1: Compare Versions                                │
│  ┌──────────────────────────────────────────────────────┐│
│  │ _compare_versions_tab (HTMLDiff table, or empty      ││
│  │                        state if single version)      ││
│  └──────────────────────────────────────────────────────┘│
├──────────────────────────────────────────────────────────┤
│ Panel 2: Progress Updates* (conditional)                 │
│  ┌──────────────────────────────────────────────────────┐│
│  │ _progress_updates (list with rating badges, edit/del)││
│  └──────────────────────────────────────────────────────┘│
├──────────────────────────────────────────────────────────┤
│ Panel 3: Comments                                        │
│  ┌──────────────────────────────────────────────────────┐│
│  │ _project_comments (grouped list + composer)          ││
│  └──────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────┘

* Progress Updates tab shown only if @course.use_progress_updates
```

**Key decisions applied:**
- Four tabs, not three — Compare Versions gets its own tab.
- Comments are a tab on all viewports (mobile + desktop), not a sidebar.
- No Settings link — projects don't have a settings page.
- Split-button for status change (Approve / Request Changes / Reject).
- Version `<select>` dropdown replaces prev/next arrows.
- Single-column layout eliminates all mobile/desktop split rendering.

---

## 6. Build Order

```
1 → 2 → 7 (parallel, independent) → 3 → 4 → 5 → 6 → 8
```

Tickets 2, 4, 5 don't depend on each other and can be split across
contributors once Ticket 1's shared tab controller is confirmed available.
Ticket 7 is fully independent and can merge whenever. Ticket 8 (deletions)
is last — confirms nothing references the files before removing them.

**Within each ticket:** build the partial/controller first, then wire it
into the parent view, then visual QA, then tests.

---

## 7. Tests

### New: `test/system/projects/project_show_test.rb`

Minimum coverage:
- **Tab visibility:** All four tabs render. Progress tab hidden when
  `use_progress_updates` is false. Compare Versions shows empty state
  for single-version project.
- **Tab switching:** Clicking each tab shows the correct panel.
- **Compare Versions:** Viewing older version shows diff table.
  Viewing latest shows empty state.
- **Version select:** Dropdown navigates to correct version.
- **Split-button status:** Supervisor sees Approve/Request Changes/Reject.
  Non-supervisor sees static badge.
- **Actions:** Edit Proposal visible to owner on latest version.
  "Jump To Latest Version" shown when viewing older version.
- **Comments:** Grouped by version; form visible when policy allows;
  soft delete works.
- **Progress updates:** Record link visible to supervisor on approved
  project; edit/delete buttons work.

### Updated: `test/system/projects/project_versioning_test.rb`

Existing tests should continue to pass — they test version navigation
which is preserved (arrows replaced by dropdown, but the route/param
structure is identical). Verify after refactor.

---

## 8. Open Items (resolved)

1. **Compare Versions empty state** → Show tab with empty state message.
2. **Split-button interaction** → `dropdown_controller.js` (click toggle,
   not CSS hover).
3. **Version control** → `<select>` dropdown per mockup, with
   `version_select_controller.js`.
4. **Comments on mobile** → 4th tab in the shared tab shell.
5. **`owner_name` precedence** → Already defined on `Project` at
   `project.rb:61-69` as `:name`-first-then-`:group_name`. The card
   partials just need to call the model method instead of inlining it.
   No behavior change.
6. **Settings link** → Not in the mockup. Projects don't have a settings
   page. No link added.
7. **Bottom "Back to Course"** → Removed (top link sufficient on tabbed
   page). Confirmed by user.
8. **`_project_fields.html.erb` deletion** → Confirmed only referenced
   at `show.html.erb:160`. Safe to delete.
9. **`mobile_tabs_controller.js`** → **NOT deleted** — still used by
   `topics/show.html.erb:43`. Both original plans were wrong about this.
