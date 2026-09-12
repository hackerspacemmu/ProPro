# courses/show Redesign — Regression Audit Prompt & Safe Refactor Workflow

Grounded against `hackerspacemmu/ProPro`, `main` vs `refactor/design`.
Everything below is verified against actual files — `file:line` references
included so the review agent can re-verify.

`courses/show` was the **first view migrated** in the design refactor. It was
done quickly and without the audit-first discipline that later tracks
(projects/show, people tab) followed. This doc catches regressions and
anti-patterns before they compound.

---

## 0. Why audit-first

The projects/show redesign built a "Query/Path Audit" table *before*
ticket-writing — every claimed-correct query, association, and policy call
was checked against `main` first. The people/tab track followed the same
pattern with a detailed pre-existing-findings section (§2 in that doc).

`courses/show` skipped that step. The shell was rebuilt, the People tab was
decomposed into section partials, and the Groups tab was added — all in a
single pass. The results are mostly correct (this audit confirms the tab-index
fix, the IDOR fix, the htmx routing, and the policy gates), but there are
four partials that still read instance variables they shouldn't, and the
`_groups_tab` header breaks its own "ivar→locals seam" contract.

---

## 1. Files actually in play

Confirmed via `git ls-tree` / `git show` on both branches — use these paths,
don't let the agent invent new ones:

### Tab shell + chrome

| Layer | Path |
|---|---|
| Tab shell | `app/views/courses/show.html.erb` |
| Sidebar | `app/views/shared/_sidebar.html.erb` |
| Sidebar helper | `app/helpers/sidebar_helper.rb` |

### Level-0 partials (directly rendered from show.html.erb)

| Partial | Path | Locals | Ivars |
|---|---|---|---|
| Project Details tab | `app/views/courses/_project_details_tab.html.erb` | none | `@description`, `@course`, `@lecturers` |
| To Review tab | `app/views/courses/_to_review_tab.html.erb` | none | `@pending_proposals`, `@reviewed_proposals`, `@pending_topics` |
| Supervised Projects tab | `app/views/courses/_supervised_projects_tab.html.erb` | none | `@approved_projects`, `@course` |
| Topic Directory tab | `app/views/courses/_topic_directory_tab.html.erb` | none | `@course`, `@topic_list`, `@my_topics`, `@current_user_enrolment` |
| People tab | `app/views/courses/_people_tab.html.erb` | none | **ivar→locals seam** — reads ivars once, passes locals down |
| Groups tab | `app/views/courses/_groups_tab.html.erb` | none | **ivar→locals seam** — header reads ivars, children get locals |

### Level-1 partials (rendered from level-0)

| Partial | Path | Locals | Ivars |
|---|---|---|---|
| Lecturers section | `app/views/courses/_lecturers_section.html.erb` | `course`, `lecturers`, `capacity_result`, `lecturer_capacity_info` | none |
| Students section | `app/views/courses/_students_section.html.erb` | `course`, `students`, `student_group_map`, `student_enrolment_map`, `total_student_count`, `total_count`, `displayed_count`, `show_all` | none |
| Groups table | `app/views/courses/_groups_table.html.erb` | `course`, `groups`, `projects_by_owner`, `total_count`, `displayed_count`, `show_all` | none |
| Add students modal | `app/views/courses/_add_students_modal.html.erb` | `course` | none |
| Lecturers (old) | `app/views/courses/_lecturers.html.erb` | `course`, `lecturer` | **`@lecturer_capacity_info`**, **`@course`** |
| Topic card | `app/views/courses/_topic_card.html.erb` | `topic` | **`@course`** (fallback path) |
| Project card | `app/views/courses/_project_card.html.erb` | `project`, `course` | **`@course`** (fallback path) |
| Proposal list item | `app/views/projects/_proposal_list_item.html.erb` | none | **`@course`** |

### Level-2 partials (rendered from level-1)

| Partial | Path | Locals | Ivars |
|---|---|---|---|
| Students table | `app/views/courses/_students_table.html.erb` | `course`, `students`, `student_group_map`, `student_enrolment_map`, `total_count`, `displayed_count`, `show_all` | none |
| Student row | `app/views/courses/_student_row.html.erb` | `student`, `group`, `selected`, `course`, `enrolment` | none |
| Group row | `app/views/courses/_group_row.html.erb` | `course`, `group`, `project`, `status`, `supervisor` | none |
| Topic card contents | `app/views/courses/_topic_card_contents.html.erb` | `topic`, `topic_instance`, `header_bg`, `status_key` | none |
| Project card contents | `app/views/courses/_project_card_contents.html.erb` | `project`, `project_instance`, `header_bg`, `status_key` | none |

### Controller / policy / model / helper / JS

| Layer | Path |
|---|---|
| Controller | `app/controllers/courses_controller.rb` (`#show`, htmx branch, private filter/sort methods) |
| Enrolments controller | `app/controllers/enrolments_controller.rb` (`#destroy` — IDOR fix) |
| Course policy | `app/policies/course_policy.rb` (`show?`, `manage_students?`, `manage_lecturers?`, `create?`) |
| Project policy | `app/policies/project_policy.rb` (`update?` — coordinator branch) |
| Enrolment policy | `app/policies/enrolment_policy.rb` (does not exist — inline in controller) |
| Helper | `app/helpers/courses_helper.rb` |
| Sidebar helper | `app/helpers/sidebar_helper.rb` |
| Model | `app/models/topic.rb` (`owner_name`) |
| Tab controller | `app/javascript/controllers/tabs_controller.js` |
| Expandable rows | `app/javascript/controllers/expandable_rows_controller.js` (new) |
| Students select | `app/javascript/controllers/students_select_controller.js` (new) |
| Routes | `config/routes.rb` (participants route removed) |

### Deleted files (confirmed absent on refactor/design)

| Path | Was on main |
|---|---|
| `app/controllers/participants_controller.rb` | YES |
| `app/views/participants/index.html.erb` | YES |
| `app/views/courses/_participants.html.erb` | YES |
| `app/views/courses/_participants_table.html.erb` | YES |
| `app/views/courses/_grouping_settings.html.erb` | YES (inlined into settings) |

---

## 2. Pre-existing findings (verified)

These are bugs/gaps that already exist on `main` and/or `refactor/design`.
They matter because a naive branch-diff will call them "unchanged, ignore"
when they're landmines the new tabs build on top of — and the review agent
must *not* file these as regressions introduced by `refactor/design`.

### 2.1 Tab-index mismatch — FIXED on refactor/design

**main** `show.html.erb:19-58`: hardcodes `data-tabs-index-param="0..4"` with
the "Supervised Projects" button and panel conditionally rendered via
`<% if @current_user_enrolment&.coordinator? || ... %>`. For a student, the
conditional tab doesn't render, but the buttons still say `index="3"` and
`index="4"` — they match by accident because the DOM count shifts uniformly.

**refactor/design** `show.html.erb:10-48`: builds a `tabs` array, then iterates
with `each_with_index` for both buttons *and* panels. Indices are computed
dynamically. **Fix is correct.** Verified via `tabs_controller.js` which reads
`event.params.index` and iterates by DOM order.

### 2.2 Ivar coupling in `_lecturers.html.erb` (pre-existing, both branches)

`_lecturers.html.erb:19` reads `@lecturer_capacity_info[lecturer.id]` and
`:23` reads `@course.solo_supervisor?` — despite receiving `course:` as a local
and `_lecturers_section` having `lecturer_capacity_info` as a local. The local
isn't threaded through. **Pre-existing on both branches.**

### 2.3 `_groups_tab` header reads ivars directly (refactor/design only)

Despite the comment "ivar→locals seam" on line 1, the header section reads
`@total_group_count:9`, `@course:19,28,38,41,48,56,72,79`,
`@filtered_group_list:73`, `@projects_by_owner:74`, `@show_all:77` directly.
Only the `_groups_table` render call (line 71) passes locals. **The seam
comment is misleading** — the children are locals-only, but the header section
breaks the contract stated in the comment. This is a cosmetic inconsistency
(the seam layer is allowed to read ivars per the people_tab plan convention),
but the comment should not claim the entire partial is a clean seam when the
header section violates it.

### 2.4 `_project_details_tab`, `_to_review_tab`, `_topic_directory_tab` — pure-ivar

These three L0 partials receive zero locals and read multiple ivars. They are
not seams — they're the old-style Rails pattern. **Pre-existing on both
branches.** Not broken, but they violate the "partials as reusable components"
rule (§7.3 in the Agile Web Dev book): they can't be reused from a different
controller without setting the same ivars.

### 2.5 `_project_card` / `_topic_card` fall back to `@course` ivar

Both partials have an `else` branch in their path generation that reads
`@course` directly:
- `_topic_card.html.erb:24,26` — `course_topic_path(@course, topic, ...)`
- `_project_card.html.erb:32` — `course_project_path(@course, project)`

The callers `_supervised_projects_tab` and `_topic_directory_tab` pass
`course:` in some render calls but not all. **Pre-existing on both branches.**

### 2.6 `projects/_proposal_list_item` reads `@course` as ivar

`_proposal_list_item.html.erb:13` — `course_project_path(@course, proposal)`.
No `course` local is received. Called from `_to_review_tab` which passes zero
locals to this collection render. **Pre-existing on both branches.**

### 2.7 Duplicate `raise StandardError` in `courses_controller#create`

`courses_controller.rb` (refactor/design) has the line
`raise StandardError, 'Template creation failed' unless default_template.save`
twice in succession. The second call operates on an already-saved record.
Harmless but dead code. **Only on refactor/design.**

### 2.8 Dead helpers removed (refactor/design)

`courses_helper.rb` removed `participants_exceed?` and `supervisors_exceed?`.
On main, `participants_exceed?` was only called from `_participants.html.erb`
(deleted); `supervisors_exceed?` had zero callers even on main (already dead).
**No dangling references.**

### 2.9 Dead config in `config/application.rb`

`config.participants_threshold` and `config.supervisors_threshold` are now
dead — no remaining consumers on refactor/design. **Worth removing.**

### 2.10 `params[:lecturer_filter]` passed without authorization check

`courses_controller.rb` passes `params[:lecturer_filter]` directly to
`@course.enrolments.where(user_id:)`. Any enrolled user can enumerate lecturer
enrolments via this param. No SQL injection (AR type-casts to integer), but
no Pundit check either. **Pre-existing on both branches.**

---

## 3. Audit findings — severity-tagged

### BREAKING

_No breaking findings._ The tab-index fix, htmx routing, policy gates, and
IDOR fix are all correct.

### BEHAVIOR CHANGE

| # | Finding | Evidence | Impact |
|---|---|---|---|
| BC-1 | `CoursePolicy#create?` added — returns `user.is_staff` | `course_policy.rb:8` | Tightening: course creation was unauthenticated on main; now requires staff. **Intentional.** |
| BC-2 | `ProjectPolicy#update?` adds coordinator branch | `project_policy.rb:36` | Broadening: coordinators can now edit any project in their course. **Intentional.** |
| BC-3 | `authorize Course.new` added to `new`/`create` actions | `courses_controller.rb:225,230` | Tightening: these actions had no authorization on main. **Intentional.** |
| BC-4 | IDOR fixed in `EnrolmentsController#destroy` | `enrolments_controller.rb:13-17` | Security: `params[:coordinator_id]` no longer used for auth; `current_user` checked instead; enrolment scoped to `current_course`. **Intentional.** |
| BC-5 | `@group_list` filtered to `confirmed: true` only | `courses_controller.rb` (show action) | Groups tab never shows draft groups. **Intentional.** |
| BC-6 | New partials (`resend_invite` button) now gated by `manage_students?` | `_student_row.html.erb:32`, `_group_row.html.erb:73` | Tightening: resend was ungated on main's `_participants_table.html.erb`. **Intentional.** |

### COSMETIC

| # | Finding | Evidence |
|---|---|---|
| C-1 | Tab bar: `flex gap-8` (main) → `flex flex-wrap gap-x-8 gap-y-1` (refactor) with `whitespace-nowrap` on buttons | `show.html.erb:30` |
| C-2 | `content_for :body_class, "bg-[#f8fafd]"` replaces hardcoded `min-h-screen bg-[#f8fafd]` wrapper | `show.html.erb:1` |
| C-3 | Inline Google Fonts `<link>` tags removed (now in layout) | `show.html.erb:5` (was `:6-8` on main) |
| C-4 | Settings link gets `border-b-4 border-transparent` for consistent hover state | `show.html.erb:40` |

### NEEDS DECISION

| # | Finding | Evidence | Decision needed |
|---|---|---|---|
| ND-1 | `_groups_tab` header reads ivars despite "ivar→locals seam" comment | `_groups_tab.html.erb:1,9,19,28,38,41,48,56,72,79` | Fix the comment or fix the code? The convention is that L0 partials ARE the seam layer (like `_people_tab`), so reading ivars there is allowed — but the comment is misleading. |
| ND-2 | `_course_card.html.erb` and `_project_status_bar.html.erb` are orphaned on both branches | No `render` calls anywhere | Delete both? They're pre-existing orphans. |
| ND-3 | Dead config `config.participants_threshold` / `config.supervisors_threshold` | `config/application.rb` | Remove? No consumers remain. |
| ND-4 | Duplicate `raise StandardError` in `courses_controller#create` | `courses_controller.rb` (refactor/design) | Remove the duplicate line? |
| ND-5 | `_lecturers.html.erb` reads ivars despite receiving `course:` local | `_lecturers.html.erb:19,23` | Thread `lecturer_capacity_info` through as a local? Or leave (pre-existing). |

### COSMETIC (pre-existing, not regressions)

| # | Finding | Evidence |
|---|---|---|
| P-1 | `_project_details_tab`, `_to_review_tab`, `_topic_directory_tab` are pure-ivar | All L0 partials, both branches |
| P-2 | `_project_card` / `_topic_card` fall back to `@course` ivar for path generation | `_topic_card:24,26`, `_project_card:32` |
| P-3 | `_proposal_list_item` reads `@course` as ivar | `_proposal_list_item:13` |
| P-4 | `params[:lecturer_filter]` passed without authorization check | `courses_controller.rb` |

---

## 4. The audit prompt

Copy-paste this to the review/comparison agent as-is. It is scoped to
*audit only* — no implementation.

```
You are auditing the courses/show redesign area of
hackerspacemmu/ProPro. Do not write or modify any implementation code in
this pass — produce an audit document only, in the style of a
file:line-referenced evidence table.

Ground everything against actual code:
- Reference branch (source of truth for current working behavior): main
- Branch being audited: refactor/design

Scope: the courses/show surface only — i.e. everything that renders
when a user visits a course page. Specifically:
- app/views/courses/show.html.erb (the tab shell)
- app/views/courses/_project_details_tab.html.erb
- app/views/courses/_to_review_tab.html.erb
- app/views/courses/_supervised_projects_tab.html.erb
- app/views/courses/_topic_directory_tab.html.erb
- app/views/courses/_people_tab.html.erb
- app/views/courses/_lecturers_section.html.erb
- app/views/courses/_students_section.html.erb
- app/views/courses/_groups_tab.html.erb
- app/views/courses/_groups_table.html.erb
- app/views/courses/_group_row.html.erb
- app/views/courses/_students_table.html.erb
- app/views/courses/_student_row.html.erb
- app/views/courses/_add_students_modal.html.erb
- app/views/courses/_lecturers.html.erb (still rendered by _project_details_tab)
- app/views/courses/_topic_card.html.erb and _topic_card_contents.html.erb
- app/views/courses/_project_card.html.erb and _project_card_contents.html.erb
- app/views/projects/_proposal_list_item.html.erb
- app/views/shared/_sidebar.html.erb
- app/controllers/courses_controller.rb (#show, htmx branch, private methods)
- app/controllers/enrolments_controller.rb (#destroy — IDOR fix)
- app/policies/course_policy.rb
- app/policies/project_policy.rb
- app/helpers/courses_helper.rb
- app/helpers/sidebar_helper.rb
- app/javascript/controllers/tabs_controller.js
- app/javascript/controllers/expandable_rows_controller.js
- app/javascript/controllers/students_select_controller.js
- config/routes.rb (courses/participants sections)
- All deleted files: participants_controller.rb, participants/index.html.erb,
  _participants.html.erb, _participants_table.html.erb

For each file, produce a table row per meaningful unit (action, helper
method, policy method, partial local) with columns:
  Item | Exists on main? | Exists on refactor/design? | Status | Evidence (file:line)
Status must be one of: ✅ unchanged/reused correctly, ⚠️ partial/drifted,
❌ missing (spec needs it, no code implements it yet), 🐛 pre-existing bug
(exists on main already, not introduced by refactor/design).

Specifically verify or refute these claims, with evidence either way:
1. The tab-index fix: show.html.erb uses tabs.each_with_index to compute
   data-tabs-index-param dynamically, so conditional tabs (Supervised
   Projects) don't cause DOM-position mismatches for student-role users.
   Confirm this is correct.
2. The htmx branch: section=groups renders _groups_table, section=students
   renders _students_table, all locals are satisfied. Confirm.
3. Every manage_students? / manage_lecturers? policy gate on main is
   preserved on refactor/design. Confirm.
4. The IDOR in EnrolmentsController#destroy is fixed: params[:coordinator_id]
   is no longer used for auth; current_user is checked; enrolment find is
   scoped to current_course. Confirm.
5. _people_tab and _groups_tab are ivar→locals seams: they read ivars once
   and pass everything as locals to children. Confirm or refute.
6. All child partials (_lecturers_section, _students_section, _groups_table,
   _group_row, _student_row, _students_table, _add_students_modal) are
   strict locals-only. Confirm.
7. Pre-existing anti-patterns still exist: _lecturers reads @course and
   @lecturer_capacity_info as ivars; _project_card/_topic_card fall back to
   @course ivar; _proposal_list_item reads @course ivar. Confirm.
8. Dead code fully removed: _participants.html.erb, _participants_table,
   ParticipantsController, participants route. No dangling references.
   Confirm.
9. Responsive: tab bar uses flex-wrap to prevent overflow at 360px; sidebar
   uses drawer idiom (fixed -translate-x-full lg:static lg:translate-x-0);
   tables have overflow-x-auto. Confirm.
10. No nested <form> issues: _course_code_form is not rendered inside
    another <form>. Confirm.

Then, cross-check the following against what currently exists in the
codebase (both branches). For each, state: already supported, needs new
backend surface, or needs a data-model change:
- Tab shell: data-driven tabs array with conditional tabs, correct indices
  for all roles (coordinator, lecturer, student).
- People tab: lecturers section with capacity bar, students section with
  search/sort/actions, add-students modal.
- Groups tab: search, filter by status/lecturer, sortable columns, expandable
  member rows, add-students modal.
- Settings link: real navigation link, not a tab panel.
- Sidebar: drawer idiom on mobile, static column on desktop.

Deliverable: a single markdown document, same shape as an existing "Query /
Path Audit" table plus a "known broken/dead code" list plus a "spec gap"
list. Do not propose file-by-file implementation tickets — that happens in
a separate pass once this audit is reviewed.
```

---

## 5. Build workflow

### Ticket 0 — Fix `_groups_tab` seam comment (trivial)

The comment on `_groups_tab.html.erb:1` says "ivar→locals seam — the Groups
panel counterpart of _people_tab.html.erb. Reads controller ivars ONCE and
passes locals down; nothing rendered from here touches an ivar again." This is
true for the children but not for the header section, which reads
`@total_group_count`, `@course`, `@filtered_group_list`, etc. directly.

**Fix:** Either:
- (a) Update the comment to match `_people_tab`'s wording: "ivar→locals seam —
  reads controller ivars ONCE, then passes everything below as locals.
  Sanctioned exception to the locals-only rule." OR
- (b) Thread the header's ivars through as locals from `show.html.erb` (more
  work, but makes the seam honest).

Recommend (a) — the convention is that L0 partials ARE the seam layer.

### Ticket 1 — Thread `lecturer_capacity_info` into `_lecturers.html.erb` (small)

`_lecturers.html.erb` receives `course:` as a local but reads `@course` (line
23) and `@lecturer_capacity_info` (line 19) as ivars. The parent
`_lecturers_section` already has both as locals. Thread them through:

```erb
<%# was: render partial: "lecturers", collection: @lecturers, as: :lecturer, locals: { course: @course } %>
<%= render partial: "lecturers", collection: lecturers, as: :lecturer,
           locals: { course: course, lecturer_capacity_info: lecturer_capacity_info } %>
```

Then update `_lecturers.html.erb` to use `local_assigns[:lecturer_capacity_info]`
and `local_assigns[:course]` instead of ivars.

### Ticket 2 — Delete orphaned partials

- Delete `app/views/courses/_course_card.html.erb` (confirmed no render calls)
- Delete `app/views/courses/_project_status_bar.html.erb` (confirmed no render calls)

### Ticket 3 — Remove dead config

- Remove `config.participants_threshold` and `config.supervisors_threshold`
  from `config/application.rb` (no consumers on refactor/design)

### Ticket 4 — Fix duplicate `raise StandardError` in `courses_controller#create`

Remove the duplicate line.

### Ticket 5 — Add policy tests (highest value, zero cost)

```ruby
# test/policies/course_policy_test.rb
# test every CoursePolicy rule for each role (coordinator, lecturer, student, guest)
```

### Ticket 6 — Add system tests for tab switching

```ruby
# test/system/courses/course_tabs_test.rb (extend existing)
# Click each tab, assert the active panel changes
```

### Ticket 7 — Add responsive test for courses/show

```ruby
# test/system/courses/mobile_overflow_test.rb
# Port pattern from projects/mobile_overflow_test.rb:
# 360px viewport, assert no horizontal page overflow,
# assert tabs scroll/wrap, assert sidebar drawer works
```

### Ticket 8 — Add htmx search/filter system tests

```ruby
# Type into #students-search, wait for response, assert table updates
# Type into #groups-search, assert filtered results
```

### Build order

```
0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8
```

Tickets 0–4 are independent fixes/cleanup. Tickets 5–8 are new tests.

---

## 6. Feature inventory — main vs refactor/design

Walk the OLD view (`main`) top to bottom and map every user-facing behavior:

| Feature | main | refactor/design | Status |
|---|---|---|---|
| Tab: Project Details | ✅ renders `_project_details_tab` | ✅ same | PRESERVED |
| Tab: To Review | ✅ renders `_to_review_tab` | ✅ same | PRESERVED |
| Tab: Supervised Projects | ✅ conditional (coordinator/lecturer) | ✅ same | PRESERVED |
| Tab: Topic Directory | ✅ renders `_topic_directory_tab` | ✅ same | PRESERVED |
| Tab: People | ✅ monolithic `_people_tab` + `_participants` | ✅ decomposed into `_lecturers_section` + `_students_section` | REFACTORED |
| Tab: Groups | ❌ did not exist | ✅ new `_groups_tab` | NEW |
| Settings link | ✅ `link_to "Settings"` | ✅ same | PRESERVED |
| Sidebar | ✅ static 280px column | ✅ drawer idiom (off-canvas mobile, static desktop) | IMPROVED |
| Tab overflow | ❌ `flex gap-8` overflows at 360px | ✅ `flex flex-wrap` prevents overflow | FIXED |
| Fonts | ❌ inline `<link>` tags per page | ✅ global in layout | IMPROVED |
| Background | ❌ hardcoded `min-h-screen bg-[#f8fafd]` | ✅ `content_for :body_class` | IMPROVED |
| Supervisors section | ✅ inline in `_people_tab` | ✅ extracted to `_lecturers_section` | REFACTORED |
| Students section | ✅ inline `_participants` partial | ✅ extracted to `_students_section` | REFACTORED |
| Groups section | ❌ combined in `_participants_table` | ✅ separate `_groups_tab` + `_groups_table` | NEW |
| Add Students | ✅ full-page link | ✅ modal (`_add_students_modal`) opened from People + Groups | IMPROVED |
| Add Lecturers | ✅ link in `_people_tab` | ✅ link in `_lecturers_section` | PRESERVED |
| htmx search (students) | ✅ in `_participants_table` | ✅ in `_students_section` | PRESERVED |
| htmx search (groups) | ✅ in `_participants_table` | ✅ in `_groups_tab` | PRESERVED |
| htmx sort (groups) | ✅ column headers | ✅ column headers | PRESERVED |
| htmx sort (students) | ❌ no sort on main | ✅ sort-by-alpha toggle | NEW |
| Expandable group rows | ❌ did not exist | ✅ `expandable_rows_controller.js` | NEW |
| Single-select student radio | ❌ did not exist | ✅ `students_select_controller.js` | NEW |
| Actions dropdown (Resend/Remove) | ❌ inline buttons | ✅ dropdown with policy gates | IMPROVED |
| Resend invite | ✅ ungated in `_participants_table` | ✅ gated by `manage_students?` | IMPROVED |
| Capacity bar (3-tier color) | ✅ in `_lecturers` partial | ✅ in `_lecturers_section` with ratio-based color | PRESERVED |
| Pending count red warning | ❌ did not exist | ✅ `pending_exceeds` check | NEW |
| Solo-supervisor "Instructor:" variant | ✅ in `_people_tab` | ✅ in `_lecturers_section` | PRESERVED |
| Auto-calculate offset callout | ✅ in `_people_tab` | ✅ in `_lecturers_section` | PRESERVED |
| Student "Pending" badge | ✅ in `_participants_table` | ✅ in `_student_row` | PRESERVED |
| Student resend-invite URL | ✅ in `_participants_table` | ✅ `data-resend-url` attribute | PRESERVED |
| Group confirmed-only filter | ❌ showed all groups | ✅ `where(confirmed: true)` | IMPROVED |
| Duplicate controller cleanup | ❌ `ParticipantsController` existed | ✅ deleted | CLEANED |

---

## 7. Partials discipline — tie-back to §7.3

Every rule from "Think of Partials as Re-usable Components" checked:

### Rule 1: Partials should be re-usable components

| Partial | Reused? | Verdict |
|---|---|---|
| `_lecturers_section` | Single use (People tab only) | ⚠️ Single-use, but justified by decomposition |
| `_students_section` | Single use (People tab only) | ⚠️ Same |
| `_groups_tab` | Single use (Groups tab panel) | ⚠️ Same |
| `_groups_table` | Two uses: `_groups_tab` + htmx re-render | ✅ Re-usable |
| `_students_table` | Two uses: `_students_section` + htmx re-render | ✅ Re-usable |
| `_add_students_modal` | Two uses: `_students_section` + `_groups_tab` | ✅ Re-usable |
| `_student_row` | Single use (`_students_table`) | ⚠️ Single-use, but table row partial |
| `_group_row` | Single use (`_groups_table`) | ⚠️ Same |
| `_lecturers` | Single use (`_project_details_tab` solo-supervisor) | ⚠️ Single-use, legacy |
| `_topic_card` | Four uses: `_to_review_tab`, `_topic_directory_tab`, `lecturers/show`, `topics/index` | ✅ Re-usable |
| `_project_card` | Three uses: `_supervised_projects_tab`, `_project_status_bar`, `lecturers/show` | ✅ Re-usable |
| `_proposal_list_item` | Single use (`_to_review_tab`) | ⚠️ Single-use |

### Rule 2: Partials should use locals, not instance variables

| Partial | Locals-only? | Anti-pattern? |
|---|---|---|
| `_lecturers_section` | ✅ Yes | — |
| `_students_section` | ✅ Yes | — |
| `_groups_tab` | ⚠️ Seam layer (header reads ivars) | Comment is misleading |
| `_groups_table` | ✅ Yes | — |
| `_group_row` | ✅ Yes | — |
| `_students_table` | ✅ Yes | — |
| `_student_row` | ✅ Yes | — |
| `_add_students_modal` | ✅ Yes | — |
| `_lecturers` | ❌ No | Reads `@lecturer_capacity_info`, `@course` |
| `_topic_card` | ❌ No | Falls back to `@course` |
| `_project_card` | ❌ No | Falls back to `@course` |
| `_proposal_list_item` | ❌ No | Reads `@course` |

**Summary:** 7 new partials are all strictly locals-only. 4 pre-existing
partials still have ivar anti-patterns. 1 seam layer partial has a misleading
comment.

---

## 8. Test coverage

### Current state: 121 tests, 299 assertions, 0 failures

| Area | Coverage |
|---|---|
| Tab visibility per role | ✅ `course_tabs_test.rb` (7 tests) |
| Tab click → panel content | ⚠️ Clicks buttons but doesn't assert panel content swaps |
| Settings page rendering | ✅ `settings_coursecode_test.rb` (3), `settings_save_test.rb` (2) |
| htmx search/filter (controller-level) | ✅ `courses_controller_test.rb` |
| htmx search/filter (browser-level) | ❌ No system tests |
| Policy tests | ❌ No `test/policies/` directory |
| Responsive (course show) | ❌ All responsive tests target project show |
| Unauthenticated access | ❌ No test |

### Recommended new tests (priority order)

1. `test/policies/course_policy_test.rb` — every rule for every role
2. `test/policies/project_group_policy_test.rb` — same
3. System test: tab switching with panel content assertion
4. System test: htmx students/groups search (browser-level)
5. System test: course show at 360px viewport
6. Controller test: unauthenticated access to course show
7. Controller test: empty states (no projects, no groups, no students)

---

## 9. How to verify

```sh
bin/rails test                                                        # 121 runs, 0 failures
bin/rails test test/system/courses/                                   # 12 system tests
npx @herb-tools/linter app/views/courses/show.html.erb                # lint
npx @herb-tools/linter app/views/courses/_people_tab.html.erb
npx @herb-tools/linter app/views/courses/_groups_tab.html.erb
npx @herb-tools/linter app/views/courses/_lecturers_section.html.erb
npx @herb-tools/linter app/views/courses/_students_section.html.erb
npx @herb-tools/linter app/views/courses/_groups_table.html.erb
npx @herb-tools/linter app/views/courses/_students_table.html.erb
```

# ProPro Redesign — courses/show — To Review styling + Follow-up Plan (v2) — Implementation Session Log

## Session status (updated)

Implemented: To Review tab styling (Ticket A), shared `_empty_state` partial +
SVG asset intake (Ticket B), empty-state wiring (Ticket C), To Review combined
zero state (Ticket D), tab bar primary/overflow split + scrolling net with
`dropdown#close` (Ticket E), and global breadcrumb fix + `sm` collapse
(Ticket F). Pass 1 cleanup/tests (Tickets 0–8 of the first pass) remain
**out of scope** from this session and are still open.

## Decisions landed this session

| # | Decision | Resolution |
|---|---|---|
| D-1 | Scope | To Review styling + Pass 2 only (tab bar, breadcrumb, empty states). **Defer all Pass 1 cleanup/tests.** |
| D-2 | Empty-state visual | **Illustration set** in `ProPro_Design/SVG/`, not Material icons. |
| D-3 | SVG → empty-state slot mapping | To Review→10, Supervised Projects→7, Topic Directory→5, Lecturers→8, Students→6, Groups→4. |
| D-4 | Asset serving | Copy SVGs into `app/assets/images/empty_states/` with descriptive names (e.g. `to_review_empty_state.svg`). |
| D-5 | Tab bar | Full primary/overflow split + "More" dropdown below `lg` + scrolling/fade net. |
| D-6 | Breadcrumb | **Global** fix in `breadcrumb_helper.rb` (all ~30 shared-header views) + `sm` collapse, with a reusable current-page-name accessor. |

## SVG → empty-state slots

| Empty state | Source SVG | Renamed to |
|---|---|---|
| To Review (full-tab zero) | `10 SCENE.svg` | `to_review_empty_state.svg` |
| Supervised Projects | `7 SCENE.svg` | `supervised_projects_empty_state.svg` |
| Topic Directory | `5 SCENE.svg` | `topic_directory_empty_state.svg` |
| Lecturers | `8 SCENE.svg` | `lecturers_empty_state.svg` |
| Students | `6 SCENE.svg` | `students_empty_state.svg` |
| Groups | `4 SCENE.svg` | `groups_empty_state.svg` |

## Implementation notes

- `dropdown_controller.js` already exists with `toggle` + `menu` target but had
  **no `close` action**; a `close` action was added (Ticket E step 5) so the
  More-menu item click closes the menu after `tabs#show`.
- `tabs_controller.js` and `tab_fade_controller.js` were reused **unchanged**.
- `_proposal_list_item.html.erb` is the shared row partial used by the To
  Review tab; its row/title/meta/pill styling was updated to match the design
  reference so both To Review sections inherit the polished look.

---

# ProPro Redesign — courses/show — Breadcrumb, Tab Bar & Empty-State Illustrations — Follow-up Plan (v2)

Grounded against `hackerspacemmu/ProPro`, `main` vs `refactor/design` (same repo
audited in `courses/show Redesign — Regression Audit Prompt & Safe Refactor
Workflow`). That audit confirmed the tab-shell logic, htmx routing, policy
gates, and IDOR fix are all correct — this is a **second, narrower pass** on
top of that shipped work: the header breadcrumb, the tab bar at small
viewports, a general responsive check across the six tabs, and empty-state
illustrations. Planning only — no implementation in this doc.

**This is a revision of the original follow-up plan.** §4.1 (breadcrumb) and
§4.2 (tab bar) have been rewritten after a design review that compared
ProPro's current mobile layout against Google Classroom's, and the two
approaches originally proposed for the tab bar (Ticket 1: port the
projects/show scrolling-strip pattern; Ticket 3: collapse the breadcrumb
below `sm` as a "stretch goal, needs a decision") have been superseded by
concrete decisions below. Everything else in this doc (§0–§3, §4.3, and
Tickets 4–8) is unchanged from the original pass and still applies.

**A note on images:** this doc references two screenshots that were shown
during the design discussion but are not attached here — a screenshot of
ProPro's own People tab at a narrow width, and a screenshot of Google
Classroom's Classwork tab at a comparable width, used as the point of
comparison that produced the decisions in §0.1. Both are described in full
in §3.1 and §3.2 in enough textual detail that no image is needed to follow
the reasoning or implement the tickets.

---

## 0. Why this follow-up

The `courses/show` redesign landed the shell, tabs, and People/Groups
decomposition correctly, but two chrome elements were never given the same
responsive treatment that `projects/show` already has, and every "nothing
here yet" state across the six tabs is still bare italic text with no
visual. Concretely:

- The breadcrumb wraps to a second line on long course names and breaks
  mid-word doing it, which changes the header's height per page.
- The tab bar wraps onto multiple rows on narrow screens instead of
  scrolling or otherwise adapting — and even once it doesn't wrap, six tabs
  plus a Settings link is visually dense compared to comparable tools.
- All seven "empty" branches across the six tabs are a single italic
  `<p>`/`<td>` line; there's no illustration anywhere in `courses/show`,
  though one exists (in miniature, icon-only) elsewhere in the app.

### 0.1 Decision log — read this before touching the tab bar or breadcrumb

Two different strategies were on the table for de-cluttering the tab bar on
narrow screens, and it's important the implementer understands why the
rejected one was rejected, since it's the more obvious-looking fix at first
glance:

**Option A — REJECTED: permanently reduce the number of top-level tabs, at
every screen width.** Concretely this would have meant moving the Settings
link out of the tab row into a gear icon in the page header (so it stops
counting as a "tab" at all), and merging the Groups tab into the People tab
as a third internal section alongside Lecturers and Students. This would
produce a 4-tab layout identical at every breakpoint — closest to how
Google Classroom is actually built (see §3.2: Classroom doesn't have a
different mobile layout, it just has four tabs, period). **This was
rejected** because it changes the app's information architecture — where
Settings lives, whether Groups is its own destination or a sub-section of
People — rather than just how that same architecture is *presented* at
different widths. That's a product/IA decision, not a responsive-styling
fix, and it's out of scope for a follow-up pass that's explicitly
presentation-only per the intro above. It would also affect deep links,
existing tests, and anywhere else in the app that links directly to the
Groups tab.

**Option B — CHOSEN: keep the existing six-tab-plus-Settings structure
completely intact, and change only which of those tabs render inline vs.
behind a "More" affordance, depending on viewport width.** The full set of
destinations (Project Details, To Review, Supervised Projects, Topic
Directory, People, Groups, Settings) still exists at every width, in the
same order, with the same `tabs` array driving the same `data-tabs-index-param`
indices as today. Below the `lg` breakpoint, four of those render inline and
the rest collapse into a "More" menu — but nothing is removed, renamed, or
merged. This is a pure presentation change: no controller, policy, route,
or partial-rendering logic changes as a result.

Reasoning for choosing B over A, specific to ProPro's usage: students are
the most likely group to open ProPro on a phone, but lecturers and
coordinators do too, and coordinators/lecturers are the ones who actually
need Supervised Projects, Groups, and Settings — the very tabs a permanent
merge would deprioritize. A responsive "More" menu keeps those reachable on
mobile for the people who need them, without asking every desktop user to
accept a restructured People/Groups tab they didn't ask for.

For the breadcrumb, the decision is: **below the `sm` breakpoint, hide the
entire multi-crumb trail (crumb › crumb › crumb, plus the "Home" fallback
link) and replace it with a single truncated string showing only the
current page's name — no chevron, no parent-page link.** This mirrors what
Classroom does (see §3.2: its mobile header shows only the class name, no
breadcrumb chain at all) and leans on the fact that ProPro already has a
hamburger/drawer sidebar that serves as the real navigation surface on
mobile — a breadcrumb trail is redundant chrome once that drawer exists.
This supersedes the original doc's Ticket 3, which had proposed keeping a
partial "‹ Dashboard" back-affordance; that's no longer necessary since the
drawer already provides one-tap access to Dashboard and every other course.

---

## 1. Files in play

| Area | Path |
|---|---|
| Breadcrumb component (gretel) | `app/helpers/breadcrumb_helper.rb` |
| Breadcrumb trail config | `config/breadcrumbs.rb` (`:root`, `:course` crumbs) |
| Breadcrumb consumption / header chrome | `app/views/shared/_header.html.erb` |
| Sidebar (course name truncation precedent) | `app/views/shared/_sidebar.html.erb` |
| Tab shell + tab bar | `app/views/courses/show.html.erb` |
| Reference pattern: scrolling tab strip | `app/views/projects/_project_header.html.erb` |
| Reference pattern: fade controller | `app/javascript/controllers/tab_fade_controller.js` |
| Reference pattern: viewport regression test | `test/system/projects/mobile_overflow_test.rb` |
| Existing empty-state convention (icon-only) | `app/views/courses/profile.html.erb:291-315` |
| Empty states to update | `_to_review_tab`, `_supervised_projects_tab`, `_topic_directory_tab`, `_students_table`, `_groups_table`, `_lecturers_section` (all `app/views/courses/`) |
| Existing course-tab test | `test/system/courses/course_tabs_test.rb` |

**Boundary note:** a full copy of what's presented as `show.html.erb`,
pasted into the design conversation for context, appeared to contain the
tab-building logic, the sidebar `<aside>` markup, and the `<header>` chrome
all in one block — which would contradict the file split above (sidebar and
header listed as separate shared partials, reused by ~30 other views). The
working assumption in this doc is that the paste concatenated content from
`show.html.erb`, `_sidebar.html.erb`, and `_header.html.erb` together for
readability, and that the file table above is still correct. **Confirm the
actual file boundaries in your checkout before splitting the edits below
across files** — if header/sidebar markup really has been inlined into
`show.html.erb` on `refactor/design`, the breadcrumb fix in §4.1 only
reaches `courses/show` instead of all ~30 views, which changes the priority
and blast-radius framing in §3.1.

---

## 2. What's already correct — do not rebuild

- **Sidebar drawer** (`shared/_sidebar.html.erb`, ADR-0008): off-canvas below
  `lg` (`-translate-x-full`, becoming `lg:static lg:translate-x-0`), backdrop
  + Stimulus toggle. Fine as-is. This is also the breakpoint the new tab-bar
  and breadcrumb logic below should key off of, for visual consistency —
  everything currently collapses/expands at `lg`, so the new "More" tab menu
  and the breadcrumb collapse should switch at the same points the sidebar
  already uses (`lg` for the tab bar, `sm` for the breadcrumb, matching the
  existing convention of a tighter breakpoint for text-heavy chrome).
- **Groups tab filter bar** (`_groups_tab.html.erb:6-40`): already
  `flex-col md:flex-row`, inputs `w-full md:w-auto`. No changes needed.
- **Students/Groups tables**: both already render inside an
  `overflow-x-auto` wrapper (`_students_table.html.erb:5`,
  `_groups_table.html.erb`), so the tables themselves scroll horizontally
  rather than blowing out the page. No changes needed there.
- **The scrolling-strip pattern this doc partially reuses has already been
  built once**, on `projects/show` (`_project_header.html.erb:38-65` +
  `tab_fade_controller.js`). This follow-up ports the scrolling/fade
  mechanism as a defensive layer underneath the new "More" menu — see §4.2 —
  it is not being reinvented.

---

## 3. Findings

### 🔴 3.1 Breadcrumb wraps and breaks mid-word on long course names

**What the reference screenshot shows, in words (no image attached):** a
screenshot of ProPro's own `courses/show` People tab, viewed at a narrow
(phone-width) viewport, shows the header row starting with a hamburger icon
and the word "ProPro," followed immediately by a breadcrumb trail that has
wrapped onto a second and third line. The trail reads "Dashboard" on its
own line, then ">" and the course name split mid-word across two more
lines as "Grouped TopicAp" / "provalEnabled" — the course is actually named
something like "Grouped Topic Approval Enabled," and the wrap point lands
in the middle of the word "Approval." A "Log out" link sits to the right of
the ProPro wordmark, on the same first line. Below that three-line-tall
header, the tab row shows "Project Details," "To Review," and "Supervised
Projec—" (cut off at the right edge of the screen) on one visible row, with
"People," "Groups," and "Settings" wrapped onto a second row underneath
("People" is underlined, indicating it's the active tab). Below the tabs,
the page shows the People tab's Lecturers section: a "Lecturers" heading,
then three rows each with a circular avatar, a name ("lecturer1",
"lecturer2", "lecturer3"), for one of them a "(2 pending)" label plus a
green progress bar and a "1/6" frature, and for the other two an empty gray
progress bar and "0/6". Below that, a "Students" heading with "15 students"
and a search box are just becoming visible at the bottom of the screenshot.

**Why this happens, in the code:** `_header.html.erb:1-25` puts the sidebar
toggle, the "ProPro" wordmark (`shrink-0`, line 15), and the breadcrumb
trail in one `flex items-center gap-2 min-w-0` row (line 2). The breadcrumb
trail itself (`breadcrumb_helper.rb:6`) is `flex flex-wrap items-center ...
w-full min-w-0` — so on a narrow screen with a long course name (the
screenshot's own "Grouped Topic Approval Enabled" is exactly this stress
case), the trail wraps to a second line instead of shrinking. Worse, only
the **last** crumb gets any overflow handling at all, and that handling is
`break-all` (`breadcrumb_helper.rb:11`) — it breaks the course name
mid-word rather than truncating it. This is inconsistent with the
**sidebar**, which truncates the identical course name with an ellipsis
(`_sidebar.html.erb:38`, `class: "... truncate"`). Two different overflow
strategies for the same string, visible on the same page, is the "hacky and
funky" feeling.

A second-order effect: because the header is a single-row
`flex items-center justify-between` (`_header.html.erb:1`) with **no
`min-h-*` utility set at all** (confirmed directly in the current source —
the `<header>` tag is just `class="flex items-center justify-between gap-3
px-4 py-3"`), a page whose breadcrumb wraps to two or three lines becomes
visibly taller than one whose breadcrumb fits on one line — the header's
height is effectively random per-course.

**Blast radius:** `render_custom_breadcrumbs` is shared infrastructure used
by ~30 views (courses, projects, topics, lecturers, settings, auth pages,
static pages — see the grep list in §1), **provided the file-boundary
assumption in §1 holds**. A fix at the helper level fixes every one of
those pages at once; a fix scoped to `courses/show` alone would mean
forking the header just for this route, which is more work for a worse
outcome. Recommend fixing at the helper/header level (see §4.1).

### 🔴 3.2 Tab bar is dense and wraps instead of adapting

**What the two reference screenshots show, in words (no images attached):**

*Screenshot 1 — ProPro's own courses/show, narrow viewport* (the same one
described in §3.1): the tab row wraps onto two visual rows because there
isn't room for all six tab labels plus "Settings" on one line. The first
row shows "Project Details," "To Review," and "Supervised Projec—" cut off
at the screen edge; the second row shows "People," "Groups," and
"Settings." Which row a given tab lands on, and how tall the two-row block
ends up, depends on exactly how much horizontal space each tab's label
needs and how many tabs are present for the current user's role.

*Screenshot 2 — Google Classroom's Classwork tab, comparable narrow
viewport, shown as a reference point:* the header is just a hamburger icon
followed by "Scatting class" on one line and "G11" (the section) on a
smaller line beneath it — no breadcrumb chain of any kind, just the class
name and section. A gear icon and a three-dot overflow menu sit at the
top-right of that same header row. Below the header is a single-row tab
bar with exactly four items — "Stream," "Classwork," "People," "Marks" —
all fitting on one line with "Classwork" underlined as the active tab.
There is no visible "More" button or overflow affordance in this
screenshot; four items apparently fit without needing one. Below the tabs
is a blue pill-shaped "+ Create" button, a "Collapse all" toggle with a
chevron icon, and a "No topic" section heading with four assignment rows
underneath (each showing an icon, a title, a status like "Draft" or
"Edited 10:38", and a three-dot menu).

**The comparison and what it implies:** Classroom achieves a single clean
header row and a single clean tab row by (a) never having more than four
top-level tabs to begin with, and (b) never rendering a breadcrumb chain at
all, since the hamburger drawer already handles navigation. ProPro's
`courses/show` has six tabs plus a Settings link — more than Classroom's
four — and, per §3.1, a breadcrumb chain on top of that. §0.1 explains why
we are *not* copying Classroom's exact four-tab structure (that would
require merging Groups into People and relocating Settings, an IA change
out of scope here) and are instead adapting the *presentation* of the
existing six-tab-plus-Settings structure so it degrades the way Classroom's
does on a narrow screen, without changing what those tabs are or where they
live.

**Why it wraps, in the code:** `show.html.erb`'s tab row currently uses
`flex flex-wrap gap-x-8 gap-y-1` for the tab buttons plus the Settings
link. On a narrow viewport this wraps the strip onto a second row, and —
because the number of tabs is role-dependent (5 for a student, 6 for a
coordinator/lecturer, since "Supervised Projects" only renders for
`@current_user_enrolment&.coordinator?` or `&.lecturer?`) — *where* it
wraps, and how tall the tab bar ends up, differs by role and by exactly how
much horizontal space each tab label needs.

### 🟡 3.3 People tab: Lecturers section has no empty state at all

`_lecturers_section.html.erb` has no `lecturers.any?` guard anywhere — if a
course somehow has zero enrolled lecturers, the `<div class="flex flex-col
gap-1">` (line 22) simply renders empty, no message. Every other list-y
partial in this tab set (`_students_table.html.erb:28`,
`_groups_table.html.erb:65`, `_supervisor_capacity_settings.html.erb:85` —
a *different* lecturer-capacity table, not this one) has an italic
fallback line; this one doesn't. Small, easy to fold into the empty-state
ticket since we're touching all the others anyway.

### 🟢 3.4 Everything else checked

`_to_review_tab.html.erb`, `_supervised_projects_tab.html.erb`,
`_topic_directory_tab.html.erb`, `_students_table.html.erb`,
`_groups_table.html.erb` all *do* have an empty-state fallback already —
they're just plain text with no illustration (see the mapping in §4.3).

---

## 4. Target design

### 4.1 Breadcrumb — single line + truncate at `sm`+, collapse to page name below `sm`

Two things stack here: a fix to the existing trail (still needed at every
width `sm` and up), and a new mobile-specific collapse below `sm`.

**At `sm` and above — fix the existing trail (unchanged from the original
plan's Ticket 2):**

- In `breadcrumb_helper.rb`, change the trail container from
  `flex flex-wrap items-center text-sm text-gray-500 w-full min-w-0` to a
  non-wrapping flex row (`flex flex-nowrap items-center ... min-w-0`), and
  give the trail itself `min-w-0` so it can shrink inside the header's
  `flex items-center gap-2 min-w-0` row instead of forcing a second line.
- Replace the final crumb's `break-all` with `truncate min-w-0 flex-1` —
  the same overflow strategy the sidebar already uses for the identical
  course-name string, so the two stop disagreeing with each other.
- Give the `<header>` element in `_header.html.erb` (currently
  `class="flex items-center justify-between gap-3 px-4 py-3"`, confirmed
  from the actual source — no height utility present today) a fixed
  `min-h-[3.5rem]` (or whatever the design system's standard header height
  is), so the row no longer changes height between a short-name course and
  a long-name one.

**Below `sm` — collapse to a single truncated name (decided; supersedes the
original doc's "stretch goal, needs a decision" framing for this):**

Hide the full trail entirely and show only the current page's name,
truncated, with no chevron and no separate parent-page link — matching
Classroom's mobile header, which shows only the class name and never a
breadcrumb chain (see §3.2, Screenshot 2). Concretely, in `_header.html.erb`,
where the header currently has:

```erb
<span class="shrink-0 text-[24px] text-[#5F6368] font-medium">ProPro</span>

<% unless content_for?(:hide_breadcrumbs) %>
  <% render_custom_breadcrumbs %>
  <% if content_for?(:breadcrumbs) %>
    <%= yield :breadcrumbs %>
  <% else %>
    <%= link_to "Home", root_path, class: "hover:text-gray-900 transition-colors" %>
  <% end %>
<% end %>
```

this becomes, in outline:

```erb
<span class="shrink-0 text-[24px] text-[#5F6368] font-medium">ProPro</span>

<% unless content_for?(:hide_breadcrumbs) %>
  <div class="hidden sm:flex sm:items-center sm:gap-2 sm:min-w-0">
    <% render_custom_breadcrumbs %>
    <% if content_for?(:breadcrumbs) %>
      <%= yield :breadcrumbs %>
    <% else %>
      <%= link_to "Home", root_path, class: "hover:text-gray-900 transition-colors" %>
    <% end %>
  </div>
  <span class="sm:hidden truncate text-sm text-[#3C4043] font-medium min-w-0">
    <%%= current_breadcrumb_page_name %>
  </span>
<% end %>
```

**Prerequisite, blocking, before this ticket is written up in detail:**
`breadcrumb_helper.rb` and `config/breadcrumbs.rb` have not been reviewed
directly as part of this pass — only referenced by file:line in the earlier
audit. The call site is `<% render_custom_breadcrumbs %>` — note the
**missing `=`** — which means the helper must already be pushing markup
into the view's output buffer itself (e.g. via `concat`/`safe_concat`)
rather than returning a string to be printed; this is confirmed to work
today since the screenshot in §3.1 shows a rendered breadcrumb trail, so
it's a helper-implementation detail to account for, not a bug. What's
**not yet known** is whether that helper (or `config/breadcrumbs.rb`)
already exposes the *current/last crumb's display text* as a plain string
anywhere reusable — if it does, `current_breadcrumb_page_name` above should
just call that. If it doesn't, a small addition to the helper is needed to
expose it, rather than having every one of the ~30 call sites guess at
their own page name (e.g. `@course&.course_name` would be wrong on any
non-course page using the same shared header). **Read both files before
writing this ticket's real diff** — do not ship a per-view hack like
`@course&.course_name || "Home"` as a stand-in for the real helper output.

### 4.2 Tab bar — role-agnostic primary/overflow split, with a scrolling safety net

This replaces the original plan's Ticket 1 (which proposed a straight port
of the projects/show scrolling-strip pattern with no overflow menu). The
final design combines two mechanisms, layered:

1. **A name-based split into "primary" and "overflow" tabs**, which
   controls *how many buttons show inline* below the `lg` breakpoint. This
   is the mechanism that actually reduces visual density on a phone,
   closing most of the gap with Classroom's four-tab look without changing
   which tabs exist.
2. **The existing projects/show scrolling-strip pattern**, ported and
   applied to whatever set of buttons ends up visible at a given
   breakpoint, so that even the reduced set never wraps if it still doesn't
   fit — e.g. a very narrow phone, a browser with enlarged/zoomed text, or
   a future locale with longer tab labels. This is a defensive layer, not
   the primary fix.

**What renders where, spelled out per role and per breakpoint (no image
needed to follow this):**

| Breakpoint | Role | What's visible in the tab row |
|---|---|---|
| `lg` and up (desktop/tablet-landscape) | any role | Every tab renders inline, in the existing order: Project Details, To Review, (Supervised Projects — coordinators/lecturers only), Topic Directory, People, Groups, then the Settings link. Nothing is hidden, and no "More" button appears — this is visually identical to today except that an overloaded row now scrolls horizontally instead of wrapping (see the scrolling-strip mechanism below). |
| below `lg` (phone/small tablet) | student (5 tabs, no Supervised Projects) | Visible inline: Project Details, To Review, Topic Directory, People — four tabs — followed by a "More ⌄" button. Tapping/tapping "More" opens a small menu listing: Groups, then Settings. |
| below `lg` | coordinator or lecturer (6 tabs) | Visible inline: the same four — Project Details, To Review, Topic Directory, People — followed by "More ⌄". The menu lists: Supervised Projects, Groups, then Settings. |

Note that "Project Details," "To Review," "Topic Directory," and "People"
were chosen as the always-visible four because they read as
browse/review-oriented actions a student is likely to check often, versus
"Supervised Projects," "Groups," and "Settings," which skew toward
management tasks more relevant to coordinators/lecturers or occasional
configuration. **This grouping is a UX judgment call, not a hard
requirement** — if usage data suggests students check Groups often, or
coordinators rarely touch Topic Directory from a phone, the `primary_names`
list below is a one-line change.

**Implementation, based on the current `show.html.erb` tab-building code:**

```erb
<%
  tabs = []
  tabs << { name: "Project Details", partial: "courses/project_details_tab" }
  tabs << { name: "To Review", partial: "courses/to_review_tab" }
  if @current_user_enrolment&.coordinator? || @current_user_enrolment&.lecturer?
    tabs << { name: "Supervised Projects", partial: "courses/supervised_projects_tab" }
  end
  tabs << { name: "Topic Directory", partial: "courses/topic_directory_tab" }
  tabs << { name: "People", partial: "courses/people_tab" }
  tabs << { name: "Groups", partial: "courses/groups_tab" }

  primary_names = ["Project Details", "To Review", "Topic Directory", "People"]
  overflow_tabs = tabs.reject { |t| primary_names.include?(t[:name]) }
%>

<div class="border-b border-[#E0E0E0] px-6 pt-4">
  <div data-controller="tab-fade">
    <div data-testid="content-tabs"
         data-tab-fade-target="scroller"
         class="flex flex-nowrap items-center gap-x-8 gap-y-1 overflow-x-auto
                [scrollbar-width:none] [&::-webkit-scrollbar]:hidden
                [-webkit-overflow-scrolling:touch]">

      <% tabs.each_with_index do |tab, index| %>
        <% is_overflow = overflow_tabs.include?(tab) %>
        <button type="button"
                data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="<%= index %>"
                style="font-family: 'Google Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500; letter-spacing: 0; line-height: 1.25rem;"
                class="pb-3 whitespace-nowrap border-b-4 transition-colors <%= is_overflow ? "hidden lg:inline-flex" : "" %>">
          <%= tab[:name] %>
        </button>
      <% end %>

      <%# Real navigation, not a tab panel — separate settings page. Inline on desktop, moves into the "More" menu below lg. %>
      <%= link_to "Settings", settings_course_path(@course),
            style: "font-family: 'Google Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500; letter-spacing: 0; line-height: 1.25rem;",
            class: "pb-3 whitespace-nowrap text-[#5F6368] hover:text-[#3C4043] border-b-4 border-transparent transition-colors hidden lg:inline-flex" %>

      <% if overflow_tabs.any? %>
        <div class="lg:hidden relative shrink-0" data-controller="dropdown">
          <button type="button" data-action="dropdown#toggle"
                  class="pb-3 whitespace-nowrap text-[#5F6368] hover:text-[#3C4043] border-b-4 border-transparent transition-colors">
            More <span aria-hidden="true">⌄</span>
          </button>
          <div data-dropdown-target="menu" class="hidden absolute right-0 top-full mt-1 min-w-[10rem] bg-white border border-[#E0E0E0] rounded-lg shadow-lg z-10">
            <% overflow_tabs.each do |tab| %>
              <button type="button" data-action="tabs#show dropdown#close" data-tabs-index-param="<%= tabs.index(tab) %>"
                      class="block w-full text-left px-4 py-2.5 text-sm text-[#3C4043] hover:bg-[#F1F3F4]">
                <%= tab[:name] %>
              </button>
            <% end %>
            <%= link_to "Settings", settings_course_path(@course),
                  class: "block px-4 py-2.5 text-sm text-[#5F6368] hover:bg-[#F1F3F4]" %>
          </div>
        </div>
      <% end %>
    </div>
    <div data-tab-fade-target="rightMask"
         class="pointer-events-none absolute right-0 top-0 h-full w-8 bg-gradient-to-l from-white to-transparent hidden"></div>
  </div>
</div>
```

**Implementation notes, spelled out because there's no diagram attached:**

- The `tabs.each_with_index` loop still renders **every** tab button in the
  DOM, in the original order, for every role and every screen width. The
  only thing that changes per breakpoint is the `hidden lg:inline-flex`
  class applied to buttons whose tab is in `overflow_tabs` — this means
  `data-tabs-index-param` values never shift, `tabs_controller.js` needs
  zero changes, and the tab-index-fix the earlier audit already confirmed
  (dynamic indices via `each_with_index`, not hardcoded `0..4`) stays
  intact.
- The overflow tabs are **rendered twice**: once inline (hidden below `lg`
  via the class above) and once inside the "More" dropdown (the whole
  dropdown wrapper is `lg:hidden`, so it disappears entirely at `lg`+).
  Both copies use the same `data-tabs-index-param` value pulled from
  `tabs.index(tab)`, so clicking either one fires the identical Stimulus
  action and switches to the identical panel. This is intentional — two
  trigger elements for the same tab index is a normal pattern here, not a
  bug, but it will look like a duplicate if someone inspects the DOM
  without this context.
- `data-controller="tab-fade"`, `data-testid="content-tabs"`,
  `data-tab-fade-target="scroller"`, and the trailing
  `data-tab-fade-target="rightMask"` div are the exact same attributes
  `_project_header.html.erb:38-65` already uses, and `tab_fade_controller.js`
  is reused completely unchanged — it just measures `scrollWidth` vs.
  `clientWidth` on the scroller and shows/hides the fade mask accordingly.
  Elements hidden via Tailwind's `hidden` class (`display: none`) don't
  contribute to `scrollWidth`, so the fade-mask math automatically reflects
  only whatever's currently visible at a given breakpoint — no changes
  needed to the controller to make it "aware" of the responsive hiding.
- `flex-nowrap` replaces `flex-wrap` on the scroller — this is what
  prevents the two-row wrapping shown in the §3.2 screenshot. Combined with
  `overflow-x-auto`, if the visible set (four primary tabs + "More" button
  on mobile, or the full set on desktop) still doesn't fit at some
  particularly narrow width or larger font size, it scrolls horizontally
  with the fade mask instead of wrapping or clipping.
- The `dropdown` Stimulus controller referenced above (`toggle` / `close`
  actions, a `menu` target) is assumed to be a small generic
  show/hide-on-click controller. **Check first** whether one already exists
  in the codebase — the earlier regression audit mentions an "Actions
  dropdown (Resend/Remove)" pattern already used on student/group rows
  (`_student_row.html.erb`, `_group_row.html.erb`); if that's backed by a
  reusable Stimulus controller, reuse it here rather than writing a second,
  near-identical one. If it's bespoke to that one dropdown, a small new
  controller for this is fine.
- Coordinates with §4.1: both the tab row and the breadcrumb key off
  Tailwind breakpoints that are already load-bearing elsewhere in this
  file — `lg` is the sidebar's existing collapse point, and `sm` is a
  tighter breakpoint used only for the breadcrumb text collapse. Don't
  introduce a third custom breakpoint for either of these; reuse what's
  already established.

---

### 4.3 Empty-state illustrations

**Component:** extract the icon-badge pattern already used at
`profile.html.erb:291-315` into a shared partial —
`app/views/shared/_empty_state.html.erb` (locals: `image:`, `title:`,
`subtitle: nil`) — centered illustration (fixed width, e.g. `w-40`) above a
bold title and an optional gray subtitle line, same typography the existing
pattern already uses. Use it at all seven spots below instead of the bare
`<p>`/`<td>` text.

**Assets:** save the chosen illustrations under
`app/assets/images/empty_states/`, renamed from the generic upload names to
something a future contributor can identify at a glance (the ten supplied
files are a matched illustration set — graduation, studying, video calls,
mentorship — well-suited to an academic tool like this one).

**Important, given this doc's no-images constraint:** the mapping below
refers to illustrations by their position in a set that was shown during
planning but is **not attached to this document**. Whoever does the asset
intake (Ticket 4) needs the actual image files or, at minimum, descriptive
filenames for each — a numeric reference like "image 7" is meaningless
without the source set in hand. Treat the "why it fits" column as the real
spec (the mood/subject each empty state needs), and the numbered
illustration references as a note for whoever already has the original
file set, not as something the implementation agent can act on directly.

**Proposed mapping** (a style call, not an engineering one — see §6, OI-3):

| Empty state | File : line | Suggested illustration subject | Why it fits |
|---|---|---|---|
| To Review — *whole tab* zero state (all three sections empty at once) | `_to_review_tab.html.erb` (new combined branch, see below) | Two graduates jumping, diplomas in hand | Celebratory "you're all caught up" — replaces two stacked text lines when there's truly nothing to review |
| To Review — Pending Proposals (partial-empty case) | `_to_review_tab.html.erb:13` | *keep as plain text* | Illustration reserved for the full-tab zero state; avoids double illustrations when only one section is empty |
| To Review — Reviewed Proposals (partial-empty case) | `_to_review_tab.html.erb:29` | *keep as plain text* | Same reasoning |
| Supervised Projects | `_supervised_projects_tab.html.erb:5` | Mentor and student working through a page together | Direct supervision theme |
| Topic Directory | `_topic_directory_tab.html.erb:22` | Student pulling a book from a shelf | Browsing/discovery — literally a library metaphor |
| People → Lecturers (new empty state, §3.3) | `_lecturers_section.html.erb` | Student on a video call with an instructor | Teaching/instructor theme |
| People → Students | `_students_table.html.erb:28` | Two students studying casually on steps | Student-life theme |
| Groups | `_groups_table.html.erb:65` | Two people collaborating over a laptop and sketch | Teamwork/collaboration theme |

Spare, unused in this pass: a busy multi-hands graduation composite image
(better suited to a big splash moment like a course-completion page than a
small in-tab empty state), a tired-at-desk image, a three-person video-call
panel image, and a form/scantron-with-clock image — keep these on hand for
a general "nothing on your dashboard yet" state or an error page later.

**To Review tab logic:** currently the three sections
(`_to_review_tab.html.erb:1-44`) each render independently — Pending
Proposals and Reviewed Proposals always render (with a text fallback when
empty), and Pending Topics is wrapped in `if @pending_topics.present?`
(line 33) so it disappears entirely when empty. Add a combined check —
`@pending_proposals.empty? && @reviewed_proposals.empty? &&
@pending_topics.blank?` — and when true, render the one full-tab
`_empty_state` illustration instead of the two separate "No X" lines (the
Pending Topics section already contributes nothing visually when empty, so
no change needed there). When only one of the three is empty, keep that
section's existing plain-text fallback — no illustration clutter next to
sections that do have content.

---

## 5. Ticket list

### Ticket 0 — Confirm the actual file boundaries (do first, small)

Before touching anything, confirm in the real checkout whether
`show.html.erb`, `_sidebar.html.erb`, and `_header.html.erb` are in fact
three separate files as listed in §1, or whether some of that markup has
been inlined together (see the boundary note in §1). This determines
whether the breadcrumb fix in §4.1 reaches all ~30 views or only
`courses/show`, which changes how the rest of this ticket list should be
prioritized and reviewed.

### Ticket 1 — Tab bar: primary/overflow split + scrolling safety net (supersedes the original Ticket 1)

Implement the design in §4.2: partition `tabs` by name into
`primary_names` vs. everything else; wrap the full visible row (all tab
buttons + Settings link + the mobile-only "More" trigger) in the
`tab-fade` / `content-tabs` / `scroller` pattern ported from
`_project_header.html.erb:38-65`, reusing `tab_fade_controller.js`
unchanged; apply `hidden lg:inline-flex` to overflow-tab buttons and to the
Settings link; add the `lg:hidden` "More" dropdown containing the overflow
tabs plus Settings. Confirm (or add) a reusable `dropdown` Stimulus
controller per the note in §4.2 rather than writing a duplicate one.

### Ticket 2 — Breadcrumb: single line, truncate, stable header height (unchanged)

`breadcrumb_helper.rb`: swap `flex-wrap` → `flex-nowrap` on the trail
container, swap the final crumb's `break-all` → `truncate flex-1 min-w-0`.
`_header.html.erb`: add `min-h-[3.5rem]` to the `<header>` (confirmed today
it has no height utility at all). Affects every view that calls
`render_custom_breadcrumbs` (~30 views, pending Ticket 0) —
regression-check a couple of the others (e.g. `projects/show`,
`topics/index`) while in there, not just `courses/show`.

### Ticket 3 — Breadcrumb: collapse to page name below `sm` (decided; supersedes the original "needs a decision" framing)

**Blocked on:** reading the actual source of `breadcrumb_helper.rb` and
`config/breadcrumbs.rb` — not reviewed as part of this doc — to find or add
a reusable accessor for "the current/last crumb's display text," per the
prerequisite note in §4.1. Do not implement this ticket by having each
view guess its own page name (e.g. `@course&.course_name`); that breaks on
every one of the ~30 non-course views sharing this header.

Once that accessor exists: hide the full trail (and the "Home" fallback)
below `sm` with `hidden sm:flex`, and add a `sm:hidden` sibling span
showing only the truncated current-page name, per the code outline in
§4.1.

### Ticket 4 — Shared `_empty_state` partial + asset intake

New `app/views/shared/_empty_state.html.erb` (locals: `image:`, `title:`,
`subtitle: nil`), built from the existing icon-badge markup at
`profile.html.erb:291-315`. Add the chosen illustration files under
`app/assets/images/empty_states/` with descriptive names — this requires
the actual image files or descriptive filenames in hand, per the note at
the top of §4.3; numeric "image N" references from the planning
conversation aren't independently actionable.

### Ticket 5 — Wire the empty-state partial into the six existing spots

`_to_review_tab.html.erb:13`, `:29`; `_supervised_projects_tab.html.erb:5`;
`_topic_directory_tab.html.erb:22`; `_students_table.html.erb:28`;
`_groups_table.html.erb:65` (keep both the filtered and unfiltered message
variants, just illustrated).

### Ticket 6 — To Review tab: combined full-tab zero state

Add the `all three empty?` branch described in §4.3; falls back to the
existing per-section text when only one side is empty.

### Ticket 7 — Bonus: add the missing Lecturers empty state

`_lecturers_section.html.erb` gets an `if lecturers.any?` guard around the
list (line 22) and an `_empty_state` fallback, matching the other five.

### Ticket 8 — Tests

- New/adapted system test for the tab bar at 360px covering **both** roles:
  assert a student sees exactly four inline tabs plus a "More" trigger, and
  that opening "More" reveals Groups and Settings (two items); assert a
  coordinator/lecturer sees the same four inline tabs plus "More", and that
  opening it reveals Supervised Projects, Groups, and Settings (three
  items). Also assert no page-level horizontal overflow, and that the
  visible row itself scrolls (doesn't wrap) if artificially shrunk further
  or with larger text sizing — porting the assertion style from
  `mobile_overflow_test.rb:98-158`.
- Assert that at `lg`+, all tabs render inline with no "More" button
  present, for both roles.
- Extend `course_tabs_test.rb` (or a new file) with a breadcrumb assertion:
  header height doesn't change between a short- and a long-name course
  (mirrors the existing `wait_for_stable_metrics` idiom); and, separately,
  a test at a sub-`sm` viewport asserting the full crumb trail is hidden
  and only the truncated page name shows.
- One system test per tab confirming the empty-state illustration renders
  when the relevant collection is empty, and doesn't when it isn't.

### Build order

```
0 → 1 (independent) → 8 (tab-bar tests)
0 → 2 → 3 (breadcrumb; 3 is blocked on reading breadcrumb_helper.rb) → 8 (breadcrumb tests)
4 → 5 → 6 → 7 (empty states; independent of 1/2/3, can run in parallel)
```

Ticket 0 is a five-minute sanity check that should happen before anything
else. Tickets 1 and 2–3 touch different files and can happen in either
order or in parallel, same as before. Ticket 3 specifically cannot start
until `breadcrumb_helper.rb`/`config/breadcrumbs.rb` have been read. Ticket
4 (shared partial) must land before 5, 6, or 7 can use it. Tests last,
except where noted they're tied to a specific ticket above.

---

## 6. Open items — need a decision

| # | Question | Status |
|---|---|---|
| OI-1 | Breadcrumb: truncate-only, or also collapse below `sm`? | **RESOLVED** — do both: Ticket 2 (truncate at `sm`+) and Ticket 3 (collapse below `sm`) ship together, not sequenced as a stretch goal. See §0.1. |
| OI-2 | Fix `render_custom_breadcrumbs` globally (affects ~30 views) vs. fork the header just for `courses/show`? | Still open, pending Ticket 0's file-boundary check. Recommendation unchanged: global — it's already shared infrastructure. |
| OI-3 | Final illustration-to-empty-state mapping (§4.3 table) | Still open — a style call, not an engineering one. Blocked on having the actual image set or descriptive filenames in hand (see §4.3). |
| OI-4 | Ship the illustrations as the provided PNGs, or re-export as SVG? | Still open. PNG@2x is fine to start (no existing SVG source for this set); revisit if the illustration library's vector source turns out to be available. |
| OI-5 (new) | Does `breadcrumb_helper.rb` / `config/breadcrumbs.rb` already expose the current/last crumb's display text as a reusable value? | Open, blocking Ticket 3. Needs someone with repo access to check before that ticket's diff is written. |
| — | Tab bar: permanent 4-tab merge (Settings → header icon, Groups → People) vs. responsive "More" menu keeping all 7 destinations at every width? | **RESOLVED** — responsive "More" menu chosen; permanent merge rejected as an out-of-scope IA change. See §0.1. |

---

## 7. How to verify

```sh
bin/rails test test/system/courses/                                    # existing + new course system tests
npx @herb-tools/linter app/views/courses/show.html.erb
npx @herb-tools/linter app/views/shared/_header.html.erb
npx @herb-tools/linter app/views/shared/_empty_state.html.erb
```

Manually: resize to 360px and to a mid-size tablet width, and separately to
a width just below and just above `lg` and just below and just above `sm`,
to see the tab "More" menu and breadcrumb collapse trigger at the right
points. Check both a student (5 tabs) and a coordinator (6 tabs) session at
each width — the "More" menu's contents differ by role, per §4.2's table.
Check a course with a very long name against one with a short name to
confirm the header no longer changes height, and that below `sm` the
header shows just the truncated name with no chevron chain.