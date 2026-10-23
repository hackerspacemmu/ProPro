# ADR 0022 — Project and topic tabs are routes; participant profiles are routes

Date: 2026-10-20
Status: Accepted

## Context

ADR 0019 made the course tab set (Overview / Topics / People / Groups)
route-per-tab: each tab is its own URL, the strip is plain Turbo Drive links,
and the selected slug is the URL rather than a cookie. Two tab sets were left
behind on the old client-side model:

- **Project show** (`projects/show`): Project Details / Compare Versions /
  Progress Updates, switched by `tabs_controller.js` and persisted to a
  per-project cookie (`propro_tab_project_<id>`); `current_tab_index` read the
  cookie back so the server could pick the initial panel.
- **Topic show** (`topics/show`): Topic Details / Compare Versions, same
  controller, same cookie shape (`propro_tab_topic_<id>`).

The same costs ADR 0019 named for courses applied to both: the URL lied (a
version could not be linked on the Compare tab), every tab paid for every
tab's data, and the cookie was runtime state the server and client had to
agree on. The participant-profile page (`courses#profile`) compounded the
problem: it was a member route carrying `participant_id`/`participant_type`
*and* it authorized nothing — any logged-in user could read any course's
profiles — with a global `User.find` that leaked participants across courses.

## Decision

Tabs are routes, everywhere; and a participant profile is a resource, not a
member action on a course.

- **Project tabs are routes.** `projects#show` stays Details-only. Compare
  Versions becomes a singular nested resource
  (`resource :version_comparison, only: :show, controller:
  'project_version_comparisons'`), Progress Updates becomes a nested
  `resources :progress_updates, only: %i[index create update destroy]` gaining
  `:index`. The `projects/_tab_shell` + link-based `_tab_strip` carry the
  shared chrome (sidebar, capped-height left pane, sticky header slot, comments
  drawer + backdrop, review card, review action bar, `#panel-<slug>`), and the
  strip keeps the test-facing contract (`data-testid="content-tabs"`,
  `tab-<slug>` ids, tab-fade mask, comments trigger). Same for topics:
  `topic_version_comparisons#show` and a two-tab strip.
- **Tab hrefs carry `?version=` only.** The version switcher
  (`version_select_controller.js`) navigates to
  `window.location.pathname + '?version=' + v`, so selecting a version stays on
  the current tab; the previous/next chevrons build their href with
  `url_for(version:)`. The controller no longer hardcodes a base path.
- **A shared compare concern.** The compare-pair selection was duplicated
  verbatim between `projects#show` and `topics#show`; it moves into one concern
  alongside the instance-ordering and `?version=` resolution logic, each action
  loading only its own data.
- **Participant profiles are routes.** `courses#profile/:participant_id/
  :participant_type` is deleted. `people#show` renders the student profile and
  `groups#show` the group profile. Both `authorize @course, :show?` and look
  the participant up **through the course** (`@course.students.find`,
  `@course.project_groups.find`), so a participant from another course 404s and
  a non-enrolled viewer is redirected to the dashboard with the standard alert.
  `groups#show` also 404s on an ungrouped course, like `groups#index`. This is
  a deliberate behavior change: it closes the "any logged-in user sees any
  course's profiles" hole. There is no redirect for the old URLs — no persisted
  profile links exist in mailers or invites (verified).
- **The participant params die with the old route.** `from_participant` /
  `participant_type` were only ever read by `crumb :project`; the crumb branch,
  the profile links that carried them, and the `_list_item` comment that
  mentioned them are all removed. Profile Current-Project links and the
  project/topic "owner"/"submitted by" links become plain
  `course_project_path` / `course_person_path` / `course_group_path`. The
  profile breadcrumb (`crumb :course_participant_profile`) links the real
  profile path instead of `'#'`.
- **Nested lecturer resources go.** The lecturer-nested `projects` (one unused
  `show`) and `topics` blocks existed only to give a Course > Lecturer > Project
  / Topic breadcrumb to a handful of rows. Both are deleted; the rows link the
  canonical course paths and breadcrumb Course > Project / Course > Topic.
- **Comments redirect back.** `comments#create` / `#soft_delete` use
  `redirect_back(fallback_location: course_project_path(..., version: ...),
  allow_other_host: false)` so a comment posted from any tab returns there.
- **Dead code.** `tabs_controller.js`, `current_tab_index`,
  `show_progress_tab?`, and both `propro_tab_*` cookies are deleted once topics
  is the last consumer gone.

## Consequences

- Every project and topic tab is linkable, bookmarkable, and
  back/forward-navigable; a version can be linked while on any tab.
- Each tab page loads only its own data instead of every tab's.
- Participant profiles are properly authorized and course-scoped; invited
  (unregistered) students still resolve.
- Obsolete `docs/revert_copy_topic.md` and the deletion of the participant
  route's dead branches reduce surface area.

## Known debt (out of scope, listed only)

A whole-app route audit found ~35 non-canonical routes left alone here:
courses member actions (`add_students`, `handle_settings`, `grouping_preview`,
`export_csv`, `details`, …), hand-written `user/*` routes, `change_status` as a
member PATCH, promote/demote, project-group confirm/revert/lock/unlock/
promote_leader, invite accept/decline, `invite`, three-level nesting under
`project_groups`, and the `groups` / `project_groups` naming overlap.
`ProgressUpdatesController` still uses a hand-rolled `supervisor_access` (no
Pundit), a global `ProgressUpdate.find`, and no flag check on writes;
`set_project` / `set_topic` redirect with an alert rather than 404. New routes
follow canonical resources; these are the backlog.

## References

- ADR 0019 — course tabs are routes (the pattern this extends; its "what keeps
  the old controller" note is resolved here)
- ADR 0015 — server-rendered fragment swapping
- `docs/tab-routes.md` — the three-phase implementation plan
