# ProPro Redesign — Topics-by-Supervisor ("Grouped Topic Approval") Refactor Plan

Grounded against `hackerspacemmu/ProPro` @ `refactor/design` (current HEAD at
audit time) and the hardcoded mockup supplied alongside this doc (course
named "Grouped Topic Approval Enabled" in the sidebar/breadcrumb — that's the
seed-data course name used to test this feature, not a real setting).
File:line references below are verified against the actual branch, not
recalled from memory — re-verify against HEAD before building, since other
branches move fast.

**In scope:** wiring the mockup's per-supervisor topic list (search bar,
supervisor filter, per-supervisor collapsible groups, per-topic row) into a
real controller/view, without regressing `TopicPolicy` visibility rules.
**Out of scope:** the mockup's top chrome (header/sidebar/tab bar) — see §1,
this is stale scaffolding, not a spec. Redoing Overview, People, or Groups
tab content (already handled by `docs/courses_overview_refactor_plan.md`,
`docs/people_tab_refactor_plan.md`).

**This doc ships one open Decision Point (§6) rather than silently picking
one.** §3 (which file this targets) was originally a second open decision
but is resolved below — an earlier recommendation there was wrong and is
corrected in place, with the reasoning kept visible rather than edited
away. Resolve §6 — ideally as a short ADR, per this repo's convention
(`docs/adr/000N-*.md`) — before a ticket touches any file listed in §10.

---

## 0. Decisions agreed (grill-me interview, 2026-09-06)

Supersedes anything below that contradicts it. Where a section below still
says otherwise, this log wins; stale text is kept for the record (this doc's
habit — same as §3's kept correction). Recorded long-form in **ADR 0013**
(target/architecture) and **ADR 0014** (Available badge + page-local wiring).

**Purpose & audience.** All three roles equally, and the primary problem is
*browse*, not review: students finding topics to propose to, other lecturers
browsing topics, coordinators reviewing every status. Mockup fidelity is a
goal; `TopicPolicy::Scope` subsets (§2) still apply per role.

**Hard constraint (scope).** This pass touches only the Topics tab's content
(`_topic_directory_tab.html.erb` + its partials). The 4-tab bar in
`courses/show.html.erb`, `tabs_controller.js`, and every other tab are off
limits. The mockup's "Overview active + To Review" tab strip is stale (§1) —
not built.

**Scoping.** `TopicPolicy::Scope` remains the only gate (§8). The
`student_access` / `lecturer_access` settings are **not** consulted for topic
visibility here (they aren't today either — `TopicPolicy::Scope` branches only
on enrolment role); they keep governing `ProjectPolicy`/lecturer-profile views
exactly as unchanged. Deliberate, documented for future readers who expect
those settings to matter on this page.

**Available pill — REPLACES the status pill on this page (final; §6 records
the option history).** On Topics Directory rows only, an approved topic with
no claims (`Topic#available?` = `approved? && proposed_project_instances.none?`)
renders a green "Available" pill *in place of* its "Approved" pill; every
other row keeps its real status pill. Always green — the mockup's two blue
"(You)"-group pills are an authorial artifact, not reproduced. Implementation
stays additive: `_row_item`'s `pill_label` local already exists and approved
already colors green, so `_topic_card` merely gains an optional
`available_pill:` local (default false); `_row_item` needs no pill change.
Display-only, zero migration (ADR 0014).

**Layout (mockup-faithful).**
- Stacked action bar: `+ Create` top-left (the only Create door into topic
  creation — `topics/index.html.erb` has none), full-width search pill
  ("Search supervisors or topics"), then "Topic filter" M3-outlined select
  (mockup's label/copy: "Topic filter" / "All topics" default, populated with
  supervisor names) + "Collapse all". Mockup's visual style; `_groups_tab`'s
  htmx mechanics (§7).
- Supervisor groups with an A→Z order and newest-first rows inside each
  group. The current user's own group is **pinned first** with a gray "(You)"
  suffix, staff (lecturer/coordinator) only, pinned even at count 0 — this
  replaces the old "My Topics" section. Students browsing see plain A→Z, no
  pinned group.
- Zero-topic supervisors render a header with "0" (mockup's Kevin row). During
  an active search/filter, non-matching groups vanish.
- Row meta line drops the redundant owner-name segment via a new optional
  `hide_owner:` local on `_topic_card` (default false); time reads "Updated X
  ago" (unchanged). `_row_item` gets a small separator fix so an empty
  `meta_parts` renders no leading "•" (safe today — no caller passes empty
  meta_parts + time_meta).
- Collapse via `expandable_rows_controller.js` (needs the small generalizing
  pass in §11). The `/` shortcut is **not** wired to Topics at all.
- No supervisor-capacity figures in headers (name + count only).
- `require_coordinator_approval?` copy is **dropped** from this tab (the
  setting itself is untouched elsewhere — it only stops rendering here).

**Responsive (style-guide rule added to `ProPro_Design/style_guide.html.erb`
§24).** Mobile: `+ Create` left-aligned; search full-width; filter
full-width; **Collapse-all is always centered on mobile**. Supervisor names
truncate on narrow screens. Rows stay the app's one-line `_row_item`. Content
stays in the real tab-panel column (`max-w-5xl` from `show.html.erb`) — no
800px override (matches R4).

**Pagination.** None on this tab for now (few supervisors per course) — the
`participants_pagination_threshold` "show all" story is a flagged future
follow-up (ADR 0013), not built this pass.

---

## 1. Ground truth — the mockup, and what to discard from it

The mockup renders:

- The standard app chrome: left sidebar (Home / enrolled courses / Edit
  profile), top header (ProPro breadcrumb, template/settings icons, Log out).
- A 5-item tab strip: **Overview** (rendered as the *active* tab —
  `bg-[#e9eef6] text-[#0b57d0]`), **To Review**, **Topics**, **People**,
  **Groups**.
- Below that: a search bar ("Search supervisors or topics"), a "Topic
  filter" dropdown (currently only option: "All topics"), and a "Collapse
  all" button.
- A flat sequence of supervisor blocks, each: supervisor name + topic count
  + chevron, then (if count > 0) a list of topic rows — icon, title, a
  `owner`/course-context meta line, "Proposed N [time] ago", and a green
  **"Available"** pill + `more_vert` button.

**Two things in this mockup are stale scaffolding, not requirements — do not
build them:**

1. **The active tab is "Overview," and there's a "To Review" tab.** This
   mockup was almost certainly hand-edited from an existing full-page HTML
   export (the same shell `courses/show.html.erb` produces) and the tab
   state was never updated to match the new body content. Two independent
   pieces of evidence:
   - `courses/show.html.erb:9-12` (current branch) defines exactly **four**
     tabs — `overview`, `topics`, `people`, `groups`. There is no `to_review`
     slug anywhere in routes, controllers, or views.
   - `docs/courses_overview_refactor_plan.md` §"In scope" explicitly lists
     **"removing the To Review tab (D1)"** as an already-completed decision
     for this branch. Building a "To Review" tab now would be reintroducing
     something a prior pass on this exact branch deliberately removed.
   - Treat the tab strip as: reuse the real 4-tab bar from
     `courses/show.html.erb` verbatim, with **Topics** as the active tab.
     Do not add a 5th tab.

2. **The "Available" pill isn't a real status.** See Decision Point 2 (§6) —
   `Topic#status` only has four values that ever reach the UI:
   `approved` / `pending` / `redo` / `rejected` (`not_submitted` exists on
   the enum but is excluded from every rendering call site checked). There
   is no `available` state on the model.

What *is* real and worth preserving from the mockup: grouping by supervisor,
the search-by-topic-title-or-supervisor-name behavior, the supervisor
filter, and per-group collapse. Those map cleanly onto existing patterns —
see §7.

---

## 2. Where "grouped by supervisor" data already flows from

- `Topic` (`app/models/topic.rb`) — `self.table_name = 'projects'`,
  `enum :status, { pending: 0, approved: 1, rejected: 2, redo: 3, not_submitted: 4 }`.
  `owner` is polymorphic (a `User` for lecturer-owned topics here, since
  `Topic` forces `ownership_type: :lecturer`). `owner_name` returns the
  lecturer's name — this is your "supervisor name" for grouping.
- `TopicPolicy::Scope#resolve` (`app/policies/topic_policy.rb`) is the
  **only** correct entry point for "all topics a given user may see in this
  course." It branches on the viewer's enrolment role:
  - `coordinator` → `scope.all` (every topic, every status, every owner —
    this is the only role for whom a "browse every supervisor's topics,
    including pending/redo" view is meaningful).
  - `lecturer` → own topics (any status) **or** anyone's approved topics.
  - anyone else (student, or no enrolment) → approved topics only.
- `Course#lecturers` (`app/models/course.rb:10`) — the supervisor list for
  a filter dropdown; already used verbatim by `_groups_tab.html.erb`'s
  `lecturer-filter` `<select>`.
- Status colors/labels: `ApplicationHelper#status_badge_classes` (4 cases +
  gray fallback) and `shared/_row_item.html.erb`'s own `pill_bg`/`pill_fg`
  case statement (4 cases + gray fallback) — two different color palettes
  for the same 4 statuses, used in different places. Don't introduce a
  third.

---

## 3. Decision Point 1 — which file does this redesign actually target?

**Correction (post-review): an earlier draft of this doc recommended
targeting the standalone `topics/index.html.erb` page and adding a 4-tab
bar to it. That recommendation was wrong and has been replaced below — see
the "Why the standalone-page option is out" callout for the reasoning, kept
here so the mistake and its fix are both on the record.**

`app/javascript/controllers/tabs_controller.js` is what actually drives
Overview/Topics/People/Groups today, and it is **pure client-side state**:
`connect()`/`show()` just toggle a `.hidden` class across `panelTargets`
that are already rendered in the same page load — there is no navigation
involved. The file's own comment documents the one place this app already
needed a tab-bar entry that *does* navigate — Settings — and it's a plain
`link_to`, explicitly called out as **not** participating in this
controller: *"it doesn't participate in this controller at all."*

That means a "Topics tab" that's actually a separate route
(`topics/index.html.erb` via `course_topics_path`) can't be one of the four
instant-toggle tabs — it would have to be a second Settings-style
navigation link, which breaks the one thing tabs are for: switching between
Overview/Topics/People/Groups without a page reload. Building full tab
chrome onto a page that can only be *reached by leaving the tab bar* would
look like a tab and behave like a navigation, which is worse than either
being consistent.

**The actual fix: `_topic_directory_tab.html.erb` should become the full
view (search, filter, grouped-by-supervisor, collapse) — not stay a
lightweight preview with a "View All Topics" escape hatch.** There's
already precedent for this inside the same file: `_groups_tab.html.erb` and
`_people_tab.html.erb` are not previews — they're full searchable,
filterable, htmx-driven panels, and they live directly inside the
instant-toggle tab system as ordinary `data-tabs-target="panel"` elements.
Topics should follow that pattern, not a different one. This also explains
the mockup's chrome: it shows the *full* sidebar/header/tab-bar shell not
because that's stale scaffolding to strip away (item 1's "To Review"/active-
tab mismatch is still stale, per below), but because this content is
genuinely meant to render inside `courses/show`, the same as Groups/People.

**`topics/index.html.erb` / `TopicsController#index` stays out of scope,
untouched.** It isn't dead weight competing for the same job — it has
independent callers unrelated to the course-show tab: `course_topics_path`
is also linked from `app/views/projects/index.html.erb` (a topic search
form) and `app/views/topics/new.html.erb` (browse/reference-topic flows).
Those are "pick or reference a topic" contexts, not "coordinator reviews
every supervisor's queue" contexts — its simpler flat search UI suits them
fine as-is, and grafting the supervisor-grouped coordinator view onto it
would be solving a problem neither of those call sites has.

**Practical consequence for every section below:** wherever this doc
previously said "the target controller," read `CoursesController#show` —
it already has the exact `if params[:section] == 'groups' / elsif … 'topics' / else`-shaped
`HX-Request` branch this needs (currently branches on `groups` vs.
default-students; add a third branch), and it already calls
`authorize @course` at the top (`courses_controller.rb:12`) — nothing new
to add there. See §9 for the concrete shape.

---

## 4. Query / Data Audit

| Need | Status | Evidence |
|---|---|---|
| All topics visible to current viewer | ✅ exists | `TopicPolicy::Scope#resolve`; already consumed as `@topic_list` in `courses_controller.rb` (`policy_scope(@course.topics, policy_scope_class: TopicPolicy::Scope)`) |
| Group topics by supervisor | ⚠️ needs a `group_by(&:owner)` or `.owner_name` grouping step — not currently done anywhere | n/a |
| Supervisor list for filter dropdown | ✅ exists | `Course#lecturers` (`course.rb:10`), reused pattern in `_groups_tab.html.erb:44-54` |
| Search topic title (flat, non-htmx — different page, see §3) | ✅ pattern exists on `topics/index.html.erb`'s own page, out of scope | `TopicsController#index` (`topics_controller.rb:5-19`) does an in-Ruby `.select` over `topic_instances… .title` — a different, unrelated page (§3); don't copy its htmx-free approach, copy `search_students` instead |
| Search topic **or supervisor name**, htmx-driven | ⚠️ nearest analog is `search_students`/`search_groups` (`courses_controller.rb`, private) — same shape, different model | needs a `search_topics(topic_list, query)` written to match, added to `CoursesController` (§3) |
| Supervisor filter (as opposed to lecturer-filters-groups-by-supervision) | ⚠️ conceptually different from `supervised_owner_ids` (which filters *students/groups* by who supervises their project) — here the filter's target *is* the supervisor grouping key, not a side attribute | needs new helper, see §7 |
| Row rendering (icon, title, meta, status pill) | ✅ fully built | `shared/_row_item.html.erb`, wrapped by `shared/_row_list.html.erb`, called from `courses/_topic_card.html.erb` |
| Per-group collapse that survives an htmx swap | ✅ pattern exists, wrong controller currently attached to the wrong feature | `expandable_rows_controller.js` — delegated listeners + `data-row-id`/`data-detail-row-id`, explicitly documented as "generic — does not reference the groups table by name," built exactly for htmx-swapped content |
| Pagination threshold ("show all" / first N) | ✅ exists | `Rails.application.config.participants_pagination_threshold`, used in `courses_controller.rb` for `@filtered_group_list`/`@filtered_student_list` |

---

## 5. What's already correct — do not rebuild

Per this repo's own glossary (`CONTEXT.md`, "row item" entry): *"Topics
render as row items (not colored cards) at every `_topic_card` call site."*
That work is done and should be reused, not re-implemented:

- `shared/_row_item.html.erb` — icon avatar, title, meta line, status pill.
  Exactly matches the mockup's per-topic row shape (icon, title, meta,
  pill, `more_vert`).
- `shared/_row_list.html.erb` — the wrapper that maps a collection through a
  partial with consistent borders. Use this for each supervisor's topic
  list, same as every other list in the app.
- `courses/_topic_card.html.erb` — already computes `path`/`linkable` via
  `policy(topic).show?` and passes `status: topic.status.to_s.downcase`
  straight into `_row_item`. **Do not fork this partial** to special-case
  the grouped view; if it needs a new local (e.g. to suppress the meta
  line's owner name since the owner is now the group header), add an
  optional local with a sane default, the same way `_topic_card.html.erb`
  already handles the optional `lecturer:` local.
- `ApplicationHelper#status_badge_classes` / `_row_item`'s own pill
  case statement — the color mapping for pending/redo/rejected/approved.
  Do not add a parallel color scheme for "Available."

---

## 6. Decision Point 2 — the "Available" pill

**AMENDED by §0 (interview, 2026-09-06): replace-when-available is the
choice — page-local.** Option history recorded here: Option A (drop the pill)
was the original recommendation, then Option B (a second, smaller badge next
to the status pill) was chosen during the interview, and the stakeholder's
final call is neither: on Topics Directory rows only, the pill *replaces* the
status pill when `Topic#available?` (`approved? && proposed_project_instances.none?`,
`topic.rb:15`) is true — green "Available" instead of "Approved". Non-available
rows keep their real status pill: approved-and-claimed keeps "Approved", and
in the pinned "(You)" group a lecturer's own pending/redo/rejected topics keep
their status pills (students never see those — they only ever see approved
topics on this page). Always green; the mockup's two blue "(You)" pills are an
authorial artifact, not reproduced. Implementation stays additive: `_row_item`'s
`pill_label` local already overrides the label and approved already colors the
pill/icon green, so `_topic_card` merely gains an optional `available_pill:`
local (default false) that passes `pill_label: "Available"` when true and
`topic.available?`. `_row_item` needs **no pill change at all** — its only
change is the meta-separator fix (empty `meta_parts` + `time_meta` renders no
leading "•"), needed because grouped rows pass `hide_owner:`. No enum change,
no migration; display-only, never an authorization check (ADR 004, ADR 0014).
The original "do not repurpose the `status` pill" caution below is superseded
for this one page: the swap reuses the pill language (same slot, same
approved-green palette), it does not relabel the pill on any other page.

`Topic#status` (`topic.rb`) is a hard 4-value enum
(`pending`/`approved`/`rejected`/`redo`, plus an unused-in-views
`not_submitted`). There is no `available` value, and adding one to this
enum would be a breaking migration touching every place `.status` is read
(mailers, CSV export, `SupervisorCapacityCalculator`, `TopicPolicy`). **Do
not add a status.** Two non-breaking readings of "available," pick one:

**Option A (recommended default) — drop the "Available" pill; show the
real status pill instead.** Every topic already carries one of the 4 real
statuses; `_row_item.html.erb` already renders it correctly with the right
color. This is strictly more informative to a coordinator doing topic
review (which pending/redo topics need attention vs. which are already
approved) than a pill that's hard-coded to say the same thing on every row.
Zero new code beyond what §5 already reuses.

**Option B — "Available" is a real, separate, computed idea: "approved AND
not yet claimed by a student/group."** `Topic` already has
`has_many :proposed_project_instances, class_name: 'ProjectInstance', foreign_key: 'source_topic_id'`
— populated when a student picks this topic from "Browse Topic Catalog"
(`projects/_topic_picker.html.erb` → `ProjectInstance#source_topic_id`). A
topic is "claimed" once at least one such instance exists. If this is
genuinely wanted:
- Add `Topic#claimed?` / `#available?` (`approved? && proposed_project_instances.none?`)
  as a plain model method — no migration.
- This is a **second, independent axis** from status (a `redo` topic can't
  be "available" either way; an `approved` topic can be available or
  claimed). Render it as a second, smaller badge next to the status pill,
  not a replacement for it — conflating the two into one pill loses
  information Option A already preserves for free.
- `_row_item.html.erb` currently renders exactly one pill; adding a second
  badge slot is a new, additive local (e.g. `secondary_badge:`), not a
  change to the existing `status`/`pill_label` contract — every other
  `_row_item` call site (proposals, projects) is unaffected as long as the
  new local defaults to `nil`.

Either way: **do not repurpose the `status` pill to display "Available"** —
that silently hides the real approval state from a page whose whole purpose
is reviewing approval state. **[Superseded for this one page by the final
decision above: Topics Directory rows swap the pill's *label* to "Available"
when `available?`, reusing the approved-green palette in the same slot — on
every other page the status pill is untouched.]**

---

## 7. Search + filter — mirror the participants-table htmx pattern

The Students/Groups sections on `courses/show.html.erb` already solve
"debounced search + dropdown filter + swap a container, gated by policy" —
mirror this exactly rather than inventing a second pattern:

**Reuse verbatim:**
- The `hx-get` / `hx-target="#…-container"` / `hx-swap="outerHTML"` /
  `hx-trigger="input changed delay:300ms"` / `hx-include="#…"` /
  `hx-vals='{"section": "…"}'` / `hx-indicator="#…-loading"` combination —
  see `_students_section.html.erb:11-21` and `_groups_tab.html.erb:14-24`.
- The `<select id="lecturer-filter" name="lecturer_filter">` markup from
  `_groups_tab.html.erb:44-54`, populated from `@course.lecturers` — this
  is your "Topic filter" (rename the mockup's placeholder "All topics"
  option set to supervisor names; the mockup's filter description says it
  filters supervisors, which is exactly what this select already does
  elsewhere).
- The `data-search-shortcut-target="input"` wiring so the existing `/`
  keyboard shortcut (`search_shortcut_controller.js`) can reach this input
  the same way it reaches Students/Groups search boxes — check whether
  Topics should become a new `fallbackInput` candidate or stay
  shortcut-only-when-active; either is a one-line addition, just don't
  silently skip it.

**Write new (small, same shape as existing private controller methods):**
- `search_topics(topic_list, query)` — mirror `search_students`
  (`courses_controller.rb`, private section): match on
  `topic.current_title.downcase.include?(query)` **or**
  `topic.owner_name.downcase.include?(query)`. Case-insensitive, matches
  the mockup's stated intent ("search through the topic title or the
  supervisor name") exactly.
- A supervisor-filter helper: given `params[:lecturer_filter]`, restrict
  the already-policy-scoped topic list to `topic.owner_id == filter_id`.
  This is simpler than `supervised_owner_ids` (which resolves *supervision
  of a project owner*, a different relationship) — don't reuse that method,
  write the direct one.
- A grouping step: `topic_list.group_by(&:owner)` (or `&:owner_name` if
  display-only), sorted by supervisor name, with zero-topic supervisors
  still listed (the mockup explicitly shows "Kevin Chong Wei Keong — 0" and
  "Raymond Lee Wei Kang — 1" with no rows rendered under it, so the
  supervisor list — probably `@course.lecturers`, not "lecturers who happen
  to have a topic" — must be the outer loop, with topics grouped in
  underneath, not the other way around).

**Collapse behavior — use `expandable_rows_controller.js`, not the
mockup's inline `onclick`.** The mockup's collapse is a raw
`onclick="…closest('.mb-3')…"` handler embedded per-row in HTML — this
repo's JS is 100% Stimulus (`app/javascript/controllers/`), and inline
`onclick` handlers don't exist anywhere else in the codebase; introducing
one here would be the one-off in an otherwise consistent architecture.
`expandable_rows_controller.js` was written generically for exactly this
shape (delegated listeners, `data-row-id` / `data-detail-row-id` pairing,
explicitly designed to survive an htmx-swapped container) — apply it to the
supervisor-group wrapper the same way it's applied to the Groups table's
member-list rows, plus reuse its `data-expandable-toggle-all` header button
for "Collapse all."

---

## 8. Policy & gates — non-negotiable

This is the part most likely to regress silently. Worth noting for the
record even though it's now out of scope per §3:
`TopicsController#index` (the separate, untouched page) has **no
`authorize` call at all** today — it relies solely on `policy_scope`. Don't
copy that gap into the code this doc does touch:

1. **Every topic list this feature renders must originate from
   `policy_scope(@course.topics, policy_scope_class: TopicPolicy::Scope)`
   (or `policy_scope(@course.topics)`, which resolves to the same
   `TopicPolicy::Scope` by convention — confirm at ticket-review time
   which form the target controller already uses and stay consistent with
   it).** Search, filter, and grouping are all steps applied *on top of*
   this scoped collection — never re-query `@course.topics` (or any raw
   association) directly for the search/filter/htmx-swap endpoint. This is
   the same shape as `filtered_student_list`/`filtered_group_list`, which
   both start from an already-policy-scoped `@student_list`/`@group_list`
   ivar and only ever narrow it (`courses_controller.rb`, private section)
   — copy that shape exactly for `filtered_topic_list`.
2. **`authorize @course` is already covered — verify it stays that way.**
   Since §3 puts this work in `CoursesController#show`, the existing
   `authorize @course` at the top of that action (`courses_controller.rb:12`,
   gated by `CoursePolicy#show?` → enrollment) already runs before the new
   `topics` section branch does. There's nothing to add here; there *is*
   something to protect: don't move the new topics logic into a
   `before_action` or helper that could run ahead of that `authorize` call,
   and don't add a second entry point (e.g. a standalone route for the
   htmx partial) that bypasses `#show` entirely. (For the record, not a
   request to fix elsewhere: `TopicsController#index`, the untouched page
   from §3, has this gap on both `main` and `refactor/design` — don't
   import that pattern here.)
3. **The supervisor filter must never become a way to see another
   supervisor's non-approved topics you weren't already scoped to see.**
   Filtering by `owner_id` happens *after* `TopicPolicy::Scope` has already
   removed anything the viewer can't see — a student filtering to "Faisal"
   still only sees Faisal's *approved* topics, because non-approved ones
   were never in the scoped collection to begin with. Write a test that
   asserts this directly (§11) — it's the one behavior that's easy to get
   right by accident today and wrong after a refactor.
4. **The row-level `linkable: policy(topic).show?` check inside
   `_topic_card.html.erb` stays untouched.** Even though the outer list is
   already scoped, this per-row policy check is what disables the link
   (rather than removing the row) for edge cases — keep it, per this
   branch's own precedent in `docs/adr/0004-policy-is-authoritative.md`:
   *"Do not invent view-level authorization… No new checks are added or
   removed."* That ADR is about a different controller but the principle —
   policy is authoritative, views render exactly what it permits — applies
   here too: if Option B's `claimed?` badge (§6) is added, it's a display
   concern only and must never be used as a substitute authorization check.
5. **Course-setting gates already used elsewhere on this page must keep
   working**: `@course.toggle_topics` (gates whether Topics content shows
   at all — currently checked in `_topic_directory_tab.html.erb:3`; note
   this is a *different* gate from `TopicsController`'s own
   `before_action :toggle_topics`, which belongs to the untouched page from
   §3 — don't confuse the two or assume one covers the other), and
   `@course.require_coordinator_approval?` (changes the copy shown to
   lecturers about what "pending" means). Neither should need new logic —
   just preserve both checks when rewriting the partial.

---

## 9. Target architecture (per §3's correction)

```
CoursesController#show                                  # existing action, extended
  authorize @course                                      # already exists — courses_controller.rb:12
  ...                                                     # existing ivars unchanged
  @topic_list = policy_scope(@course.topics, policy_scope_class: TopicPolicy::Scope)
                                                          # already exists — courses_controller.rb, "@topic_list ="
  @lecturers already exists (courses_controller.rb, "@lecturers = @course.lecturers")
                                                          # reuse as-is for the filter <select>

  @filtered_topic_list = filtered_topic_list             # NEW private method, §7 — same
                                                          # shape as filtered_student_list/
                                                          # filtered_group_list, starts from
                                                          # the already-scoped @topic_list
  @topics_by_supervisor = @course.lecturers
    .index_with { |l| @filtered_topic_list.select { |t| t.owner_id == l.id } }
                                                          # outer loop is @course.lecturers, not
                                                          # "lecturers who happen to have a topic" —
                                                          # §7's grouping note: 0-topic supervisors
                                                          # must still render a header row

  # existing HX-Request branch, extended with a third case:
  if params[:section] == 'groups'
    render partial: 'groups_table', ...                  # unchanged
  elsif params[:section] == 'topics'
    render partial: 'topics_by_supervisor_list',          # NEW partial, mirrors
           locals: { course: @course,                     # groups_table.html.erb /
                     topics_by_supervisor: @topics_by_supervisor, ... }
  else
    render partial: 'students_table', ...                 # unchanged
  end
```

- Reuse `Rails.application.config.participants_pagination_threshold` for a
  "show all" affordance if the supervisor count or per-supervisor topic
  count gets large — same UX as Students/Groups, don't invent a different
  pagination story for this one tab.
- No new tab bar to add — `topics` is already one of the four slugs in
  `courses/show.html.erb`'s existing `tabs` array; this work only changes
  what `_topic_directory_tab.html.erb` renders inside that already-wired
  panel.
- Empty states: no supervisors at all → existing "No topics are currently
  available." copy pattern; a supervisor with 0 topics (post-filter or
  otherwise) → render the header row with count "0" and no row-list body,
  exactly as the mockup already shows for "Kevin Chong Wei Keong."

---

## 10. Ticket List

**Ticket 0 — Decision Points 1 & 2 (§3, §6) — RESOLVED in ADR 0013 / ADR 0014
(see Decision Log §0).** No longer blocking.

**Ticket 1 — `filtered_topic_list` + `search_topics` + supervisor-filter
helper** on `CoursesController` (§3) (private methods, mirroring
`filtered_student_list`/`search_students` shape exactly). Unit-testable in
isolation from any view work.

**Ticket 2 — Grouping + view scaffold.** Supervisor header row (name, count,
chevron) + `shared/_row_list` per supervisor, reusing `courses/_topic_card`
unchanged (or with one new optional local per §5/§6-Option-B). No
search/filter/htmx yet — static render of `@topics_by_supervisor` to
de-risk the grouping/empty-state logic before adding interactivity.

**Ticket 3 — Search input + supervisor filter `<select>`, htmx-wired.**
Copy `_groups_tab.html.erb`'s search+filter block, retarget `hx-get`/
`hx-target` at a new `#topics-by-supervisor-container`, wire the new
`section: "topics"` case into `CoursesController#show`'s existing
`HX-Request` branch (§9).

**Ticket 4 — Collapse behavior via `expandable_rows_controller.js`.**
Generalize/reuse (don't fork) — apply `data-row-id`/`data-detail-row-id`
to supervisor header/body pairs, wire "Collapse all" through the
controller's existing `data-expandable-toggle-all` path.

**Ticket 5 — Policy/gate hardening (§8).** Verify `authorize @course` (already
present on `#show`) still runs ahead of the new branch, add a request spec
proving the supervisor filter can't leak non-approved topics across roles,
confirm `toggle_topics`/`require_coordinator_approval?` behavior is
untouched.

---

## 11. File Operations Summary (per §3's correction; §6 → Option B, page-local)

**New files:**
- `app/views/courses/_topics_by_supervisor_list.html.erb` — the
  htmx-swappable container (mirrors `_groups_table.html.erb`/
  `_students_table.html.erb`: it's the thing `hx-target`/`hx-swap="outerHTML"`
  replace, and what `CoursesController#show`'s new `topics` branch renders).

**Modified files:**
- `app/controllers/courses_controller.rb` — `@lecturers` already exists;
  add `@filtered_topic_list`/`@topics_by_supervisor`, the new `elsif
  params[:section] == 'topics'` branch, and private `filtered_topic_list`/
  `search_topics`/supervisor-filter methods (§7, §9). `authorize @course`
  is untouched — already there.
- `app/views/courses/_topic_directory_tab.html.erb` — rewritten from a
  preview-boxes layout into the full search/filter/grouped/collapsible view
  (§3, §0), on the same footing as `_groups_tab.html.erb`/`_people_tab.html.erb`.
  The "View All Topics" links to `course_topics_path` are removed (redundant
  once the tab itself is the full view) — but `course_topics_path` and its
  controller/view are **not deleted**, since `projects/index.html.erb` and
  `topics/new.html.erb` still depend on that route (§3).
- `app/views/courses/_topic_card.html.erb` — **no longer "possibly":** add the
  optional `hide_owner:` local (default `false`; grouped rows skip the
  redundant owner-name meta segment) and the optional `available_pill:` local
  (default `false`; when true and `topic.available?`, pass
  `pill_label: "Available"` — green comes free from the approved status,
  ADR 0014). Defaults keep every other call site (`topics/index`,
  `lecturers/show` ×4, Overview's pending topics) byte-identical.
- `app/models/topic.rb` — add `#available?` (`approved? &&
  proposed_project_instances.none?`, `topic.rb:15`). Plain model method, no
  migration, no enum change (ADR 0014).
- `app/views/shared/_row_item.html.erb` — **no pill changes at all**: the
  existing `pill_label` local covers the "Available" swap and approved already
  colors green. Only the small meta-separator fix so an empty `meta_parts`
  renders no leading "•" before the time (needed for `hide_owner:` grouped
  rows). Safe: no current `_row_item` caller passes empty `meta_parts` +
  `time_meta`.
- `app/javascript/controllers/expandable_rows_controller.js` — generalize the
  Groups-table-specific bits so the Topics Directory can reuse it: the chevron
  lookup must not assume a `tr[data-row-id]` (supervisor headers are divs), and
  the toggle-all icon lookup must not be hardcoded to `#groups-table-toggle-all`
  (the Topics Directory has its own "Collapse all"; §0 rule: centered on
  mobile).

**Untouched:** `app/controllers/topics_controller.rb`,
`app/views/topics/index.html.erb` (§3 — has its own independent callers),
`course_topics_path` and its route, `TopicPolicy`,
`app/helpers/application_helper.rb` (`status_badge_classes`),
`app/javascript/controllers/tabs_controller.js` — none of these need to change
for this feature, and if a ticket finds itself editing one, stop and check it
against §0/§3/§5/§8 first.

---

## 12. Build Order

1. Ticket 0 (decisions/ADRs) →
2. Ticket 1 (helpers, unit-tested) →
3. Ticket 2 (static grouped render) →
4. Ticket 5's request-spec-only half (write the leak-proof test *before*
   htmx interactivity lands, against Ticket 2's static render — cheaper to
   catch a scope leak before search/filter adds more surface area) →
5. Ticket 3 (htmx search/filter) →
6. Ticket 4 (collapse) →
7. Ticket 5's remaining authorize/gate checks, run against the finished page.

---

## 13. Tests

**Existing tests to keep green:** any request/system spec currently
covering `CoursesController#show`'s existing HX-Request branches (groups/
students), `_topic_directory_tab.html.erb`'s current preview content, or
`TopicsController#index` (untouched, but confirm nothing there implicitly
depended on the "View All Topics" links this work removes) — locate and run
before starting (`grep -rl "course_topics_path\|topic_directory_tab" spec/`).

**New/updated tests:**
- Policy spec: `TopicPolicy::Scope` unchanged, but add a request spec on
  the new action per role (coordinator sees all statuses across all
  supervisors; lecturer sees own-any-status + others'-approved-only; student
  sees approved-only) — this is the test called for in §8.3.
- Request spec: unauthenticated / non-enrolled user hitting the route gets
  redirected (proves `authorize @course` from §8.2 is actually wired, not
  just present).
- Unit specs for `search_topics` (title match, supervisor-name match,
  case-insensitivity) and the supervisor-filter helper, mirroring whatever
  test shape `search_students`/`search_groups` already have.
- System/feature spec: typing in the search box narrows visible supervisor
  groups; selecting a supervisor in the filter shows only that supervisor's
  group; "Collapse all" collapses every group and its label flips to
  "Expand all" (mirrors the Groups-table expand-all spec if one exists —
  check `spec/` for it and copy the shape).

---

## 14. Open items for whoever picks this up

- **§3 is now grounded in how `tabs_controller.js` actually works, not a
  style preference** — treat it as settled unless someone finds a reason
  `_topic_directory_tab.html.erb` specifically can't carry this content
  (none surfaced in this audit). Still worth a short ADR per this repo's
  convention, since the reasoning (why a routed page can't be one of the
  four instant tabs) is exactly the kind of thing `docs/adr/` exists to
  preserve.
- **Confirm §6.** Option A ships today with zero new model code; Option B
  is a real feature (topic claiming) that may already be wanted for other
  reasons (e.g., surfaced on `topics/show.html.erb` too) — worth asking
  whether this is scoped as "make the mockup's badge accurate" or "we
  actually want claimed-topic tracking as a feature," since the latter has
  a bigger footprint than this one page.
- **Supervisor capacity** (`SupervisorCapacityCalculator`) is a real,
  separate per-supervisor number already computed elsewhere in this
  controller's parent (`courses_controller.rb`) — the mockup doesn't show
  it, but a coordinator reviewing "how many topics does this supervisor
  have" might also want "...and how much capacity do they have left"
  alongside it. Not required by the mockup; flagging as a plausible
  follow-up ticket, not part of this one.