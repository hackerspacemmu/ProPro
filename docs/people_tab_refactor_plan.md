# People / Students / Groups Refactor — Audit Prompt & Workflow

Grounded against `hackerspacemmu/ProPro`, `main` @ `8bc27f9` vs `refactor/design`
@ `bcff8fc`. Everything below is verified against the actual files, not
guessed — file:line references are included so the review agent can
re-verify. `refactor/design` currently has `_people_tab.html.erb` as a
**placeholder** (it's a straight copy of the old "Supervisors Available" +
`_participants` render + Add Students/Add Lecturers buttons, just moved
under a new tab). None of the Teachers-capacity-bar / Students-table /
Groups-table redesign exists in code yet — this doc is for that work.

---

## 0. Why audit-first, given the projects/show precedent

The projects/show redesign started from a hardcoded mockup and wired it in
afterward. That worked, but it only stayed safe because a "Query/Path Audit"
table was built *before* ticket-writing — every claimed-correct query,
association, and policy call was checked against `main` first, so the ticket
list could say "already correct, do not rebuild" with confidence.

The People/Students/Groups surface is riskier than projects/show for three
concrete reasons found while grounding this doc (not hypothetical):

1. **There's a live duplicate controller.** `ParticipantsController#index`
   and `CoursesController#show` both compute the participants list
   independently, and they've drifted — one has search/sort, the other
   doesn't (§2.1). A mockup-first pass could easily "finish" the People tab
   against whichever controller happens to be open in the editor and ship
   the other one broken.
2. **A tab-indexing bug already exists** in the exact Stimulus controller
   this new work will extend (§2.3). Adding a Groups tab without fixing it
   first will multiply the number of broken role/visibility permutations.
3. **The spec asks for a capability that doesn't exist in the backend at
   all** — removing a student from a group without unenrolling them (§2.4).
   That's not a view refactor, it's new controller+policy surface, and it's
   easy to accidentally build as a view-only "optimistic" action that quietly
   does nothing or does the wrong thing.

So: audit first (Section 3, a ready-to-run prompt), *then* ticket the build
(Section 4).

---

## 1. Files actually in play

Confirmed via `git ls-tree` / `git show` on both branches — use these paths,
don't let the agent invent new ones:

| Layer | Path |
|---|---|
| Old combined view | `app/views/courses/_participants.html.erb` |
| Old table partial | `app/views/courses/_participants_table.html.erb` |
| Old lecturer card | `app/views/courses/_lecturers.html.erb` |
| Old lecturer section (deleted on refactor/design) | `app/views/courses/_lecturer_section.html.erb` |
| Old student section (deleted on refactor/design) | `app/views/courses/_student_section.html.erb` |
| New tab shell | `app/views/courses/show.html.erb` |
| New placeholder tab | `app/views/courses/_people_tab.html.erb` |
| Duplicate/dead controller | `app/controllers/participants_controller.rb` |
| Real controller (does the actual filtering) | `app/controllers/courses_controller.rb` (`#show`, private methods from line 838) |
| Fullpage route target | `app/views/participants/index.html.erb` → `course_participants_path` |
| View-layer helpers | `app/helpers/courses_helper.rb` |
| Capacity math | `app/services/supervisor_capacity_calculator.rb` |
| Group model | `app/models/project_group.rb`, `app/models/project_group_member.rb` |
| Group policy | `app/policies/project_group_policy.rb` |
| Course policy | `app/policies/course_policy.rb` (`manage_students?`, `manage_lecturers?`) |
| Unenroll | `app/controllers/enrolments_controller.rb#destroy` |
| Tab controller (new, shared) | `app/javascript/controllers/tabs_controller.js` |
| Routes | `config/routes.rb:65` (`resources :participants, only: [:index]`, nested under `courses`) |

---

## 2. Pre-existing findings (verified — decide on purpose, don't inherit blindly)

These are bugs/gaps that already exist on `main` and/or `refactor/design`
today. They matter for two reasons: (a) a naive branch-diff will call them
"unchanged, ignore" when they're actually landmines the new tabs are about
to build on top of, and (b) the review agent needs to *not* file these as
"regressions introduced by refactor/design" — they predate it.

### 2.1 Duplicate, drifted controllers

`participants_controller.rb#index` and `courses_controller.rb#show` both
build `@filtered_group_list`/`@filtered_student_list` for the same partial.
They've drifted:

- `courses_controller.rb` (private, from line 848) supports `search_query`
  and `sort_by`/`sort_dir` (`search_groups`, `search_students`,
  `sort_value_for_group`, `sort_value_for_student`, `sort_descending?` —
  all defined in `courses_controller.rb` itself, lines 772–835).
- `participants_controller.rb#index` only supports `status_filter` and
  `lecturer_filter`. No search, no sort.

But `_participants_table.html.erb`'s column-header sort links (`hx-get`)
always target `course_url(@course)` — i.e. `CoursesController#show` —
**regardless of which controller rendered the page they're sitting in.**
On the fullpage `/courses/:id/participants` route (rendered by
`ParticipantsController#index` via `views/participants/index.html.erb`),
clicking a sort header silently navigates the user back to the course page.

### 2.2 Fullpage view depends on ivars its own controller doesn't set

`_participants.html.erb`'s `fullpage: true` branch reads `@lecturers`,
`@total_group_count`, `@total_student_count`. `ParticipantsController#index`
never sets any of them (only `@total_count`). It currently "works" only
because the lecturer-filter block is skipped when `@course.solo_supervisor?`
is true — for a multi-lecturer course this route would throw on
`@lecturers.each`.

### 2.3 Tab index/DOM-position mismatch (in the branch you're building on)

`tabs_controller.js` (`refactor/design`) shows/hides by **DOM position**:

```js
this.panelTargets.forEach((panel, i) => panel.classList.toggle("hidden", i !== index));
```

`courses/show.html.erb` hardcodes `data-tabs-index-param` as literal
0/1/2/3/4, and panel index 2 ("Supervised Projects") is wrapped in
`<% if @current_user_enrolment&.coordinator? || @current_user_enrolment&.lecturer? %>`.
For a plain student, that tab+panel don't render, so DOM position 2 becomes
"Topic Directory" (whose button still says `index-param="3"`) and DOM
position 3 becomes "People" (`index-param="4"`). Result for students:
clicking **Topic Directory opens the People panel**, and clicking **People
opens nothing** (no `panelTargets[4]` exists, so every panel matches
`i !== 4` and gets hidden). This needs fixing *before* a 6th tab (Groups)
is added — otherwise there's a fourth combination to get wrong.

### 2.4 No "remove from group without unenrolling" capability

`EnrolmentsController#destroy` (only destroy action that touches
enrolment/group membership) always destroys the `Enrolment` and cascades
to the group membership as a side effect (`app/controllers/enrolments_controller.rb`).
There is no route/controller/policy method anywhere in the codebase for
"remove this student from their group, keep them enrolled." The spec's
Students-tab row action "remove from group (override, independent of
unenroll)" is **new backend surface**, not a view change.

### 2.5 Helpers already read instance variables, not locals

`CoursesHelper#group_project_for(group, _course)` and
`#student_project_for(student, _course)` both accept a `course` argument
and ignore it — they read `@projects_by_owner` straight off whatever
controller rendered the current request. This is exactly the anti-pattern
the "partials as reusable components" excerpt you're working from warns
about (locals only, no instance variables) — it's baked into current code,
and it's an easy thing to copy by habit into the new Teachers/Students/Groups
partials since the existing helpers are right there to call.

### 2.6 Capacity color tiers need a ratio, not a new field

`SupervisorCapacityCalculator::LecturerCapacity` (`app/services/supervisor_capacity_calculator.rb`)
exposes `approved_count`, `effective_cap`, `pending_count`, and a binary
`at_capacity?`. The spec's 3-tier bar (green <70%, amber to full, red at/over)
can be computed in the view from `approved_count.to_f / effective_cap` —
no model change needed — but `effective_cap` can be `0` (e.g. all lecturers
excluded from auto-calc), so the partial must guard the division.

---

## 3. The audit prompt

Copy-paste this to the review/comparison agent as-is. It is scoped to
*audit only* — no implementation.

```
You are auditing the People/Students/Groups redesign area of
hackerspacemmu/ProPro. Do not write or modify any implementation code in
this pass — produce an audit document only, in the style of a
file:line-referenced evidence table.

Ground everything against actual code:
- Reference branch (source of truth for current working behavior): main
- Branch being audited: refactor/design

Scope: the participants/people surface only — i.e. everything that reads
or writes course participants (teachers, students, groups). Specifically:
- app/views/courses/_participants.html.erb
- app/views/courses/_participants_table.html.erb
- app/views/courses/_people_tab.html.erb (refactor/design only)
- app/views/courses/_lecturers.html.erb, _lecturer_section.html.erb,
  _student_section.html.erb
- app/views/participants/index.html.erb
- app/controllers/participants_controller.rb
- app/controllers/courses_controller.rb (#show and every private method it
  calls for participants filtering/sorting/searching)
- app/controllers/enrolments_controller.rb
- app/controllers/project_groups_controller.rb
- app/helpers/courses_helper.rb
- app/policies/course_policy.rb, app/policies/project_group_policy.rb
- app/services/supervisor_capacity_calculator.rb,
  supervisor_capacity_updater.rb
- app/javascript/controllers/tabs_controller.js and any controller the new
  People/Students/Groups tabs will depend on
- config/routes.rb, the courses/participants/lecturers/project_groups
  sections

For each file, produce a table row per meaningful unit (action, helper
method, policy method, partial local) with columns:
  Item | Exists on main? | Exists on refactor/design? | Status | Evidence (file:line)
Status must be one of: ✅ unchanged/reused correctly, ⚠️ partial/drifted,
❌ missing (spec needs it, no code implements it yet), 🐛 pre-existing bug
(exists on main already, not introduced by refactor/design).

Specifically verify or refute these five claims, with evidence either way:
1. ParticipantsController#index and CoursesController#show independently
   compute the same participants list and have drifted in what filters/sort
   they support.
2. views/participants/index.html.erb (the fullpage view) depends on
   instance variables that ParticipantsController#index does not set.
3. tabs_controller.js indexes tab/panel visibility by DOM position, and
   courses/show.html.erb's hardcoded data-tabs-index-param values assume a
   tab (Supervised Projects) that is conditionally absent for some roles —
   confirm whether this causes tab/panel mismatches for a student-role user,
   and state which tab param map breaks.
4. There is no existing controller action, route, or policy method for
   "remove a student from their group without unenrolling them from the
   course" — confirm this gap exists on both branches.
5. CoursesHelper#group_project_for / #student_project_for accept a `course`
   argument but read @projects_by_owner instead — confirm, and list every
   partial/helper in this area that reads an instance variable it wasn't
   passed as a local, since these are exactly the kind of implicit
   dependency that breaks when a partial gets reused somewhere new.

Then, cross-check the following NEW spec requirements against what
currently exists in the codebase (main and refactor/design). For each,
state: already supported by existing model/controller/policy code (cite
it), needs new but small backend surface (describe exactly what), or needs
a data-model change:
- Teachers list: capacity bar 3-tier color (green/amber/red) by
  approved/effective_cap ratio; pending-count tag that turns red if
  approving it would exceed cap; conditional "allocate an offset" callout
  only when auto-calculate is on and remainder > 0.
- Students tab: search by name; filter All/Ungrouped/Grouped; sortable
  name/status columns; single consolidated status badge
  (Invited/Joined/Active); row actions "remove from course" (full unenroll)
  and "remove from group" (independent of unenroll).
- Groups tab: search across project title + group name + member names;
  filter by review status (Pending/Approved/Redo/Rejected); sortable
  columns (group name, project title, status, supervisor); member column
  expand/collapse per row + a header toggle for expand/collapse-all.
- Browse Groups (separate screen) is explicitly unchanged — confirm nothing
  in refactor/design has modified app/views/project_groups/*, and that
  drafts still never surface in the Groups tab (i.e. the Groups tab's data
  source must exclude unconfirmed ProjectGroup records — check whatever
  query/scope will feed it).

Deliverable: a single markdown document, same shape as an existing "Query /
Path Audit" table plus a "known broken/dead code" list plus a "spec gap"
list. Do not propose file-by-file implementation tickets — that happens in
a separate pass once this audit is reviewed.
```

---

## 4. Build workflow (once the audit above is reviewed)

Same shape as the projects/show plan: ticket list → build order → file
operations summary → open items → tests. The ordering below is deliberate —
each ticket is picked so it can be tested in isolation before the next one
depends on it.

### Ticket 0 — Fix the tab index / DOM-position mismatch (blocking)

Fix `courses/show.html.erb` so tab/panel indices are correct regardless of
which conditional tabs render for the current role, **before** adding a
Groups tab. Two ways to do it, pick one: (a) compute indices in Ruby as the
panels are built so `data-tabs-index-param` always matches actual DOM
position, or (b) change `tabs_controller.js` to match on a stable
`data-tabs-name-param` instead of positional index. Either way, add a test
that loads the course page as a plain student and asserts each visible tab
opens its own panel — this is the regression guard for §2.3 and for every
tab added after it, including Groups.

### Ticket 1 — `remove_from_group` backend (independent, no view work)

New policy method (`ProjectGroupPolicy#remove_member?` — coordinator, or
group leader during the open grouping window, mirroring the existing
`destroy?`/`promote_leader?` gating already in that file) + a controller
action that destroys the `ProjectGroupMember` only, leaves the `Enrolment`
alone. Test this directly against the policy and controller before any
Students-tab or Groups-tab UI exists — it's small and fully decoupled from
the redesign's view work.

### Ticket 2 — Teachers list partial

Extract from `_people_tab.html.erb`'s "Supervisors Available" block into its
own partial, **locals only** (`course:`, `lecturers:`, `capacity_result:`,
`lecturer_capacity_info:` — don't reach for `@course`/`@lecturers` inside
the partial). Capacity bar computes its own ratio from
`lecturer_capacity.approved_count.to_f / lecturer_capacity.effective_cap`
with a zero-guard; three-tier color reuses the exact hexes already used for
project status (`#137333`/`#F57F17`/`#C5221F`) rather than new Tailwind
shades, per spec. Pending tag turns red when
`lecturer_capacity.pending_count + lecturer_capacity.approved_count > lecturer_capacity.effective_cap`.
Drop the static "Total Projects / Max per Lecturer" line (removed per spec);
keep the conditional offset callout, gated exactly as it is today
(`@course.supervisor_auto_calculate_enabled? && @capacity_result.remainder > 0`).

### Ticket 3 — Students tab

Reuse `courses_controller.rb`'s existing `filtered_student_list`,
`search_students`, `sort_value_for_student`, `sort_descending?` — this
machinery already does search + sort + status filter correctly on `main`;
don't reimplement it. Do **not** wire this tab's search/sort against
`ParticipantsController` (see §2.1) — pick `CoursesController#show`'s
version as the single source of truth and delete the other one in Ticket 5.
New: single consolidated status badge (Invited/Joined/Active) replacing
whatever ad hoc status logic gets reused; row actions call the existing
`EnrolmentsController#destroy` (remove from course) and the new Ticket 1
action (remove from group). Add the Ungrouped/Grouped filter as a thin
wrapper around the existing group-membership check already used to compute
`@students_with_projects`/`@students_without_projects` in
`courses_controller.rb#show` — verify in the audit whether that split is
actually "has a project" (current code) vs "is in a group" (what the filter
needs) before assuming they're the same thing; they aren't for solo-supervisor
non-grouped courses.

### Ticket 4 — Groups tab

**Before building:** resolve the open spec question — does "+Add students"
on this tab mean the page-level bulk-enroll flow (same target as Students
tab) or a per-group "add member" action that also enrolls on first use? This
changes the policy gating and the controller action, not just a button
label — don't guess it into the view and pave over the ambiguity. Build
the table on the existing `filtered_group_list`/`search_groups`/
`sort_value_for_group` and confirm the audit's finding on whether drafts
are excluded from whatever scope feeds this list (Browse Groups drafts must
never appear here, per spec — check `ProjectGroup` for a `confirmed`
scope/column and make sure the Groups-tab query filters on it explicitly,
don't rely on it "just not happening to include drafts" incidentally).
Member column: collapsed avatar stack + count, expand per row via a small
Stimulus controller (new, generic — don't hardcode to this table if it can
be reused for the header's expand/collapse-all).

### Ticket 5 — Delete dead code

- `app/controllers/participants_controller.rb` + its route
  (`resources :participants, only: [:index]`) + `app/views/participants/index.html.erb`
  — once Students/Groups tabs fully replace what the fullpage view did.
  Confirm nothing else links to `course_participants_path` first.
- `app/views/courses/_participants.html.erb`, `_participants_table.html.erb`
  — superseded by the Students/Groups tab partials.
- `app/views/courses/_lecturer_section.html.erb`, `_student_section.html.erb`
  — already deleted on `refactor/design`; confirm nothing on `main`-only
  code paths still references them before merging.

> **Deferred (ADR-011, future session):** select-all, bulk remove, and bulk
> send-email are intentionally NOT built in this refactor. The Students table is
> single-select only; the Actions dropdown acts on the one selected row
> (Email = client-side `mailto:`, Remove = existing
> `EnrolmentsController#destroy`). Do not "complete" the mockup's bulk UI
> without revisiting `docs/adr/0011-defer-bulk-student-actions.md`.

### File operations summary

| Type | Path |
|---|---|
| New | `app/views/courses/_teachers_list.html.erb` (locals: `course`, `lecturers`, `capacity_result`, `lecturer_capacity_info`) |
| New | `app/views/courses/_students_tab.html.erb`, `_students_row.html.erb` |
| New | `app/views/courses/_groups_tab.html.erb`, `_groups_row.html.erb` |
| New | policy method on `ProjectGroupPolicy` + controller action for remove-from-group |
| New | Stimulus controller for row-level member expand/collapse (+ header toggle) |
| Modify | `app/views/courses/show.html.erb` — fix index/DOM mismatch (Ticket 0), add Groups as its own top-level tab, replace People-tab People-only content with People (Teachers) + separate Students/Groups tabs per spec |
| Modify | `app/views/courses/_people_tab.html.erb` → becomes just the Teachers list render, per spec ("People holds Teachers + Students only" — re-check this against "Groups is its own top-level tab" wording; confirm with whoever owns the spec whether Students also moves out of People into its own tab or stays inside People as a sub-section, since the tab list at the top of the spec lists People and Groups as siblings but the People description says "holds Teachers + Students") |
| Delete | `app/controllers/participants_controller.rb`, its route, `app/views/participants/index.html.erb` |
| Delete | `app/views/courses/_participants.html.erb`, `_participants_table.html.erb` |
| Untouched | `app/views/project_groups/*` (Browse Groups screen — spec says unchanged) |

> Flag before Ticket 4: the spec text has an internal inconsistency worth
> resolving with whoever wrote it — the tab list says
> `People / Groups / Settings` (Groups as a sibling top-level tab), but the
> "People" section header says "People holds Teachers + Students only,"
> which would make Students a sub-section of People, not its own tab. Ticket
> 3 above assumes Students is reachable somewhere under People and Groups is
> the only new top-level tab; confirm this before building the tab shell in
> Ticket 0/4 so the index-fix isn't done against the wrong tab count.

### Tests to add

- System test: student-role user can open every visible tab and see the
  matching panel (regression guard for §2.3, run before and after Ticket 0).
- Controller/policy test: remove-from-group destroys the `ProjectGroupMember`
  only, leaves `Enrolment` intact; non-leader/non-coordinator is denied.
- System test: Teachers list capacity bar renders correct color tier at
  <70%/70–99%/100%+, and at `effective_cap == 0` without raising.
- System test: Students tab search/filter/sort produce the same result set
  `CoursesController#show`'s existing private methods already produce today
  — i.e. this is a "did we actually reuse it" regression test, not just a
  new-feature test.
- System test: Groups tab never renders an unconfirmed/draft `ProjectGroup`.
- Delete-path test: after Ticket 5, `course_participants_path` and
  `ParticipantsController` are gone and nothing 404s that shouldn't.

---

## 5. Partials discipline (tie-back)

Every new partial in this ticket list is written to take **locals only** —
`course:`, `lecturers:`, `capacity_result:`, etc. — specifically because
this area already has one instance-variable-coupled anti-pattern in
production (`CoursesHelper#group_project_for`/`#student_project_for`, §2.5).
That pattern is easy to copy by habit since the helpers are sitting right
there to call; the Teachers/Students/Groups partials should call
`@projects_by_owner`-style data only if it's passed in as a local, so each
partial's dependencies are visible from its `render(..., locals: {...})`
call site instead of hidden behind a controller ivar that happens to be set
somewhere else in the request.