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
| `proposal.owner_name` | ✅ **already exists** | `Project#owner_name` (`project.rb:61-69`). The card partials just inline-duplicate it. `Topic` does NOT have `owner_name` yet — follow-up. |
| `proposal.current_status` | ✅ | `Project#current_status` (`project.rb:53-55`). |
| `proposal.current_instance&.updated_at` | ✅ | `Project#current_instance` (`project.rb:49-51`). `projects.updated_at` is stale. |

---

## 2. What's already correct — do not rebuild

`ProjectsController#show` (`projects_controller.rb:5-48`) computes
everything the new design needs. **No controller changes required.**

Already correct and reusable:
- Comments pane (`_project_comments.html.erb`) — groups by version,
  gates composer behind policy, uses locals only.
- Version diff engine — `HTMLDiff`-based comparison in
  `_project_details.html.erb:141-375`. Needs to be **moved**, not written.
- Version navigation — prev/next arrows in `_project_header.html.erb:307-348`.
  Will be replaced by `<select>` dropdown per mockup.
- Status change endpoint — `change_status_course_project_path` +
  `ProjectPolicy#change_status?` already work.

---

## 3. Target Architecture — matched to mockup

All three mockup files (`projects_show.html.erb`, `progress_updates.html.erb`,
`projects_version_comparison.html.erb`) share **identical shell**:

```
┌────────────────────────────────────────────────────┬──────────────────┐
│ LEFT PANE (flex-1 flex flex-col overflow-y-auto)   │ RIGHT PANE       │
│                                                    │ (w-[380px]       │
│ ┌────────────────────────────────────────────────┐ │  shrink-0        │
│ │ Context Header (sticky info)                   │ │  flex flex-col)  │
│ │  Status badge · Timestamp · Title              │ │ ┌──────────────┐│
│ │  [Version: ▾ select]  [Approve ▾ split-btn]   │ │ │ Comments     ││
│ ├────────────────────────────────────────────────┤ │ │ header +     ││
│ │ Sticky Tabs                                    │ │ │ count badge  ││
│ │ [Project Details] [Compare Versions]           │ │ ├──────────────┤│
│ │              [Progress Updates]                 │ │ │ scrollable   ││
│ ├────────────────────────────────────────────────┤ │ │ comment list ││
│ │ Tab Panel Content (swaps per active tab)       │ │ │ (grouped by  ││
│ │                                                │ │ │  version)    ││
│ └────────────────────────────────────────────────┘ │ ├──────────────┤│
│                                                    │ │ Comment      ││
│                                                    │ │ composer     ││
│                                                    │ └──────────────┘│
└────────────────────────────────────────────────────┴──────────────────┘
```

**Critical constraint:** Comments are a **persistent sibling panel**, not a
tab. They are visible on every left-pane tab. This matches the current
working code (`w-[380px]`/`w-[450px]` right column in `show.html.erb:214-289`)
and all three mockups.

### What changes vs. current code

| Element | Current | Mockup |
|---------|---------|--------|
| Layout | Two-column with mobile/desktop split | Two-column, single rendering path |
| Mobile | `mobile-tabs` Stimulus, tabs hide/show | Same two-pane, comments折叠成4th tab on small screens |
| Context Header | `_project_header.html.erb` (373 lines): title + properties + status card + version card, all in one | Split: context header (status badge, title, version select, split-button) + "Project Overview" card in tab content |
| Status control | `<select>` + submit | Split-button (Approve primary, dropdown has Request Changes / Reject) |
| Version nav | Prev/next arrows | `<select>` dropdown in context header |
| Tab shell | Desktop: Turbo `link_to` tabs (`_project_fields.html.erb`). Mobile: `mobile-tabs` Stimulus | Stimulus `tabs_controller.js` (index-based, same as courses/show) |
| Compare Versions | Embedded in `_project_details.html.erb:141-375` | Own tab with compare toolbar + side-by-side diff |
| Progress Updates | Conditional tab (desktop), hidden panel (mobile) | Always-visible tab (content hidden behind `use_progress_updates`) |
| Right sidebar | `w-[450px]`, desktop only | `w-[380px]`, always visible |
| Comments partial | `_project_comments.html.erb` (178 lines) | Restyled to match mockup |
| "Back to Course" link | Inline at top and bottom | Removed (sidebar provides navigation context) |

---

## 4. Ticket List

### Ticket 1 — Tab shell controller

**Files:**
- Reuse existing `app/javascript/controllers/tabs_controller.js`. Already
  generic, index-based. No changes needed.
- **Do NOT delete `mobile_tabs_controller.js`** — `topics/show.html.erb:43`
  also uses `data-controller="mobile-tabs"`. Stays until topics/show is
  migrated.

### Ticket 2 — Extract "Compare Versions" into its own tab

**Files:**
- New `app/views/projects/_compare_versions_tab.html.erb` — **move**
  (cut/paste) the `VERSION DIFF COMPARISON` block from
  `_project_details.html.erb:141-375`. Same locals: `fields`, `next_fields`,
  `index`, `instances`.
- Modify `app/views/projects/_project_details.html.erb` — delete the moved
  block. What's left is purely the field list + "Based on Topic" footer.
- No controller changes.

**Behavior:** Tab always visible. When single version (`index >= instances.size`),
show empty state: "Only one version exists — nothing to compare yet."

**Compare toolbar (new in mockup):** The mockup shows a version-pair selector
above the diff (two `<select>` dropdowns with a swap icon between them). The
current code always compares `index` vs `index + 1`. The toolbar would let
users pick any two versions to compare. This is a **scope expansion** —
recommend building the diff table first (moved from _project_details), then
adding the toolbar as a follow-up if needed. The existing logic already
handles arbitrary version pairs via `@current_fields` / `@next_fields`.

### Ticket 3 — Restyle project header → split into context header + overview card

**This is the biggest structural change.** The current `_project_header.html.erb`
(373 lines) bundles everything: title, properties (Type/Owner/Supervisor/Group),
status card, and version card. The mockup splits this into:

1. **Context header** (inside left pane, above tabs): status badge, timestamp,
   title, version `<select>`, split-button. ~50 lines.
2. **"Project Overview" card** (tab panel content, first item in Details tab):
   Group Name, Type, Owners (with avatars), Supervisor. ~40 lines.

**Files:**
- New `app/views/projects/_context_header.html.erb` — extracted from
  `_project_header.html.erb`. Contains:
  - Status badge (pill, not card)
  - Timestamp ("Submitted 2 hours ago")
  - Title (`h1`)
  - Version `<select>` dropdown
  - Split-button (Approve primary, dropdown for Request Changes / Reject)
- New `app/views/projects/_project_overview.html.erb` — extracted from
  `_project_header.html.erb`. Contains:
  - "Project Overview" card with Group Name, Type, Owners, Supervisor
- Modify `app/views/projects/_project_header.html.erb` — delete everything
  extracted into the two new partials. What's left? Nothing — this partial
  is fully decomposed. Delete it.
- New `app/javascript/controllers/dropdown_controller.js` — generic
  open/close menu on click, close on outside-click/Escape. Needed for
  the split-button caret and the progress update `more_vert` menu.
- New `app/javascript/controllers/version_select_controller.js` — navigates
  to `course_project_path(course, project, version: N)` on `<select>` change.

**Status badge colors (from mockup):**
- Pending: `bg-[#E8F0FE] text-[#1967D2]`
- Approved: `bg-[#E6F4EA] text-[#137333]`
- Redo: `bg-[#FFF8E1] text-[#F57F17]`
- Rejected: `bg-[#FCE8E6] text-[#C5221F]`

**Split-button:** The primary button always says "Approve" (green). The
dropdown contains "Request Changes" (redo) and "Reject Proposal" (red hover).
All three hit `change_status_course_project_path` with the appropriate
`status:` param. Gated by `current_user == project.supervisor && current_version == latest_version`.

**Version `<select>`:** Options generated from `@instances`. Label format:
"1 of 3 (Current)" for latest, "2 of 3" for older. Navigates on change via
`version_select_controller.js`.

### Ticket 4 — Restyle Comments pane

**Files:**
- Modify `app/views/projects/_project_comments.html.erb` — visual restyle
  to match mockup. No behavior or local changes.
- Mockup shows: `w-[380px]`, `bg-[#f8fafd]`, `border-l border-[#E0E0E0]`,
  Google Sans header, comment count badge, scrollable list, bottom composer.
- The existing partial already has all this structure — it's a restyle, not
  a rebuild.

**Mobile behavior:** ~~On small screens, the right pane becomes a 4th tab in
the tab bar (Comments)~~ — **SUPERSEDED by ADR-0007.** Comments become an
icon-triggered drawer (see Ticket 9), and the review actions + version
switcher move to a pinned bottom bar. The tab bar stays a fixed set at every
width.

### Ticket 5 — Restyle Progress Updates tab + Record Update modal

**Files:**
- Modify `app/views/projects/_progress_updates.html.erb` — visual restyle
  to match mockup's timeline layout. Key changes from current:
  - Timeline vertical line with avatar nodes
  - Card-based layout (border, rounded-xl, bg-[#F8F9FA] header)
  - Rating pills (semantic colors matching status badge palette)
  - `more_vert` dropdown for Edit/Delete (instead of inline buttons)
  - "Record Update" button (blue pill) at top — wires to new modal
- New `app/views/projects/_record_update_modal.html.erb` — `<dialog>`
  matching mockup (`progress_updates.html.erb:367-420`):
  - Status `<select>` (No Progress / Unsatisfactory / Satisfactory / Excellent)
  - Feedback `<textarea>` with markdown hint
  - Cancel + Save Update buttons
  - Wired to existing `progress_updates_path` (POST)
  - Gated by `policy(@project).can_record_progress_update?`
- New `app/javascript/controllers/record_update_modal_controller.js` —
  mirrors `field_expand_modal_controller.js` pattern:
  - `open()` → `this.dialogTarget.showModal()`
  - `close()` → `this.dialogTarget.close()`
  - `submitEnd()` → close on successful Turbo submission, reset form
- No controller change (`@progress`/`@weeks` already only set when
  `@course.use_progress_updates`, `projects_controller.rb:44-47`).

### Ticket 6 — Wire the new shell into `show.html.erb`

**Files:**
- Rewrite `app/views/projects/show.html.erb`:
  - Remove `content_for :hide_toggler, true` and `content_for :no_sidebar, true`
    (these become dead once the header/sidebar ticket finalizes).
  - Remove the "Back to Course" links (top lines 19–36, bottom lines 294–311).
  - Replace `data-controller="mobile-tabs"` + two-column flex with the
    mockup's shell: `<main class="flex-1 bg-white rounded-tl-[28px] flex overflow-hidden">`
    containing left pane + right pane.
  - Left pane: context header → sticky tabs → tab panels.
  - Right pane: `render "project_comments"` (always visible).
  - Tab panels:
    - Panel 0 (Project Details): `_project_overview` + `_project_details`
      + `_project_actions`
    - Panel 1 (Compare Versions): `_compare_versions_tab`
    - Panel 2 (Progress Updates, conditional): `_progress_updates`

**Shell structure (pseudocode):**
```erb
<main class="flex-1 bg-white rounded-tl-[28px] flex overflow-hidden">
  <!-- LEFT PANE -->
  <div class="flex-1 flex flex-col overflow-y-auto">
    <%= render "context_header", ... %>
    <div class="border-b border-[#E0E0E0] px-8 sticky top-0 bg-white z-10">
      <nav class="flex gap-8">
        <button data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="0">Project Details</button>
        <button data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="1">Compare Versions</button>
        <% if @course.use_progress_updates %>
          <button data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="2">Progress Updates</button>
        <% end %>
      </nav>
    </div>
    <div data-tabs-target="panel" class="p-8 max-w-5xl space-y-8">
      <%= render "project_overview", ... %>
      <%= render "project_details", ... %>
      <%= render "project_actions", ... %>
    </div>
    <div data-tabs-target="panel" class="p-8 max-w-[85rem] hidden">
      <%= render "compare_versions_tab", ... %>
    </div>
    <% if @course.use_progress_updates %>
      <div data-tabs-target="panel" class="p-8 max-w-4xl hidden">
        <%= render "progress_updates", ... %>
      </div>
    <% end %>
  </div>
  <!-- RIGHT PANE -->
  <div class="w-[380px] bg-[#f8fafd] border-l border-[#E0E0E0] flex flex-col shrink-0">
    <%= render "project_comments", ... %>
  </div>
</main>
```

**No Settings link** — confirmed: the projects mockup has no Settings
tab/link. Projects don't have a separate settings page.

### Ticket 7 — `Project#owner_name` cleanup (independent)

**Files:**
- `Project#owner_name` already exists (`project.rb:61-69`). No model change.
- Update `app/views/courses/_project_card_contents.html.erb:18-24` to call
  `project.owner_name` instead of inlining the ternary.
- `Topic#owner_name` does NOT exist yet — add it (same implementation) or
  leave inline for now. Recommend adding for consistency.
- Not used by `projects/show` itself — cleanup while we're in the codebase.

### Ticket 9 — Responsive: comments drawer + pinned review action bar

**ADR:** `docs/adr/0007-comments-drawer-and-review-action-bar.md`

**Decision:** Below `min-[1245px]` the tab bar must never grow a 4th tab. Two
mobile-only presentations instead:

1. **Comments drawer** — the right pane stays a single element that is the
   static sticky comments column on desktop and an off-canvas slide-in panel
   on mobile. Same element, responsive classes only.
2. **Pinned review action bar** — the version switcher + policy-driven
   actions are `fixed` to the bottom on mobile (thumb-reachable on every tab).

**Files:**
- New `app/views/projects/_review_actions.html.erb` — extracted from the old
  `_project_review_card`: version `<select>` + action body. **Single source of
  truth** for the controls and role gates; both frames render this partial.
  The split-button status dropdown opens **upward** in the mobile bar vs
  downward in the card (`bottom-full ... min-[1245px]:top-full`).
- New `app/views/projects/_review_action_bar.html.erb` — mobile-only pinned
  bar frame (`fixed bottom-0 ... min-[1245px]:hidden`), includes
  `env(safe-area-inset-bottom)` padding. Renders `_review_actions`.
- New `app/javascript/controllers/comments_drawer_controller.js` — registry
  identifier `comments-drawer`; targets `panel`/`backdrop`/`trigger`; toggles
  `translate-x-full` + `hidden` on the backdrop, body scroll lock, Escape
  close, `aria-expanded` on the trigger. It never affects desktop because
  `min-[1245px]:translate-x-0` wins.
- Modify `app/views/projects/_project_review_card.html.erb` — now a
  desktop-only frame (`hidden min-[1245px]:flex`) = title + Active badge
  + `render "review_actions"`.
- Modify `app/views/projects/_project_header.html.erb` — tab row becomes
  `justify-between`; right side gains the comments trigger (chat_bubble icon
  + count badge, `min-[1245px]:hidden`, `aria-controls="comments-drawer"`).
  New `comments_count` local.
- Modify `app/views/projects/show.html.erb` — `<main>` gets
  `data-controller="tabs comments-drawer"` + `keydown.esc@window` action; the
  right pane gets `id="comments-drawer"`, `data-comments-drawer-target="panel"`
  and the drawer/mobile classes; a backdrop element follows the pane; the
  action bar renders after `</main>`; the content column gets
  `pb-28 min-[1245px]:pb-8` so nothing hides under the pinned bar.

**Gates (shared, in `_review_actions`):** supervisor + latest →
`change_status?` split-button; owner/coordinator → `_project_actions`
(Edit / Unable to Edit / Jump To Latest); every viewer gets the version
switcher. The bar/card render for all roles (a no-action viewer sees the lone
version switcher, preserving today's always-visible review card).

**Breakpoint:** `min-[1245px]`, matching existing usage in `projects/show`
(sticky comments heights) and `topics/show` (mobile-tabs).

**Deferred (noted but not built):** `topics/show` keeps its `mobile-tabs` +
comments-column behavior until migrated to the same drawer; 3-tab overflow on
sub-~380px viewports is unflagged.

### Known broken system tests (pre-existing, from earlier redesign)

`test/system/projects/project_versioning_test.rb` (3 tests) and
`test/system/projects/change_status_test.rb` (happy-path test) reference
removed testids (`version-back`, `version-next`, `current-version`,
`status-select`, `change-status-submit`) that no longer exist in the
redesigned review UI (replaced by the version `<select>` + split-button).
Fixing them needs a JS-aware driver or new selectors; defer to a follow-up.

### Ticket 8 — Delete dead partials

**Files:**
- Delete `app/views/projects/_project_fields.html.erb` — confirmed only
  referenced at `show.html.erb:160`. Desktop-only Turbo tab wrapper.
- Delete `app/views/projects/_comments_panel.html.erb` — dead code.
  Legacy Google-Material panel, never rendered.
- Delete `app/views/projects/_project_header.html.erb` — after Ticket 3
  decomposes it into `_context_header` + `_project_overview`.
- **Do NOT delete `mobile_tabs_controller.js`** — still used by
  `topics/show.html.erb:43`.

---

## 5. File Operations Summary

### New files (8)
1. `app/views/projects/_context_header.html.erb` — status badge, title, version select, split-button
2. `app/views/projects/_project_overview.html.erb` — Project Overview card (Group Name, Type, Owners, Supervisor)
3. `app/views/projects/_compare_versions_tab.html.erb` — side-by-side diff (compare toolbar deferred — see §7 item 11)
4. `app/views/projects/_record_update_modal.html.erb` — `<dialog>` for recording progress updates
5. `app/javascript/controllers/dropdown_controller.js` — generic click-toggle dropdown
6. `app/javascript/controllers/version_select_controller.js` — navigate on `<select>` change
7. `app/javascript/controllers/record_update_modal_controller.js` — open/close/reset `<dialog>`

### Ticket 9 additions (ADR-0007)
- `app/views/projects/_review_actions.html.erb` — shared version switcher + action body
- `app/views/projects/_review_action_bar.html.erb` — mobile pinned bottom bar frame
- `app/javascript/controllers/comments_drawer_controller.js` — comments drawer toggle/backdrop/Escape

### Modified files (4)
6. `app/views/projects/show.html.erb` — rewrite (two-pane shell with persistent comments)
7. `app/views/projects/_project_details.html.erb` — remove version diff block (moved to _compare_versions_tab)
8. `app/views/projects/_project_comments.html.erb` — visual restyle
9. `app/views/projects/_progress_updates.html.erb` — visual restyle (timeline layout)

### Deleted files (3)
10. `app/views/projects/_project_fields.html.erb`
11. `app/views/projects/_comments_panel.html.erb`
12. `app/views/projects/_project_header.html.erb` — after decomposition

### Untouched files
- `app/views/projects/_project_actions.html.erb` — no changes
- `app/views/projects/_comment.html.erb` — no changes
- `app/controllers/projects_controller.rb` — no changes
- `app/javascript/controllers/tabs_controller.js` — no changes
- `app/javascript/controllers/scroll_to_bottom_controller.js` — no changes
- `app/javascript/controllers/field_expand_modal_controller.js` — no changes
- `app/javascript/controllers/textarea_resize_controller.js` — no changes
- `app/javascript/controllers/mobile_tabs_controller.js` — NOT deleted (topics/show)
- `app/views/projects/edit.html.erb` — no changes
- `app/views/projects/new.html.erb` — no changes

---

## 6. Build Order

```
1 → 2 → 7 (parallel) → 3 → 4 → 5 → 6 → 8 → 9
```

Tickets 2, 4, 5 don't depend on each other. Ticket 7 is fully independent.
Ticket 8 (deletions) is last.

**Within each ticket:** build the partial/controller first, then wire into
the parent view, then visual QA, then tests.

---

## 7. Open Items (resolved)

1. **Compare Versions empty state** → Show tab with empty state message.
2. **Split-button interaction** → `dropdown_controller.js` (click toggle,
   not CSS hover — works on touch).
3. **Version control** → `<select>` dropdown per mockup.
4. **Comments on desktop** → Persistent `w-[360px]` right pane as one element,
   a static sticky column on desktop. **On mobile → comments drawer (ADR-0007)
   — SUPERSEDED: not a 4th tab.** See Ticket 9.
5. **`owner_name` precedence** → Already on `Project` at `project.rb:61-69`.
   Card partials call the model method. No behavior change.
6. **Settings link** → Not in the mockup. No link added.
7. **Bottom "Back to Course"** → Removed. Sidebar provides nav context.
8. **`_project_fields.html.erb` deletion** → Confirmed only at `show.html.erb:160`.
9. **`mobile_tabs_controller.js`** → NOT deleted — `topics/show.html.erb:43`.
10. **Record Update modal** → `<dialog>` with new Stimulus controller,
    mirroring `field_expand_modal_controller.js`. Replaces page navigation.
11. **Compare toolbar** → **Deferred.** Mockup shows two `<select>` dropdowns
    for picking any two versions. Current code only compares adjacent versions.
    Build the diff table first (moved from _project_details); toolbar is a
    follow-up. Flagged in `_compare_versions_tab.html.erb` with a TODO comment.
12. **`_project_header.html.erb` deletion** → After Ticket 3 decomposes it.
    Confirm both new partials cover all 373 lines of content.

---

## 8. Tests

### New: `test/system/projects/project_show_test.rb`

Minimum coverage:
- **Layout:** Two-pane layout renders (left content + right comments).
- **Tab visibility:** Three tabs render. Progress tab hidden when
  `use_progress_updates` is false.
- **Tab switching:** Clicking each tab shows correct panel, hides others.
  Comments sidebar remains visible across all tabs.
- **Compare Versions:** Viewing older version shows diff table. Viewing
  latest shows empty state.
- **Version select:** Dropdown navigates to correct version.
- **Split-button status:** Supervisor sees split-button; non-supervisor
  sees static badge.
- **Actions:** Edit Proposal visible to owner on latest version.
  "Jump To Latest Version" shown when viewing older version.
- **Comments:** Grouped by version; form visible when policy allows;
  soft delete works. Comments visible on all tabs.
- **Progress updates:** Timeline layout renders; Record Update button
  visible to supervisor on approved project; modal opens, submits, closes.
- **Responsive:** The three content tabs stay identical at every width. Below
  `min-[1245px]`, comments become a drawer (trigger icon + count badge in the
  tab bar; backdrop; Escape; scroll lock) and the version switcher + actions
  pin to a bottom bar. Desktop keeps the static sticky comments column.
- **New:** `test/system/projects/project_show_responsive_test.rb` — structural
  coverage only (rack_test has no JS/viewport): drawer trigger/panel/backdrop
  present, comments render, review actions + version switcher render, supervisor
  sees the Approve split-button. No count-based select asserts (the shared
  `_review_actions` renders in both frames; `select_tag nil` emits no `id`).

### Updated: `test/system/projects/project_versioning_test.rb`

Existing tests should continue to pass — version navigation is preserved
(arrows replaced by dropdown, but route/param structure identical).
