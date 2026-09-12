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
first-tab rename, converting **topic cards to row-style list items**, the
per-section **expand/collapse** behavior (§11), **removing the To Review tab**
(D1), **settings icon relocation** (D2), and **presenter-based section
visibility** (D3, D4).
**Out of scope:** People/Groups/Topic-Directory content behavior.

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

---

## 12. Tab bar cleanup & presenter-based visibility (2026-09-02)

Supersedes §5 Ticket 4's reference to `_to_review_tab.html.erb` (deleted here)
and introduces a presenter for section visibility in the Overview tab.

### Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Remove `_to_review_tab.html.erb` + its `show.html.erb` callsite | Overview tab already renders the same three sections (Pending Proposals, Reviewed Proposals, Pending Topics) via collapsible sections |
| D2 | Settings → gear icon button, rightmost in header row | Same flex row, icon-only (`material-symbols-outlined`), `ml-auto` or `justify-between` |
| D3 | Don't render hidden sections at all (no empty states for students) | Presenter gates the `render` call; section container never hits the DOM. Empty states are dishonest UI when the section isn't for the current role. |
| D4 | Introduce `OverviewPresenter` for section visibility; keep Pundit for record-level auth | View objects (per Copeland §7.3.3) for presentation decisions, policies for authorization — complementary |

### Role visibility matrix

| Section | Coordinator | Lecturer | Student |
|---------|:-----------:|:--------:|:-------:|
| Supervised Projects | ✓ | ✓ | ✗ |
| Pending Proposals | ✓ | ✓ | ✗ |
| Reviewed Proposals | ✓ | ✓ | ✗ |
| Pending Topics | ✓ | ✗ | ✗ |

### 12.1 OverviewPresenter

**Path:** `app/presenters/overview_presenter.rb` (new directory)

```ruby
class OverviewPresenter
  def initialize(enrolment:, approved_projects:, pending_proposals:,
                 reviewed_proposals:, pending_topics:)
    @enrolment = enrolment
    @approved_projects = approved_projects
    @pending_proposals = pending_proposals
    @reviewed_proposals = reviewed_proposals
    @pending_topics = pending_topics
  end

  # Section visibility — returns false → section is not rendered at all
  def show_supervised_projects? = !student?
  def show_pending_proposals?    = !student?
  def show_reviewed_proposals?   = !student?
  def show_pending_topics?       = coordinator?

  # Collection accessors (view passes these to row_list)
  def supervised_projects = @approved_projects
  def pending_proposals   = @pending_proposals
  def reviewed_proposals  = @reviewed_proposals
  def pending_topics      = @pending_topics

  # Replaces the has_rows check — only counts sections the current role sees
  def any_sections?
    (show_supervised_projects? && @approved_projects.any?) ||
    (show_pending_proposals?   && @pending_proposals.any?) ||
    (show_reviewed_proposals?  && @reviewed_proposals.any?) ||
    (show_pending_topics?      && @pending_topics.any?)
  end

  private

  def student?     = @enrolment&.student?
  def coordinator? = @enrolment&.coordinator?
end
```

Takes `enrolment` (not `user`) because role lives on `Enrolment` (enum on
`Enrolment#role`, not `User`). The `&.` safe navigation handles the edge case
of an unenrolled user (policy already blocks page access, but the presenter
shouldn't blow up).

### 12.2 Controller change

In `CoursesController#show`, after the existing data-loading block (lines
58–81), build the presenter:

```ruby
@presenter = OverviewPresenter.new(
  enrolment: @current_user_enrolment,
  approved_projects: @approved_projects,
  pending_proposals: @pending_proposals,
  reviewed_proposals: @reviewed_proposals,
  pending_topics: @pending_topics
)
```

The existing role-based `if/elsif` blocks that populate `@my_student_projects`
and `@incoming_proposals` **stay** — they scope data to the current supervisor.
The presenter only decides **visibility**, not data scoping. For students,
`@my_student_projects` is already `[]`; the key change is the view won't render
those sections at all.

### 12.3 Overview tab changes

`_overview_tab.html.erb`: wrap each section in presenter guards:

```erb
<% if @presenter.show_supervised_projects? %>
  <div class="border-t border-[#E0E0E0] py-5">
    <%= render "section_header", title: "Supervised Projects",
        count: @presenter.supervised_projects.size, section: "supervised-projects" %>
    <% if @presenter.supervised_projects.any? %>
      <%= render "shared/row_list", rows: @presenter.supervised_projects, ... %>
    <% else %>
      <p class="text-[#5F6368] text-[0.875rem] leading-[1.5rem]">
        Projects that are approved by you will appear here.
      </p>
    <% end %>
  </div>
<% end %>
```

Same pattern for Pending Proposals, Reviewed Proposals, Pending Topics. Update
`has_rows` to use `@presenter.any_sections?`.

### 12.4 Tab bar changes

**`show.html.erb`:**

1. **Remove to_review** — delete the `tabs <<` line for `"to_review"`.

2. **Settings → icon button** — replace the text link with:

```erb
<div class="border-b border-[#E0E0E0] px-8 bg-white shrink-0">
  <div class="flex items-center justify-between">
    <div role="tablist" class="flex flex-wrap gap-y-1">
      <%# tab buttons unchanged %>
    </div>

    <% if @current_user_enrolment&.coordinator? %>
      <%= link_to settings_course_path(@course),
            class: "h-[3rem] w-[3rem] flex items-center justify-center rounded-full text-[#5F6368] hover:bg-[#F1F3F4] transition-colors",
            title: "Settings" do %>
        <span class="material-symbols-outlined">settings</span>
      <% end %>
    <% end %>
  </div>
</div>
```

Key: `justify-between` puts tabs left, icon right. Coordinator-only guard
matches the existing `CoursePolicy#update?` authorization.

### 12.5 File operations (this section only)

| Operation | File |
|-----------|------|
| **Create** | `app/presenters/overview_presenter.rb` |
| **Modify** | `app/controllers/courses_controller.rb` — build `@presenter` |
| **Modify** | `app/views/courses/_overview_tab.html.erb` — presenter guards |
| **Modify** | `app/views/courses/show.html.erb` — remove to_review tab, settings icon |
| **Delete** | `app/views/courses/_to_review_tab.html.erb` |
| **Delete** | `app/views/courses/_supervised_projects_tab.html.erb` (already unreferenced) |
| **Modify** | `test/controllers/courses_controller_test.rb` — fix stale tab names, add role visibility tests |
| **Modify** | `test/system/courses/course_tab_persistence_test.rb` — remove To Review tab test |

### 12.6 Tests

**Controller test updates** (`courses_controller_test.rb`):
- Fix stale `'Project Details'` → `'Overview'` assertions
- Remove/update `'To Review'` tab assertions
- Add: student does NOT see section headers (Supervised Projects, Pending Proposals, Reviewed Proposals, Pending Topics) in response body
- Add: lecturer sees Supervised Projects, Pending Proposals, Reviewed Proposals but NOT Pending Topics
- Add: coordinator sees all four section headers

**System test updates** (`course_tab_persistence_test.rb`):
- Remove or rewrite the test that clicks "To Review" tab

**New unit test** (`test/presenters/overview_presenter_test.rb`):
- Test `show_*?` for each role (coordinator, lecturer, student)
- Test `any_sections?` with various data combinations

---

## 13. Overview tab states — Project Details banner + My Submission (2026-09-06)

Extends §12's `OverviewPresenter` to own the Project Details card's three states
(filled banner / empty-coordinator add-CTA / empty-readonly) and a new
student-only **My Submission** section with six states. Relocates the
`7 SCENE.svg` illustration out of `ProPro_Design/` and inline markup into `app/assets/`.

The hardcoded mockup is `ProPro_Design/course_show.html.erb` (committed
`255c0857`); the artwork is `ProPro_Design/SVG/7 SCENE.svg`. All identifiers
re-verified below against `refactor/design` tip (`dab3976a`).

### 13.1 Decision log

| # | Decision | Rationale |
|---|----------|-----------|
| E1 | **Drop the "Review queue" nudge card** (mockup `:933-955`). | It references sections "moved to the **To Review** tab", but no To Review tab exists (4 tabs: Overview/Topics/People/Groups — §12). The four sections are already *inline on Overview* (`_overview_tab.html.erb`), the only home they have. The card is a product-density call that would mean *removing* working sections, not adding a card — out of scope. |
| E2 | **Browse-groups CTA → `course_project_groups_path(@course)`**, *not* the course tab. | Two independent reasons the plan's `course_path(@course, tab: "groups")` is broken: (1) `ApplicationHelper#current_tab_index` reads only the persisted cookie, never `params[:tab]`, so `?tab=` is a **no-op** for landing (`application_helper.rb:9-11`, `tabs_controller.js` trusts server-rendered state, never reads a param); (2) the course Groups tab (`_groups_tab.html.erb`) is a coordinator-facing group/student table, not where students browse/join. The student-facing destination exists: `ProjectGroupsController#index` (`course_project_groups_path`), which lists confirmed groups, the current user's group, and `@ungrouped_students`, and whose sibling `create` action is how a student actually joins/creates a group (`routes.rb:81`). **Note:** the grouping feature is not shipped to `main` yet — groups today only arrive pre-formed via CSV/Moodle import — so the `:no_group` state is additionally gated on `@course.grouping_enabled?` to keep this CTA reachable (see the `submission_state_for` guard in §13.4); otherwise a group-less student in a grouped-but-not-live course would 403 on `ProjectGroupsController#index` (`authorize :grouping?` requires `grouping_enabled?` for non-coordinators). Since `grouped?` and `grouping_enabled?` are independent columns (`course.rb:37,74-81`), this guard is necessary. |
| E3 | **Update `course_tabs_test.rb`** — it is stale vs `refactor/design`. | It asserts a "To Review" tab (deleted in §12), a text "Settings" link (now `aria-hidden` icon span, `show.html.erb:46-52`), and `visit course_path(@course, tab: 'to_review')` (param never worked — E2). Run in the same PR as the new system coverage; otherwise it fails. |
| E4 | **My Submission rows keep the `more_vert`** from `shared/_row_item`. | The mockup rows have no overflow button, but `_row_item` hardcodes it (`shared/_row_item.html.erb:74-77`). User chose to accept rather than add a suppress-local this pass. |
| E5 | **Illustration as a real asset via `image_tag`**, not inline DOM. | The SVG's internal `<style>` classes are a fixed, self-contained palette (`7 SCENE.svg:5-42`) never meant to track the app theme — no need for inline-DOM CSS access. Gets Propshaft fingerprinting/caching. |
| E6 | **Extract Project Details into `_project_details_card` partial.** | Three visual states + illustration ≈ one render call; consistent with `_topic_card` / `_proposal_list_item` each being a self-contained visual unit. |

### 13.2 Illustration — relocate + extract

`7 SCENE.svg` is a checked-in design reference (`ProPro_Design/`); nothing in
`app/` points at it, and the other nine `SCENE.svg` files stay put. Move it
like a real asset (including its WSL download-marker):

```bash
mkdir -p app/assets/images/illustrations
git mv "ProPro_Design/SVG/7 SCENE.svg" app/assets/images/illustrations/project_details_banner.svg
git rm "ProPro_Design/SVG/7 SCENE.svg:Zone.Identifier"
```

Only the `#7` file moves; promote the others one at a time as they get wired
into real views. Render (only in the filled state):

```erb
<%= image_tag "illustrations/project_details_banner.svg",
      class: "absolute right-[-70px] bottom-[-70px] h-[260px] w-auto pointer-events-none select-none",
      alt: "" %>
```

### 13.3 OverviewPresenter extension

`app/presenters/overview_presenter.rb` — extend, do **not** fork into role
partials (D4 pattern). Logging `@submission_state` is a symbol
(`:no_group/:no_proposal/:pending/:approved/:redo/:rejected`), resolved by the
controller (§13.4), so the presenter stays a pure view object that never
re-derives state:

```diff
 class OverviewPresenter
-  attr_reader :pending_proposals, :reviewed_proposals, :pending_topics
+  attr_reader :pending_proposals, :reviewed_proposals, :pending_topics, :submission

-  def initialize(enrolment:, approved_projects:, pending_proposals:, reviewed_proposals:, pending_topics:)
+  def initialize(enrolment:, approved_projects:, pending_proposals:, reviewed_proposals:, pending_topics:,
+                 course_description:, file_link:, submission_state:, submission:)
     @enrolment = enrolment
     @approved_projects = approved_projects
     @pending_proposals = pending_proposals
     @reviewed_proposals = reviewed_proposals
     @pending_topics = pending_topics
+    @course_description = course_description
+    @file_link = file_link
+    @submission_state = submission_state
+    @submission = submission
   end

   def show_supervised_projects? = !student?
   def show_pending_proposals?    = !student?
   def show_reviewed_proposals?   = !student?
   def show_pending_topics?       = coordinator?

   def supervised_projects = @approved_projects

+  # Project Details — three states
+  # Filled when EITHER description or file_link is present (matches the mockup:
+  # "there's nothing here at all" only when BOTH are blank).
+  def project_details_empty?         = @course_description.blank? && @file_link.blank?
+  def show_project_details_add_cta?  = coordinator? && project_details_empty?
+
+  # My Submission — students only
+  def show_my_submission? = student?
+  def submission_state    = @submission_state
   ...
```

### 13.4 Controller changes (`CoursesController#show`)

The controller already computes `@group`, `@project`, `@current_status`
(`courses_controller.rb:37-46,62`) just above the presenter build (`:89-95`).
Reuse them via a new private helper instead of re-deriving in the presenter:

```diff
     @presenter = OverviewPresenter.new(
       enrolment: @current_user_enrolment,
       approved_projects: @approved_projects,
       pending_proposals: @pending_proposals,
       reviewed_proposals: @reviewed_proposals,
-      pending_topics: @pending_topics
+      pending_topics: @pending_topics,
+      course_description: @description,
+      file_link: @course.file_link,
+      submission_state: submission_state_for(@current_user_enrolment),
+      submission: @project
     )
```

New private method with the other small helpers at the bottom:

```ruby
# :no_group only applies to grouped courses where self-grouping is live
# (@course.grouped? && @course.grouping_enabled?) — in an ungrouped course a
# student submits individually with no group step, so @group being nil there is
# expected, not an empty state. The grouping_enabled? guard also keeps the
# "Browse groups" CTA out of reach of students who could not actually open the
# page: ProjectGroupsController#index authorizes with CoursePolicy#grouping?,
# which requires grouping_enabled? == true for a non-coordinator. A grouped
# course with self-grouping disabled (groups arrive only via CSV/Moodle import
# coordinated by staff) would otherwise render the CTA and let a student hit a
# Pundit::NotAuthorizedError (redirect to root with alert). In that state a
# group-less student instead gets the plain :no_proposal copy below.
def submission_state_for(enrolment)
  return nil unless enrolment&.student?

  if @course.grouped? && @course.grouping_enabled? && @group.nil?
    :no_group
  elsif @project.nil? || @current_status == 'not_submitted'
    :no_proposal
  else
    @current_status.to_sym
  end
end
```

`@current_status` already normalizes to `'not_submitted'` when there is no
project instance (`courses_controller.rb:62`), so the `:no_proposal` branch is
the single guard that covers both "no project row" and "project with no
submitted instance".

### 13.5 Project Details — new `_project_details_card.html.erb`

`_overview_tab.html.erb` replaces the `#proposal-guidelines` block (lines
13–31) with:

```erb
<%= render "courses/project_details_card" %>
```

The new partial holds `#proposal-guidelines` (kept so any CSS/JS anchoring on
the id is preserved) and branches on the presenter:

1. **Filled** — the classroom-banner treatment: gradient header
   (`linear-gradient(135deg,#D3E3FD 0%,#E8F0FE 100%)`), "Project Details"
   title + course name, `@description` paragraph, the optional file pill
   (`folder_zip` + `File.basename(URI.parse(@course.file_link).path ...)`),
   and the illustration image (E5). Rendered when `!project_details_empty?`
   (either field present).
2. **Empty + coordinator** — dashed border, inline doc icon (scale/convention
   of the app's other inline `<svg>` icons, not extracted), "No project
   details yet", and an **Add details** CTA → `settings_course_path(@course)`
   (matches the existing coordinator Settings link authorization,
   `CoursePolicy#update?`).
3. **Empty + everyone else** — read-only dashed "No project details published
   yet" copy, no CTA.

The plan's original inline empty-state SVGs use solid hex throws directly —
fine, they're small self-contained icons (E5 is specifically about the large
scene illustration).

### 13.6 My Submission — new section + `_my_submission_empty_state`

Add to `_overview_tab.html.erb`, **after** the filled/empty Project Details
section and **outside** the `collapsible-sections` div (single-item section;
not collapsible). Uses the same header styling as `_section_header` but is
*none* of its two controller modes (static header, like the mockup's
`#my-submission-header` template `:1083-1087`):

```erb
<% if @presenter.show_my_submission? %>
  <div class="mb-12" id="my-submission">
    <div class="flex flex-row items-center justify-between border-b border-[#E0E0E0] p-6 -mx-6">
      <h2 class="text-[22px] font-normal text-[#202124]">My Submission</h2>
    </div>
    <% case @presenter.submission_state %>
    <% when :no_group %>
      <%= render "courses/my_submission_empty_state",
            icon: "group_add",
            heading: "You're not in a group yet",
            description: "Join or create a group before you can put together a project proposal.",
            cta_label: "Browse groups",
            cta_path: course_project_groups_path(@course) %>   <%# E2 %>
    <% when :no_proposal %>
      <%= render "courses/my_submission_empty_state",
            icon: "note_add",
            heading: "No proposal submitted yet",
            description: "Your group hasn't submitted a project proposal. Once it's in, you'll see its review status here.",
            cta_label: "Create proposal",
            cta_path: new_course_project_path(@course) %>
    <% else %>
      <% icon, verb =
           case @presenter.submission_state
           when :approved then ["assignment_turned_in", "Updated"]
           when :pending  then ["assignment", "Submitted"]
           when :redo     then ["history", "Returned"]
           when :rejected then ["block", "Rejected"]
           end %>
      <%= render "shared/row_item",
            path: course_project_path(@course, @presenter.submission),
            icon: icon,
            title: @presenter.submission.current_title,
            meta_parts: [@presenter.submission.owner_name],
            time_meta: "#{verb} #{time_ago_in_words(@presenter.submission.current_instance&.updated_at || @presenter.submission.updated_at)} ago",
            status: @presenter.submission_state do %>
        <% if @presenter.submission_state == :redo %>
          <div class="mt-2 pt-2 pl-13 border-t border-dashed border-[#E0E0E0]">
            <p class="text-[13px] text-[#5F6368] pl-13">Your coordinator asked for changes — open the proposal to see their comments and resubmit.</p>
          </div>
        <% end %>
      <% end %>
    <% end %>
  </div>
<% end %>
```

**Notes:**
- `owner_name` is `Project#owner_name` (`project.rb:61-69`) — group name for a
  grouped project, student name for a solo one — which is exactly the mockup's
  "Group 4" / student-name meta.
- Uses `_row_item` directly (not `_proposal_list_item`): the redo state needs
  the extra note line, which `_row_item` already supports via its block
  (`yield`, `_row_item.html.erb:82`), while `_proposal_list_item` forwards no
  block (`_proposal_list_item.html.erb:10-16`). The icon/verb `case` is
  duplicated locally rather than adding block-forwarding to
  `_proposal_list_item` for one caller (E4 also accepted the shared more_vert).
- The `case` assigns icon/verb in the empty-branch when the state is none of
  the four (defensive; the controller guarantees only the six values).
- **`border_top`:** `_row_item` defaults `border_top: true`; the My Submission
  header already supplies its own bottom border and the wrapper is a
  `border-b` container, so the first row would show a doubled seam. Omit the
  `border_top:` param concern by rendering the header border + section border
  exactly as in `_overview_tab`'s other sections — confirm visually, pass
  `border_top: false` on row_item if a 2px seam appears.

### 13.7 Reused components (no new work)

| Need | Component | Evidence |
|---|---|---|
| Status pill palette | `shared/_row_item:8-15` | approved green / pending blue / redo amber / rejected red — byte-for-byte the mockup palette |
| Icon/verb mapping | duplicated `case` (§13.6) | already exists once in `_proposal_list_item:1-8`; not extracted until a 3rd call site |
| Full project card | `_project_card` / `_project_card_contents` | **not used** — bigger unit for grids; My Submission is the compact row |

### 13.8 Dead code cleanup

`app/views/courses/_project_details_tab.html.erb` and
`app/views/courses/_project_status_bar.html.erb` are both **zero-reference**
(every `render`/reference greps empty under `app/`). The status bar was the
pre-redesign My Submission stepper (§ plan §1b). Delete both here; call out
separately in the commit message.

### 13.9 Naming / route reference

| Thing | Name |
|---|---|
| Illustration asset | `app/assets/images/illustrations/project_details_banner.svg` |
| Presenter methods | `project_details_empty?`, `show_project_details_add_cta?`, `show_my_submission?`, `submission_state`, `submission` |
| Controller helper | `CoursesController#submission_state_for` |
| New partials | `courses/_project_details_card`, `courses/_my_submission_empty_state` |
| `submission_state` values | `:no_group` (only when `grouped? && grouping_enabled?`), `:no_proposal`, `:pending`, `:approved`, `:redo`, `:rejected` |
| Add-details CTA | `settings_course_path(@course)` |
| Create-proposal CTA | `new_course_project_path(@course)` |
| Browse-groups CTA | `course_project_groups_path(@course)` — **the correct student destination (E2)** |
| Dead code deleted | `courses/_project_details_tab.html.erb`, `courses/_project_status_bar.html.erb` |

### 13.10 Tests

**New presenter unit test** `test/presenters/overview_presenter_test.rb` (plain
unit, no browser):
- `project_details_empty?` true only when description **and** file_link blank
- `show_project_details_add_cta?` true only for coordinator + empty
- `show_my_submission?` true only for student
- `submission_state` passthrough

**Fix stale system test** (E3) `test/system/courses/course_tabs_test.rb`; then
**extend / add** `test/system/courses/overview_tab_test.rb`:
- Coordinator, no description/file_link → "Add details" CTA visible, links to `settings_course_path`
- Student, no description/file_link → read-only empty state, **no** CTA
- Coordinator or student with description/file_link → banner + illustration render
- Student, grouped + grouping enabled, no group → "Browse groups" empty state → lands on `course_project_groups_path`
- Student, grouped but grouping disabled, no group → **no** "Browse groups" CTA (falls through to create-proposal copy)
- Student, grouped, in group, no project → "Create proposal" empty state
- Student with pending/approved/redo/rejected project → correct row + pill; redo shows the extra note
- Lecturer/coordinator → My Submission section absent entirely
- Lecturer/coordinator → banner empty state shows read-only variant (no CTA) when coordinator absent

### 13.11 Build order

```
illustration move → presenter extension → controller helper → project_details_card
→ my_submission section + empty-state partial → dead-code deletion → test fixes/new
```

The presenter + controller changes must land before the partials (partials read
`@presenter`). Dead-code deletion is independent and last.

### 13.12 Responsiveness

Scope and rules for the Project Details card, My Submission section, and banner
illustration across the app's existing breakpoints. Grounded in the mockup
(`ProPro_Design/course_show.html.erb` v5).

**Target viewports (manual verification):** 360 · 640 · 768 · 1024 · 1245 · 1440.

**Breakpoint philosophy:** reuse the existing breakpoint set only — `sm` (640,
the mockup's stack point), `lg` (1024, sidebar turns static), and the existing
chrome-independent `min-[1245px]`. No new arbitrary breakpoints for this feature.

**Golden rule — no horizontal scroll at any width, ever.** Guaranteed by three
mechanisms:

1. Card-level `overflow-hidden` on the banner header clips the illustration's
   `-70px` bleed (already in the mockup; must be in `_project_details_card`).
2. `max-w-[800px] mx-auto` caps the Overview column inside the shared
   `max-w-5xl mx-auto px-6 py-8` panel.
3. The file-link chip truncates its filename (below) instead of growing the chip.

**Column width — enforce the long-promised cap.** `_overview_tab.html.erb`'s
header comment and CONTEXT.md both say "`max-w-[800px]` centered column", but
today the only cap is the shared `max-w-5xl` panel. Add `max-w-[800px] mx-auto`
at the Overview tab's root (its wrapper partial gets the class; the shared panel
markup in `courses/show` is untouched). Other tabs keep `max-w-5xl`.

**Filled banner — all widths:**

- **Illustration: fixed crop, no responsive swap.** Always
  `class="absolute right-[-70px] bottom-[-70px] h-[260px] w-auto pointer-events-none select-none"`;
  never hidden, never scaled. The card's `overflow-hidden` does the cropping at
  every width ("just crop it, do not scroll ever").
- Header: `relative px-8 py-9 overflow-hidden`, gradient background (mockup).
- Title/subtitle: keep `max-w-[62%]`, left-aligned, `relative z-10` (sits above
  the art), at every width — `text-2xl font-medium` title + `text-[14px]`
  subtitle.
- Body (`p-6`, `--color-surface-tint`): description
  `text-[0.9rem] sm:text-[1rem] leading-[1.5] break-words` (the mockup's only
  `sm:` usage).
- **File-link chip (fixes a latent overflow defect):** current code
  (`_overview_tab.html.erb:19-28`) is `w-fit max-w-max` with an untruncated
  filename span — a long name grows the chip past the card. New partial: cap the
  chip at card width (`max-w-full`) and give the filename span `min-w-0 truncate`
  (single-line ellipsis). With this, no filename can push the card wider.

**Empty states — stack below `sm`, uniform padding:**

- Layout: `flex flex-col sm:flex-row items-center gap-6` with
  `text-center sm:text-left` (mockup). Below 640 everything stacks and centers.
- Paddings uniform at all widths: card states (coordinator add-CTA, readonly)
  `p-8`; My Submission states (`:no_group`, `:no_proposal`) `py-14 px-6`. No
  per-breakpoint tightening.
- Icons `shrink-0` (96 / 72 / 48px) — never squeezed by narrow widths.
- CTA pills stay `inline-flex px-5 py-2 rounded-full`; the stacked column
  centers them below `sm`. Not full-width.

**My Submission rows (pending / approved / redo / rejected):** `shared/_row_item`
unchanged — title truncates, meta wraps below `sm`, pill + `more_vert` stay
`shrink-0`. The redo note (block below the row) is wrapped text; no action.

**Chrome relationships:**

- Settings gear already relocates to the mobile header below `sm` (existing;
  untouched).
- `lg` (1024): sidebar turns static; verify the 800px column + banner visually
  at this width.
- `min-[1245px]`: only affects projects/topics `show` (comments drawer /
  review cards); nothing Overview-specific, verify only.

**Solo-supervisor card:** already `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3` —
no change.

**Automated fixed-width coverage (§13.10 extension):** add one narrow smoke case
to `overview_tab_test.rb` following the existing `MobileOverflowTest` pattern
(`test/system/projects/mobile_overflow_test.rb`):

- `driven_by :selenium, using: :headless_chrome, screen_size: [390, 844]` and
  `self.use_transactional_tests = false` (rack_test cannot resize the viewport
  or measure `scrollWidth`; real-browser tests must share committed records).
- Assert: (1) filled banner produces no horizontal overflow
  (`documentElement.scrollWidth <= documentElement.clientWidth`); (2) the
  illustration `img` is present; (3) one empty state stacks with its CTA; (4)
  one My Submission row renders with its status pill.
- The remaining widths/states are the manual dev-server pass at
  360 · 640 · 768 · 1024 · 1245 · 1440.
