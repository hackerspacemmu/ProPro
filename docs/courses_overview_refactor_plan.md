# ProPro Redesign — courses/show Overview Refactor Plan

Grounded against `hackerspacemmu/ProPro` `refactor/design` and the hardcoded
mockup at `ProPro_Design/course_show.html.erb`. All identifiers and queries
verified against actual controller/model/view code. File:line references
included for re-verification.

**Relation to other docs:** `docs/courses_show_refactor_plan.md` is the
previous (outdated) courses/show audit — **not** the source for this pass.
This plan supersedes it for the Overview work. `docs/projects_show_refactor_plan.md`
is the template this doc follows (query audit → architecture → tickets →
files → build order → tests).

**In scope:** the mockup's consolidated **Overview** (first-tab) content, the
first-tab rename, converting **topic cards to row-style list items**, and the
per-section **expand/collapse** behavior (§11).
**Out of scope:** the tab bar itself (only the first tab's label string
changes) and People/Groups/Topic-Directory content behavior.

---

## 1. Ground truth — the mockup

`ProPro_Design/course_show.html.erb` renders a single scrollable overview page:

```
┌ Course Overview content (max-w-[800px] centered column) ─────────────┐
│                                                                       │
│  ░░ Project Details card (bg-[#f8f9fa], rounded-[10px], shadow-sm) ░░ │
│  ░░   h4 "Project Details" + description paragraph                  ░░│
│  ░░   attachment file pill (folder_zip icon + filename)             ░░│
│                                                          [Collapse all]│
│                                                                       │
│  Supervised Projects ─────────── 1 ▾                                 │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │ (icon) EduPulse Analytics Platform   Group 8 • Updated 2 days ago│ │
│  │                                                    [Approved] ⋮ │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  Pending Proposals ──────────── 4 ▾                                  │
│  ┌ row ... Pending ┐ ┌ row ... Pending ┐ ...                          │
│                                                                       │
│  Reviewed Proposals ─────────── 4 ▾                                  │
│  ┌ row ... Redo ┐ ┌ row ... Rejected (opacity-80) ┐ ...               │
│                                                                       │
│  Pending Topics ────────────── 2 ▾                                   │
│  ┌ row (topic icon) + owner • Proposed x ago ┐ ...                    │
└───────────────────────────────────────────────────────────────────────┘
```

Row language shared by proposals and topics: circular icon avatar on the left,
title + meta on the left, status pill + `more_vert` on the right, one line at
every width. Section headers are title + blue count + `expand_less` chevron.

---

## 2. Query / Data Audit

| Claimed form | Status | Evidence |
|---|---|---|
| `@description` | ✅ set in `#show` | `courses_controller.rb:17` (`@course.course_description`) |
| `@course.file_link` | ✅ on the model | rendered today in `_project_details_tab.html.erb:8` |
| `@approved_projects` | ✅ set in `#show` | `courses_controller.rb:81` (`@my_student_projects.select(&:approved?)`) |
| `@pending_proposals` | ✅ set in `#show` | `courses_controller.rb:69` |
| `@reviewed_proposals` | ✅ set in `#show` | `courses_controller.rb:70` |
| `@pending_topics` | ✅ set in `#show` | `courses_controller.rb:71-78` |
| `@lecturers` | ✅ set in `#show` | `courses_controller.rb:18` (for the solo-supervisor card) |
| `Topic#owner_name` | ✅ exists | `topic.rb` (`owner_name`) — used by `_topic_card_contents` |

**No controller changes required.** Every ivar the Overview needs is already
computed in `CoursesController#show`.

---

## 3. What's already correct — do not rebuild

- **Proposal rows** — `app/views/projects/_proposal_list_item.html.erb`
  already produces the mockup's row language (icon avatar, title, meta,
  status pill, `more_vert`). It is reused unchanged for the Overview's
  Pending/Reviewed Proposals sections.
- **Controller data** — see §2; nothing new to compute.
- **Sidebar / header chrome** — untouched this pass.
- **Tab shell (`tabs_controller.js`)** — untouched; only panel content and
  one tab label change.

---

## 4. Target architecture

### 4.1 The Overview tab (first tab, renamed from "Project Details")

New `app/views/courses/_overview_tab.html.erb`, rendered in the first-tab
panel slot of `show.html.erb` with the mockup column classes:

```
<div class="max-w-[800px] mx-auto px-8 py-10 pb-20">

  Project Details card        (from _project_details_tab card, restyled)

  <div class="flex justify-end mb-10">
    [Collapse all]            (unfold_less icon, text-[#1A73E8]) — static
  </div>

  Supervised Projects section (header + @approved_projects rows)
  Pending Proposals section   (header + _proposal_list_item rows)
  Reviewed Proposals section  (header + _proposal_list_item rows)
  Pending Topics section      (header + topic row items)

</div>
```

Section header markup (reusable, matches mockup §1):

```erb
<div class="flex items-center justify-between mb-4">
  <h2 class="truncate min-w-0 text-[22px] font-normal text-[#202124]">Title</h2>
  <div class="flex items-center gap-3 shrink-0">
    <span class="text-[#1A73E8] font-medium text-[15px]">COUNT</span>
    <span class="material-symbols-outlined text-[#5F6368]">expand_less</span>
  </div>
</div>
```

Sections are stacked lists, **not** grids:

```erb
<div class="flex flex-col border-b border-[#E0E0E0]">
  <% render row items ... %>
</div>
```

### 4.2 The Project Details card (restyled)

Source: `_project_details_tab.html.erb:1-21`. Target (mockup `:92-110`):

- `bg-[#f8f9fa] border-gray-200 shadow-sm rounded-[10px] p-6`
- h4 "Project Details": `text-xl font-medium text-[#202124]`
- Description paragraph: `text-[#5F6368]`, `leading-[1.5]`, `whitespace-pre-line`
- File link (only when `@course.file_link.present?`): white pill
  (`border-[#DADCE0] rounded-[8px] bg-white pl-3 pr-5 py-2.5`, `folder_zip`
  icon in a `bg-[#E8F0FE] text-[#1A73E8] rounded-[6px] w-[36px] h-[36px]`
  box) + a filename label. Filename: derive from `@course.file_link` basename
  or fall back to a stable label.

### 4.3 Topic card → row item (all `_topic_card` call sites)

Rewrite `_topic_card.html.erb` (and `_topic_card_contents.html.erb`) so a
topic renders as a row, not a colored card:

```erb
<%= link_to path, class: "group flex items-center justify-between px-4 py-3
    border-t border-[#E0E0E0] hover:bg-[#F1F3F4] transition-colors cursor-pointer
    no-underline text-inherit bg-white" do %>
  <div class="flex items-center gap-4 min-w-0">
    <div class="w-9 h-9 rounded-full border border-[#DADCE0]
        flex items-center justify-center shrink-0 text-[#5F6368]">
      <span class="material-symbols-outlined text-[20px]">topic</span>
    </div>
    <div class="min-w-0">
      <h3 class="text-[15px] font-medium text-[#202124] truncate"><%= title %></h3>
      <div class="flex items-center gap-2 text-[13px] text-[#5F6368]">
        <span class="truncate"><%= owner_name %></span>
        <span>•</span>
        <span>Proposed <%= time_ago_in_words(topic.updated_at) %> ago</span>
      </div>
    </div>
  </div>
  <div class="flex items-center gap-3 shrink-0">
    <span class="bg-[#E8F0FE] text-[#1967D2] px-2.5 py-0.5 rounded
        text-[12px] font-medium tracking-wide"><%= status.humanize %></span>
    <span class="material-symbols-outlined text-[#5F6368]">more_vert</span>
  </div>
<% end %>
```

**Preserve** these behaviors from the current `_topic_card`:
- Path logic: `course_lecturer_topic_path` when `local_assigns[:lecturer]`,
  else `course_topic_path(@course, topic, from_edit_project: true, project_id: ...)`
  when `params[:from_edit_project]`, else `course_topic_path(@course, topic,
  from_new_project: params[:from_new_project])` (`_topic_card.html.erb:20-27`).
- `policy(topic).show?` gating → linking row; else a non-linking
  `opacity-75` row (`_topic_card.html.erb:33-49`).
- Skip rendering when there is no `topic_instance` (`_topic_card.html.erb:1`).

Status pill palette (same as the proposals): Pending `bg-[#E8F0FE] text-[#1967D2]`,
Approved `bg-[#E6F4EA] text-[#137333]`, Redo `bg-[#FFF8E1] text-[#E65100]`,
Rejected `bg-[#FCE8E6] text-[#C5221F]`.

### 4.4 Adapt grid wrappers at every `_topic_card` call site

The surrounding `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3` wrappers must
become single-column stacked lists now that rows render full-width:

| Call site | Line | Change |
|---|---|---|
| `courses/_to_review_tab.html.erb` pending-topics grid | `:40-42` | grid → stacked rows |
| `courses/_topic_directory_tab.html.erb` | `:18`, `:86` | grid → stacked rows |
| `topics/index.html.erb` | `:90` | grid → stacked rows |
| `lecturers/show.html.erb` | `:346`, `:381`, `:414` | grid → stacked rows |
| `topics/_copy_topic_overlay.html.erb` | `:54` | renders `_topic_card_contents` directly; re-wrap into the row container manually (see Ticket 3 note) |

---

## 5. Ticket List

### Ticket 1 — Build `_overview_tab.html.erb`

**Files:** New `app/views/courses/_overview_tab.html.erb`.
**Content:** the Project Details card + Collapse all + four sections from §4.1.
Reuse `projects/proposal_list_item` for the two proposal sections; render
`@pending_topics` with the rewritten `_topic_card`.
**No controller changes.**

### Ticket 2 — Restyle the Project Details card

**Files:** `_overview_tab.html.erb` (inline card, per §4.2). When
`@course.solo_supervisor?`, keep the existing "Instructor:" supervisors card —
but that card lives in `_project_details_tab.html.erb`, which this pass is
replacing on the first tab. Decide: fold the solo-supervisor card into
`_overview_tab` too (recommended, preserves behavior) or drop it for now.

### Ticket 3 — Rewrite `_topic_card` + `_topic_card_contents` as row items

**Files:** `app/views/courses/_topic_card.html.erb`,
`app/views/courses/_topic_card_contents.html.erb`.
Per §4.3. This single change re-skins every call site because they share the
partial. Rename the partial to the content column classes is optional; keep
the mixin of behavior (paths, policy gate, no-instance guard).

### Ticket 4 — Adapt surrounding grid wrappers

**Files:** `_to_review_tab.html.erb`, `_topic_directory_tab.html.erb`,
`topics/index.html.erb`, `lecturers/show.html.erb`.
Turn each `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3` wrapper into a
single-column stacked list (§4.4).

### Ticket 5 — Copy-topic overlay containment

**Files:** `topics/_copy_topic_overlay.html.erb`.
Renders `_topic_card_contents` directly. Wrap its content in the row container
classes so the overlay shows a row, or — if a card-like layout is
intentionally required inside the modal — keep a local `row:` flag and have
`_topic_card_contents` choose layout. Recommend the `row:` flag so the copy
overlay can opt out if needed. Confirm behavior during implementation.

### Ticket 6 — Wire Overview into `show.html.erb`

**Files:** `app/views/courses/show.html.erb`.
- Rename the first tab label `"Project Details" → "Overview"` (`:12`).
- Render `_overview_tab` in the first-tab panel slot with the
  `max-w-[800px] mx-auto px-8 py-10 pb-20` column classes.
- Leave all other tabs' labels and panel renders untouched.

---

## 6. Responsiveness plan (agreed this session)

- **Overview column:** `max-w-[800px] mx-auto px-8 py-10 pb-20` at every width
  (matches the mockup; narrower than the current `max-w-5xl`).
- **Rows (proposals + topics):** one line at every width — avatar + title +
  meta on the left, status pill + `more_vert` on the right. The meta line may
  truncate/wrap within its own space; it must not break the row into stacked
  blocks. Achieved with `min-w-0` + `truncate` on title and meta.
- **Section headers:** `flex items-center justify-between`; title is
  `truncate min-w-0` so long titles ellipsize instead of wrapping on phone
  widths; count + chevron stay right-aligned (`shrink-0`).
- **No horizontal overflow:** row content uses `min-w-0`/`truncate`; the
  content column scrolls vertically in the page's `overflow-y-auto` pane.
  Existing pages with `overflow-x-auto` tables (People/Groups) are untouched.

---

## 7. File Operations Summary

### New files (1)
1. `app/views/courses/_overview_tab.html.erb`

### Modified files (6)
2. `app/views/courses/show.html.erb` — tab label + first-panel render + column classes
3. `app/views/courses/_topic_card.html.erb` — card → row item
4. `app/views/courses/_topic_card_contents.html.erb` — card contents → row item (optional `row:` flag)
5. `app/views/courses/_to_review_tab.html.erb` — pending-topics grid → stacked rows
6. `app/views/courses/_topic_directory_tab.html.erb` — topic grids → stacked rows
7. `app/views/topics/index.html.erb` — topic grid → stacked rows
8. `app/views/lecturers/show.html.erb` — topic grids → stacked rows
9. `app/views/topics/_copy_topic_overlay.html.erb` — wrap contents in row container (or `row:` flag)

### Untouched files
- `app/controllers/courses_controller.rb` — no changes
- `app/views/projects/_proposal_list_item.html.erb` — no changes (already matches)
- `app/views/courses/_project_details_tab.html.erb` — replaced by `_overview_tab` on the first tab; keep file (To Review / solo-supervisor references may remain) or reconcile
- Tab chrome `tabs_controller.js`, `_sidebar`, `_header` — no changes

---

## 8. Build Order

```
1 → 2 → 3 → 4 → 5 → 6
```

Ticket 3 (topic row) should land before Ticket 4 (wrapper grids) so the rows
render correctly as soon as the wrappers change. Ticket 6 (wire-in) is last
and low-risk.

---

## 9. Tests

### Existing tests to keep green
- `test/system/courses/course_tabs_test.rb` — validates tab visibility
  per role. The removed "Project Details" label must be updated to "Overview"
  wherever asserted (assert against `Overview`, not `Project Details`).
- `test/controllers/courses_controller_test.rb` — no controller change, so
  these stay green.

### Recommended new / updated tests
1. `course_tabs_test.rb` — update the first-tab label assertion to "Overview".
2. First-tab content test — Overview renders the four section headers
   (Supervised Projects, Pending Proposals, Reviewed Proposals, Pending
   Topics), the Project Details card, and the Collapse all control; counts
   match `@approved_projects` / `@pending_proposals` / etc.
3. Topic-row test — a topic renders as a row item (status pill + owner meta),
   not a colored header card, on the Overview and in the Topic Directory.
4. Responsive structural test (rack_test, no JS): assert no horizontal page
   overflow / columns present at phone width.

---

## 10. Open items (for implementation)

1. **`_copy_topic_overlay`** — confirm row vs. card inside the modal; use a
   `row:` local flag on `_topic_card_contents` if isolation is needed.
2. **Solo-supervisor "Instructor:" card** — fold into `_overview_tab` to
   preserve behavior, or drop this pass.
3. **`_project_details_tab.html.erb` fate** — after `_overview_tab` replaces
   its first-tab role, reconcile whether it still has any renderers (it is
   also the solo-supervisor card's home). Retain the file this pass; revisit
   on the later tab-deletion pass.

---

## 11. Expand/collapse the Overview sections (agreed this session)

Implements the collapsible behavior behind the previously static
collapsible-look headers: each Overview section (Supervised Projects, Pending
Proposals, Reviewed Proposals, Pending Topics) toggles its own row list, and
the **Collapse all** control toggles all four.

### Decision: new controller — do not reuse `expandable_rows`

`expandable_rows_controller.js` is structurally coupled to the Groups table:
it pairs `<tr>` rows (`data-row-id` ↔ `data-detail-row-id`), reads a
hardcoded `#groups-table-toggle-all` id for its toggle-all icon, and uses
delegated listeners because htmx swaps the tbody. Generalizing it for
block-shaped sections would force markup changes on the htmx-swapped
`_groups_table` (regression risk). A new focused controller matches the
project's small-controller idiom (`tabs`, `sidebar`, `comments_drawer`, ...).

### Controller

New `app/javascript/controllers/collapsible_sections_controller.js`
(autoloaded by `controllers/index.js`):

- **Data scheme** (mirrors the `expandable-rows` pairing mental model): a
  header carries `data-collapsible-sections-target="toggle"` and its body
  container carries `data-collapsible-sections-target="body"`; each side also
  carries the same `data-collapsible-sections-section="<slug>"`, and the
  controller pairs them by that value (no index pairing, safe under the
  conditional `if ... .any?` renders).
- **`toggle(event)`** — `event.currentTarget` is the header; find the paired
  body, toggle `hidden`, flip the header chevron with `rotate-180`, then
  re-sync the toggle-all button.
- **`onKeydown(event)`** — Enter/Space on the header triggers `toggle`
  (`role="button" tabindex="0"`).
- **`toggleAll()`** — if *every* body is collapsed, expand all; otherwise
  collapse all (same semantics as the Groups toggle-all). Flips every
  chevron, then syncs the button.
- **`syncToggleAll()`** — icon `unfold_less` + "Collapse all" when anything
  is expanded, `unfold_more` + "Expand all" when everything is collapsed.
- Chevron is found via an explicit `data-collapsible-sections-chevron=...`
  attribute, not a class query.

### Section header

`courses/_section_header.html.erb` gains an optional `section` local. When
present the header renders interactive (mockup's `cursor-pointer group`,
`role="button" tabindex="0"`, the two `data-action`s, the toggle/chevron data
attributes, and the mockup's `group-hover:text-[#202124]` chevron hover). When
absent it stays the static header.

### Overview wiring

`_overview_tab.html.erb`:

- Wrap the **Collapse all** button and the four sections in
  `<div data-controller="collapsible-sections">`. The button carries
  `data-action="collapsible-sections#toggleAll"` plus
  `toggleAllIcon`/`toggleAllLabel` targets (still `unfold_less` + "Collapse
  all", per the mockup) and only renders when at least one section has rows.
- Each section passes `section: "<slug>"` to `_section_header` and the body
  data attributes to `shared/row_list` via its new `container_attrs:` local.

### `shared/_row_list` extension

`shared/_row_list.html.erb` accepts optional `container_attrs:` (merged onto
the container div through `tag.div`) so a body can carry its
`data-collapsible-sections-target="body"` + section slug without an extra
wrapper div. Default `{}`.

Default state on load = expanded (mockup). No state persistence — a Turbo
reload resets to expanded. Slugs: `supervised-projects`, `pending-proposals`,
`reviewed-proposals`, `pending-topics`. Behavior only; the mockup's static
"collapse" chevron (`expand_less`) is retained as the expanded glyph.

### 11.1 Refinements agreed after the first expand/collapse pass

1. **Row items: pill ↔ time_meta swap.** `shared/_row_item` now places the
   status pill inline at the end of the `meta_parts` line ("Group 8 •
   [Approved]") and renders the "Submitted X ago" text as a new `time_meta`
   local on the far right at 16px / 400 / 1.5rem (`text-[16px] font-normal
   tracking-normal leading-6`), matching the style_guide's Meta/Timestamp
   scale. All three `row_item` callers (`_proposal_list_item`, `_topic_card`,
   `_copy_topic_overlay`) pass `time_meta` instead of embedding the time in
   `meta_parts`.
2. **Empty states.** The four Overview sections now render unconditionally;
   `_overview_tab` shows a per-section empty-state sentence when a section has
   no rows (`.875rem` / 500 / 1.25rem, `#5F6368`), inside the collapsible body
   (`data-collapsible-sections-target="body"`), so headers/toggle still work.
   The **Collapse all** button only renders when at least one section has rows.
   Copy: Supervised Projects — "Projects that are approved by you will appear
   here."; Pending Proposals — "Proposals that are pending review from you will
   appear here."; Reviewed Proposals — "Proposals that you previously rejected
   and returned."; Pending Topics — "Topics that are pending review from you
   will appear here."
3. **Persistent top line.** `shared/_row_item` gained a `border_top:` local
   (default true) and `shared/_row_list` a `borderless_first:` local (default
   off). The Overview sections pass `borderless_first: true` and render an
   always-visible `<div class="border-t border-[#E0E0E0]">` between the section
   header and the collapsible body; because the line lives outside the body it
   persists when the section is collapsed (no doubled 2px seam when expanded —
   the first row is borderless).
