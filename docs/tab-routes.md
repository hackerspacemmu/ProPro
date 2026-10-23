# Tabs as routes — handoff plan (ADR 0022, phases 1–3)

Status: verified against the code, 20 Oct 2026. Every item below was checked in the
repo; where the earlier draft and the code disagreed, the corrections are already
applied. Decisions are Alex's and settled — do not reopen them.

## Decisions (all phases)

- Three phases, three PRs: (1) course tab routes correction, (2) project tabs, (3) topic tabs.
- Tabs are routes, plain Turbo Drive links, no Turbo Frames (ADR 0019).
- Compare Versions is a singular resource `version_comparison`, controllers
  `project_version_comparisons` / `topic_version_comparisons`.
- Progress Updates tab is `progress_updates#index`.
- No `Projects::`/`Topics::` namespaces.
- Participant profiles move to `people#show`/`groups#show`; authorization
  `authorize @course, :show?` + course-scoped lookup (deliberate behavior change —
  closes the non-enrolled-viewer hole; call out in the PR).
- Old profile URLs: no redirect. No persisted profile links exist in mailers/invites (verified).
- `from_participant`/`participant_type` are deleted app-wide (only the project crumb
  ever read them).
- The project crumb's profile parent links the real profile path (replacing the `'#'` dead link).
- Lecturer-nested `projects` and `topics` routes: delete both; switch their few call
  sites to the canonical course paths. Breadcrumbs become Course > Project / Course > Topic (accepted).
- Comment create/soft_delete: `redirect_back(fallback_location: course_project_path(..., version: ...), allow_other_host: false)`.
- Dead `show_progress_tab?` helper: delete.
- Scope discipline: nothing beyond the named concern/before_action; list all other
  canonical-route outliers in ADR 0022 as known debt.

---

## Phase 1 — course tab routes correction

### Routes

```ruby
resources :courses, only: %i[index show new create destroy] do
  # participant_profile member route DELETED
  resources :people, only: %i[index show]
  resources :groups, only: %i[index show]
end
```

Helpers: `course_person_path(course, id)` — id is the **user id**;
`course_group_path(course, id)` — id is the **project_group id**.

### Work

1. `PeopleController#show` = student branch, `GroupsController#show` = group branch of
   today's `courses#profile`. Both: `authorize @course, :show?`; `groups#show` also
   `ensure_grouped` → 404.
2. Course-scoped lookups only: `@course.students.find(params[:id])`
   (invited/unregistered students resolve — they are enrolled users with
   `has_registered == false`) and `@course.project_groups.find(params[:id])`.
   Other-course participants 404.
3. Split the monolithic `courses/profile.html.erb` into `people/show` + `groups/show`;
   keep the shell (`bg-surface-tint`, inline sidebar, `rounded-tl-panel`, centered
   `max-w-5xl`) and the coordinator-only Remove From Course check. Drop the dead
   `@project`/`@grouped` ivars and the `PROFILE PARAMS` logger.
4. Replace all 11 `participant_profile_course_path` call sites: `_student_row` (2),
   `_group_row` (1), profile group-members list (1, moves into groups/show),
   `projects/_project_overview` (3), `topics/_topic_overview` (2),
   `enrolments_controller.rb:36` rescue → `course_person_path(params[:course_id], user_id)`
   (the `user_id` local already exists).
5. Delete the participant params: the profile's Current Project links become plain
   `course_project_path(@course, @project)`; remove the `from_participant` branch of
   `crumb :project` (breadcrumbs.rb:77-83); fix the `_list_item` comment; drop the
   glossary term *participant-scoped project link*.
6. Breadcrumb: `crumb :course_participant_profile` links `course_person_path`/
   `course_group_path` from the params it already receives (replaces `'#'`).
7. Delete `courses#profile` + the route. No policy method exists to delete.
8. Start ADR 0022. Update glossary: *participant profile*, *profile entry points*
   (extended list incl. project/topic overview owner/submitter links), drop the
   dangling "(ADR 0016)" (no such file exists).

---

## Phase 2 — project tabs

### Routes

```ruby
resources :projects, only: %i[show edit update create new] do
  member { patch :change_status }
  collection do
    get 'selected_topic', to: 'projects#selected_topic'
    get 'selected_topic_edit', to: 'projects#selected_topic_edit'
  end
  resource  :version_comparison, only: :show, controller: 'project_version_comparisons'
  resources :progress_updates,   only: %i[index create update destroy]
end
# DELETE: resources :projects, only: [:show], controller: 'projects' under lecturers
```

Switch the 3 `course_lecturer_project_path` links in `lecturers/show.html.erb`
(194, 227, 246) to `course_project_path`.

### Work

1. **Shared concern** (ParticipantBrowsing style): instance ordering, `?version=`
   resolution/clamping, compare-pair selection
   (projects_controller.rb:41-50 — duplicated verbatim in topics_controller.rb:89-100),
   members, comments, `@new_comment`. Each action loads only its own data:
   show → current fields; `version_comparison#show` → compare pair;
   `progress_updates#index` → `@progress`/`@weeks`.
2. `authorize @project, :show?` in both new actions (never bare).
3. `progress_updates#index` raises `RecordNotFound` when `!@course.use_progress_updates`
   (the gate is the flag alone); tab link renders only when the flag is on;
   Record/Edit buttons keep `can_record_progress_update?`.
4. create/update/destroy keep flash-alert-on-failure + redirect, retargeted to
   `course_project_progress_updates_path(course, project, version: ...)`.
5. `comments#create`/`#soft_delete`: `redirect_back(fallback_location: ..., allow_other_host: false)`.
6. **Views**: `projects/_tab_shell` (sidebar, capped-height left pane, sticky header
   slot, comments drawer + backdrop, review card, review action bar,
   `#panel-<slug>`; `keydown.esc@window→comments-drawer#closeOnEscape` moves here
   from `<main>`); link-based `_tab_strip` mirroring `courses/_tab_strip` (`nav`,
   `aria-current="page"`, no `role="tablist"`), keeping `data-testid="content-tabs"`,
   `tab-<slug>` ids, tab-fade scroller/mask, comments trigger. Three thin templates:
   `show`, `version_comparison/show`, `progress_updates/index`. `_project_header`
   keeps flash + trigger; tabs become links. Both progress dialogs move onto the
   progress page.
7. **Version switching**: `version_select_controller.js` navigates to
   `window.location.pathname + '?version=' + v`; drop its static values and the
   data-attrs in `_review_actions`; arrows build with `url_for(version: x)`.
8. Tab hrefs carry `?version=` only.
9. Cleanup: tabs wiring + `propro_tab_project_<id>` cookie out of projects/show;
   delete `show_progress_tab?`; `tabs_controller.js` + `current_tab_index` stay for
   topics until phase 3.
10. Amend ADR 0019's "what keeps the old controller" note; continue ADR 0022.
    Glossary: *content tabs*, *review card*, *review action bar*, *comments drawer*,
    *progress update dialog*.

---

## Phase 3 — topic tabs

### Routes

```ruby
resources :topics, only: %i[index show edit update create new destroy] do
  member { patch :change_status }
  resource :version_comparison, only: :show, controller: 'topic_version_comparisons'
end
# DELETE: the entire lecturer-nested resources :topics block
```

Switch `_topic_item.html.erb:8` (lecturer branch) to `course_topic_path(course, topic)`;
keep the `from_new_project`/`from_edit_project` params on the other branches.

### Work

1. `TopicVersionComparisonsController#show`: own `set_course`/`set_topic`
   (redirect-with-alert shape) + `toggle_topics` gate + `authorize @topic, :show?`.
   Set `@is_coordinator` (source-diff gate + `_topic_comments` ivar leak) and
   `@is_student` (comments restriction).
2. Reuse the phase-2 compare concern. Split topics#show: Details keeps current
   fields; compare moves the whole panel **including the source-vs-version-1 diff
   branch** (single-version copies, coordinator/owner only). Delete the dead
   `has_actions` block and unused `@project`/`@fields`/`@lecturer`/`@owner`/`@status` ivars.
3. `topics/_tab_shell` + `_tab_strip` for two tabs, same preserved selectors as
   projects. Rework `_context_header` like `_project_header`.
4. Topics' existing prev/next arrows (they exist — do not add or remove) switch to
   `url_for(version: x)`.
5. Delete `tabs_controller.js`, `current_tab_index`, `propro_tab_topic_<id>` cookie,
   tabs wiring (topics was the last consumer). Delete the dead `crumb :topic`
   lecturer branch. Amend ADR 0019 note to resolved; finish ADR 0022.

---

## Tests

Convention: slim controller tests, one behavior each, no presentation assertions.
Only what below changes or is added — everything else must pass untouched; if a test
outside this list breaks, the diff drifted.

### Phase 1

**Delete** (`courses_controller_test.rb`): the six profile tests (573–665).

**Rewrite** (slim, in `people_controller_test.rb` / `groups_controller_test.rb` —
new files if none exist):

| # | Test | Why |
|---|------|-----|
| 1 | Enrolled user gets 200 on `people#show` | baseline |
| 2 | Enrolled user gets 200 on `groups#show` | baseline |
| 3 | Non-enrolled user → redirect to `dashboard_path` with alert, `people#show` | **new** — the security fix |
| 4 | Participant from another course → 404, `people#show` | **new** — proves course-scoped lookup |
| 5 | `groups#show` 404s on a non-grouped course | parity with index |
| 6 | Invited (unregistered) student resolves on `people#show` | glossary guarantee |
| 7 | Remove From Course renders only for coordinators (one `assert_select` present/absent pair) | policy-driven visibility |

**Update**: `courses_controller_test.rb:317-343` — the two link assertions switch to
`course_group_path` (same pages, same selectors).

### Phase 2

**Add**:

| # | Test | File | Why |
|---|------|------|-----|
| 8 | Click Compare → URL changes + browser back restores Details (one test, both tabs) | `test/system/projects/project_tab_navigation_test.rb` (new, modelled on `course_tab_navigation_test.rb`) | the core route-per-tab guard |
| 9 | `create` success redirects to the progress index | `test/controllers/progress_updates_controller_test.rb` (new) | redirect retarget |
| 10 | `create` with invalid params → flash alert + redirect to the progress index | same | preserves the failure path |
| 11 | `comments#create` with a Referer redirects back to it | `test/controllers/comments_controller_test.rb` (add, or new) | the redirect_back behavior |
| 12 | `comments#create` without a Referer falls back to `course_project_path(..., version:)` | same | the fallback half |
| 13 | Selecting a version while on Compare stays on Compare | add 1 test to `project_versioning_test.rb` | guards the version-select fix |

**Verify untouched** (selector preservation is the contract): `tabs_sticky_test.rb:143-156`,
`mobile_overflow_test.rb`, `change_status_test.rb:22`. If any of these need edits,
stop and reassess.

### Phase 3

**Add**:

| # | Test | File | Why |
|---|------|------|-----|
| 14 | Click Compare → URL changes + back restores Details | `test/system/topics/topic_tab_navigation_test.rb` (new) | no navigation guard exists for topics |

**Update**:

| # | File | Change |
|---|------|--------|
| 15 | `copy_topic_dialog_test.rb:176-178` | `click_button 'Compare Versions'` → `click_link` + `assert_current_path`; drop the `aria-selected` JS fallback |
| 16 | `topic_versioning_test.rb` header comment (3-6) | rewrite: navigation is now pathname-based, not hardcoded `/topics/:id` |

**Verify untouched**: `tabs_sticky_test.rb:158-170` (topics sticky), the existing
`topic_versioning_test` select/chevron tests (they assert paths and `a`/`button` arrows
that all still exist).

Not tested on purpose: the compare concern's pair-selection logic (it moves verbatim;
existing versioning tests exercise it through the page), version preservation on tab
hrefs beyond tests 13 (the navigation tests click from the default state —
acceptable), `topic_version_comparisons` authorization (mirrors two already-tested
patterns; a non-viewer gets the same policy redirect as show).

---

## PR checks (each phase)

- `bin/rails routes > before.txt` / `> after.txt`, diff — only intended changes.
- Grep every removed helper (`participant_profile_course_path`,
  `course_lecturer_project_path`, `course_lecturer_topic_path`, `current_tab_index`,
  `show_progress_tab?`) across `app/`, `test/`, `config/`, JS before deleting.
- Full suite incl. system tests; manual back/forward + version-switch click-through on
  each migrated page.

## Known debt → ADR 0022

The ~35 non-canonical routes from the whole-app audit (courses member actions,
user/* hand-written routes, `change_status`, promote/demote, project-group
confirm/revert/lock/unlock/promote_leader, invite accept/decline, `invite`,
three-level nesting under `project_groups`, groups/project_groups naming overlap) —
untouched, listed only. Plus: `ProgressUpdatesController`'s hand-rolled
`supervisor_access` (no Pundit), global `ProgressUpdate.find`, no flag check on
writes; `set_project`/`set_topic` redirect instead of 404. ADR 0022 states the
policy: tabs are routes; new routes follow canonical resources.
