# ProPro Grouping: UI Gap Analysis (Overview + Groups tab mockups)

Branch `feat/student-grouping-crud`, read at HEAD `4bb76b57` (mockups/plan update). Compared: the hardcoded `Overview` and `Groups tab` mockups against the repo, using `MASTER_IMPLEMENTATION_PLAN.md` (rev 9), `app/assets/tailwind/application.css` tokens and the `/styleguide` page. Static read only: the suite and the app were not run.

Status: DECIDED. The answers are recorded in `MASTER_IMPLEMENTATION_PLAN.md` rev 10; this doc's section 8 is deleted (a `Q#` reference points at an answer that now lives in the plan). This doc is the implementation work list; PRs 1–7 of its work order are built in the working tree, uncommitted, tests included.

## 0. How to read this doc

- **Gap** = something the mockup shows (or a plan item the mockup implies) that the repo does not do, or does differently.
- Each gap has an ID: `X` cross-cutting, `OV` Overview, `GT` Groups tab, `MM` Manage modal, `WG` wiring/backend the UI depends on, `PD` plan doc corrections.
- "Reuse" names the existing partial/controller/helper the implementation agent must use instead of writing new code.
- Tags: **Answered (Q#)** means the decision is recorded in the plan (rev 10); it is no longer blocked. **PROPOSED** appears only where the text records a rejected alternative, not as pending scope.

## 1. Scope of this pass

In scope (UI side of plan items O11, O14, D6 and D30, plus 1d entry points):

1. Overview, staff: new "Group formation" section.
2. Overview, student: new "My Group" section; "My Submission" gating (O14).
3. Groups tab: not confirmed groups (list scope, status badge, filter, row highlight), closed-window banner, "Group formation" button, "Manage" column.
4. Manage modal on the Groups tab: Status section with Confirm / Reopen for coordinators.
5. The wiring those need (redirects, counts, window state, presenter fields).

Out of scope (do not touch, even if tempting):

- `group_formations/show` and its table (separate "fixed" dump, not part of these two mockups).
- D2 / `confirmable_size?` / calculator (P5, other reviewer).
- Renames (`revert` to `reopen`, `draft` filter value, `direct_` prefix, "Group dissolved" copy): P7, never in a behaviour PR.
- Request/invite flows, D29 / P4c, request expiry.
- The Project Details card (already matches the mockup, no gap) and the staff proposal sections (Supervised, Pending, Reviewed, Pending Topics).
- Fixing raw gray/green colours in existing `_group_row` / `_groups_table` (known debt #24 in `OPEN_ITEMS.md`), except lines a gap forces us to touch (Q24).
- Imported-group student UX (plan 1h item 4): no new copy or states for it.

## 2. Hard rules for the implementation agent

These restate plan section 9 and "How agents use this doc", plus what this analysis found.

1. **No new policy, gate, service, route or Pundit predicate that is not named in an answered question.** If the mockup seems to need one, stop and ask. In particular: no new `ProjectGroupPolicy` methods, no new routes, no new service classes beyond `Groups::Coordinator::Confirmer` / `Reopener` (Q7).
2. Controllers never write a group directly. Confirm/Reopen go through a lock-taking service (D20, D21).
3. No student-side behaviour change. Student confirm, reopen, join, leave, invite and kick must behave exactly as at HEAD (see section 7).
4. A rename never ships with a behaviour change (P7). New user-facing strings use the D1 vocabulary (not confirmed / reopen / Tmp / G number; never draft, revert, locked, dissolved).
5. One concern per PR. Never `git add` or `git commit`; the user stages.
6. Every fix or new behaviour lands with a test. Name tests by behaviour.
7. Do not port mockup JavaScript. The mockup scripts (`S`, `COL`, `E`, `draw()`, `openM()`, `ask()`, `alert('→ ...')`) exist only to fake state. Real behaviour comes from existing Stimulus controllers and server rendering (section 3).
8. No broad `rescue StandardError` showing `e.message` (B11).
9. Build HTML in ERB, never as concatenated strings marked `html_safe`. The mockup builds markup with template strings (`<b class="font-medium">`); use `tag.strong` / `safe_join` or plain ERB.

## 3. Cross-cutting translation rules (mockup to repo)

### X1. Illustrations are rendered, not embedded

The mockup embeds four base64 SVGs in an `ILLUS` object. None of that ships. All four already exist as assets in `app/assets/images/illustrations/` and are rendered with `image_tag` (see `shared/_empty_state`, `courses/_project_details_card`, `courses/_topic_directory_tab`).

| Mockup key | Used for | Repo asset | How |
|---|---|---|---|
| `banner` | Project Details card | `project_details_banner.svg` | Already rendered in `_project_details_card`. No work |
| `together` | Student, no group, window open | `scene_5.svg` | `render "shared/empty_state", illustration: "illustrations/scene_5.svg"` |
| `closed` | Student, no group, closed/off | `topics_disabled_banner.svg` | `illustration:` local. Reuse of a "topics disabled" asset for a groups message: Q22 |
| `noProposal` | Confirmed group, no proposal | `submission_empty_banner.svg` | Already the `illustration:` default of `shared/_empty_state` |

`scene_5.svg` is also used by `homescreen_helper.rb` for course cards. Reusing it is fine; do not copy or edit the file.

### X2. Strip everything that is mockup scaffolding

Do not ship: the "Mockup controls" `<details>`, the CDN Tailwind script and inline `tailwind.config`, the inline `:root` token block, the Google Fonts `<link>`s, the duplicated header/sidebar/tab strip (the app has `shared/_header`, `shared/_sidebar`, `courses/_tab_strip`), the `go()` / `toGroups()` alert stubs, and the sample constants (`CLOSES='30 Nov'`, `MIN=3, MAX=5, UNGROUPED=4`, the `G` array).

Link translation (every `alert('→ ...')` becomes a real helper):

| Mockup | Real target |
|---|---|
| `go('/group_formation')` | `course_group_formation_path(@course)` |
| `toGroups(filter)` | `course_groups_path(@course, status_filter: ...)` (param value: Q12) |
| `go('/settings#grouping')` | `settings_course_path(@course)`. The `#grouping` anchor does not exist in `courses/settings.html.erb` (only a `data-controller="grouping-settings"` at line 207): Q21 |
| `go('/groups/3 (Group Profile)')` | `course_group_path(@course, group)` |
| `go('projects/new')` | `new_course_project_path(@course)` |

### X3. Colour and class tokens

- Every token the mockup configures (`warning-border`, `warning-container-alt`, `warning-on-container`, `success-container`, `primary-soft`, `surface-variant-deep`, `on-surface-muted`, and so on) already exists in `app/assets/tailwind/application.css`. No new tokens are needed.
- The Overview mockup is token-only. The Groups tab mockup uses raw `gray-*`, `green-700` and `hover:bg-amber-50`. New markup must use tokens (per the styleguide), for example `bg-surface-tint`, `border-outline-variant`, `text-on-surface-variant`, `text-success`. Existing lines in `_group_row` that already use raw grays stay as they are (Q24).
- Status pill classes are fixed by styleguide section 4 (12px, `rounded`, `px-2.5 py-0.5`). The Confirmed / Not confirmed pill already exists as `group_formations/_status_pill`. Reuse it; do not copy the mockup's `pill()`.

### X4. Buttons

The mockup's `BTN / FILL / OUTLINE / SMALL / DANGER / TEXT / SECONDARY` constants map to `GroupFormationsHelper` constants (already used by `_manage_dialog`, `groups/edit`):

| Mockup | Helper constant |
|---|---|
| `FILL` | `GROUP_FILL_BUTTON` |
| `OUTLINE` | `GROUP_OUTLINE_BUTTON` |
| `SMALL` | `GROUP_SMALL_BUTTON` |
| `DANGER` | `GROUP_DANGER_TEXT_BUTTON` |
| `TEXT` | `GROUP_TEXT_BUTTON` (the Overview "Collapse all" button uses its own inline text-button classes, same look) |
| `SECONDARY` (styleguide section 5 "Discard Changes" pill, used for "Settings") | Add `GROUP_SECONDARY_BUTTON` (Q20) |
| Warning pill (`Show not confirmed`, `Review groups`) | Add `GROUP_WARNING_BUTTON` (Q20) |

### X5. Reuse map for behaviour (do not re-implement)

| Mockup behaviour | Existing mechanism |
|---|---|
| Section collapse + "Collapse all" | `collapsible-sections` controller + `courses/_section_header`. It loads expanded and keeps no state, so the mockup's initial collapsed "Pending Topics" is a mockup artifact: do not replicate |
| Group formation section | Static, not collapsible, not part of "Collapse all" |
| Row expand / member detail | `expandable-rows` controller (`data-row-id`, `data-detail-row-id`, `data-row-chevron`, toggle-all) already in `_groups_table`. Do not port the mockup's `E` set |
| Manage button + dialog | `group_formations/_manage_dialog` (modal controller, lazy Turbo Frame loading `groups#edit`). The mockup's `openM()` is exactly this, so the earlier "dialog per group vs lazy frame" question is already answered in code |
| Confirm dialogs ("Confirm anyway", "Reopen group", Remove, Delete) | `data-confirm-submit` + `confirm_dialog_controller.js` + `shared/_confirm_dialog` (used by `groups/edit` today) |
| Empty states | `shared/_empty_state` (`heading`, `description`, `cta_label`, `cta_path`, `illustration`). CTAs are real `link_to`, not buttons |
| Submission row | `shared/_list_item` (supports status pill, `border_top`, trailing block). Mockup `li()` is a copy of it |
| Filters / search / table swap | htmx (`hx-get`, `hx-include`, `#groups-table-container`), already wired. Not Turbo, not mockup JS |
| Size warning icon / banner text | `group_formations/_size_warning_icon`, `_size_warning`, `group_size_state`, `group_size_warning` |
| Flash | the app's existing flash (`courses/_flash` on the Groups page), not the mockup's `#flash` div |

**Correction to X5:** `courses/_flash` is only rendered by `courses/settings.html.erb` today. The Groups tab shell does not render it. Q8 returns Manage actions to the Groups tab, so WG15/PD15 must add it.

---

## 4. Overview gaps

The mockup's `overview()` (`course_overview.html.erb:205-229`) appends two new
pieces above the staff collapsible sections:

- staff/lecturer: `formation()` (`:146-177`),
- student: `myGroup()` (`:182-202`) followed by My Submission.

The current Overview (`courses/_overview_tab.html.erb`) has neither.

### 4.1 Staff / lecturer "Group formation" block

| ID | Gap | Mockup says | Repo today | Work | Reuse / do not invent | Blocked |
|---|---|---|---|---|---|---|
| **OV1** | The whole section is missing. | `formation()` renders `id="group-formation"` with a static header (`Group formation`), status pill and optional Settings pill, then one block. | No group-formation markup; `OverviewPresenter` has no state for it. | Add a static, non-collapsible block above the collapsible staff sections (below Project Details). Render it for coordinators and lecturers only when the course is grouped and grouping is enabled; hide it before the window opens. No Off block. | Inline header; do not use `_section_header` (it always renders a count + chevron). | **Answered (Q2, Q6, Q16)** |
| **OV2** | No formation status pill. | `Open` (success container/success), `Off` (surface variant), `Closed` (surface variant). | No equivalent. `group_formations/_status_pill` only renders `Confirmed`/`Not confirmed`. | Add a small status pill driven by `grouping_window_open?`: Open when true, Closed otherwise. No Off state; before-open hides the whole staff block. | New inline markup; do not overload `_status_pill`. | **Answered (Q6, Q18)** |
| **OV3** | No Settings link. | Coordinator-only secondary pill `Settings` → `/settings#grouping`. | No link; the settings page exists but has no anchor. | Add a secondary pill to the header right slot for coordinators. | Add `GROUP_SECONDARY_BUTTON`; add `id="grouping"` (Q20, Q21). | **Answered (Q20, Q21)** |
| **OV4** | No closed empty block. | `!open && empty` → coordinator: "Group formation is closed. Enable it to let students form groups." + `Open settings`; non-staff: "Group formation is closed." only. | No block. | Show only the closed-by-window state: coordinator copy "Group formation is closed." + `Open settings`; lecturer copy "Group formation is closed." No "Enable it" copy; disabled/before-open hides the whole staff block. | Inline; `GROUP_TEXT_BUTTON`. | **Answered (Q4, Q16)** |
| **OV5** | No coordinator attention banner. | `banner()` (coordinator only, `!open`, `nc>0` or `ug>0`) **replaces** the normal block with an amber banner: bold "Group formation is closed.", `N group(s) are not confirmed, so their members cannot submit a proposal. Review and confirm them.`, optional newline + `N students are not in a group.`, and `Review groups` → Groups tab not-confirmed. | No banner. | Render the amber banner in the same slot when grouping is enabled, the window is not open, and `nc>0` or `ug>0`; it replaces the normal block. Link to the Groups tab `draft` filter. | Tokens (`border-warning-border`, `bg-warning-container-alt`, `text-warning-on-container`); add `GROUP_WARNING_BUTTON`; existing `_flash` is not this. | **Answered (Q1, Q4, Q20)** |
| **OV6** | No normal block/progress/meta. | Normal block: title (below), optional thin bar (`conf/total`, max 360px, ARIA progressbar), meta line (students not in a group / every student is in a group; open-until date), and one right-side text link. | No block. | Render the headline, bar and meta when the block is shown and the banner is absent. Only show the bar when not (non-coordinator && open) and not empty. | Inline; tokens. | **Answered (Q2, Q5, Q18)** |
| **OV7** | Link target/label. | Open → `Open group formation` → formation page. Closed → `View groups` → Groups tab all. | No link. | Use the two labels and routes; there is no Off state. | Plan 1d entry points. | — |
| **OV8** | Scheduled-open state is not in the mockup. | Mockup only has `open`, `closed`, `off`; no "opens on {date}" state. | Plan 1d says "Group formation opens on {date}" with no button. The `grouping_opens_at` column was dropped by ADR 0027, so there is no before-open state. | No separate before-open state: hide the staff block before the window opens. Do not render an "opens on" line. | `Course#grouping_closes_at`; date helper only for the open-until meta. | **Answered (Q6, Q18)** |
| **OV9** | Lecturer treatment conflicts. | Mockup: `staff()` is coordinator only, so a lecturer sees the block with no Settings and no banner; for open, title "Students are forming groups." and "Open group formation"; for closed, "View groups" (and non-staff "Group formation is closed." only when empty). | No block. Plan 1d says "Lecturer: same as student minus the contact line", i.e. no staff block. | Give lecturers the block with no Settings and no banner; they follow the non-coordinator copy. | — | **Answered (Q2, Q5)** |
| **OV10** | Placement/stacking. | The group-formation block sits above the collapsible staff sections; it is not one of them and has no chevron/count. | Staff sections are wrapped by `collapsible-sections` and are the only Overview state. | Keep the block outside `collapsible-sections`; do not include it in Collapse all/Expand all. | Existing My Submission is the precedent for a static block. | — |
| **OV11** | Counts/window state not exposed. | Needs `total`, `nc`, `ug`, `confirmed`, `open`, `off`, `empty`, `closes_at`. | `OverviewPresenter` has none. `Course` has `ungrouped_students` (`:92`), `grouping_window_open?` (`:96`), `grouping_enabled?`, `grouping_closes_at`; counts can be derived. | Add presenter/controller methods with explicit names; compute once and pass to the partial. | `Course` methods; `project_groups.where(confirmed: false).count`. | — |

Title selection:

1. Lecturer (non-coordinator) && open → `Students are forming groups.`
2. empty → `No groups yet`
3. `nc == 0` → `1 group, confirmed` or `All N groups confirmed`
4. else → `N of M groups confirmed`

Before the window opens the staff block is not rendered at all, so there is no
"opens on" title. A coordinator sees the counts title while open; a lecturer
sees the non-coordinator open title.

Meta line:

- if not (lecturer && open):
  - `ug > 0` → `N student(s) aren't in a group yet`
  - else if not empty → `Every student is in a group`
- if open → `Open until {CLOSES}` (`grouping_closes_at`); omit when nil.

Q18 fixes the date format to the formation page's existing format and omits the
meta when `grouping_closes_at` is nil.

### 4.2 Student "My Group"

| ID | Gap | Mockup says | Repo today | Work | Reuse / do not invent | Blocked |
|---|---|---|---|---|---|---|
| **OV12** | The whole section is missing. | `myGroup(g)` renders `id="my-group"` before My Submission. No group → no My Group section at all. | No markup; a student sees only My Submission. | Add the section for students in a grouped course when `@group.present?`. | `@group` already loaded at `CoursesController#show:17`. | — |
| **OV13** | No not-confirmed card. | Full tinted card (`bg-primary-container-alt`, `data-testid="my-group-panel"`): group name, `Not confirmed` pill, hint, `MEMBERS (n of MAX)` chips (first chip has `Leader`), and one action. | None. | Render the card, tinted `bg-primary-container/40` (the mockup's `-alt` class relies on a palette the repo swaps; `/40` matches the formation page's card). | `_status_pill` for the pill; duplicate the Overview-only chip markup (do not extract); `GROUP_FILL_BUTTON` / `GROUP_OUTLINE_BUTTON`. Use `course.group_max`, not the mockup's hardcoded 5; a nil max means no maximum, so the count prints bare (D3). | **Answered (Q3, Q4, Q5, Q17)** |
| **OV14** | No confirmed slim line. | Confirmed: no card, no pill, no green. `h-14` untinted line, `MY GROUP · G001` 11px uppercase label, chips, `View group` right. My Submission follows directly. | None. | Render the slim line. | Existing `_project_overview` owner-chip language (per mockup comment); duplicate the markup here. | **Answered (Q17)** |
| **OV15** | Leader tag / chips. | Not-confirmed chips mark the first member `Leader`; confirmed chips do not. | Formation page has chip markup inline; no shared partial. | Add the `Leader` tag only in the not-confirmed card; keep member order (leader first). | `ProjectGroup#leader_id` / `#leader?(user)`. | **Answered (Q5)** |
| **OV16** | Hint copy open/closed. | Open: leader → "Confirm the group once its members are final. Only a confirmed group can start a proposal."; member → "Waiting for your leader to confirm. Only a confirmed group can start a proposal." Closed: "Group formation is closed, so {group} can't be confirmed by its members. Contact your coordinator." with a warning icon. | None. | Render the exact copy by role + window. | — | **Answered (Q4)** |
| **OV17** | Action rules. | Open + leader → `Review and confirm` (FILL) → formation. Open + member → `View group` (OUTLINE) → formation. Closed → no button. | None. | Gate on leader + open. | `ProjectGroup#leader_id`; **do not** reuse `@my_group_can_confirm` (OPEN_ITEMS #4; slated for removal). | **Answered (Q3)** |
| **OV18** | Chips are duplicated inline. | Same chip markup as formation. | `group_formations/show` renders its own chips. | Do **not** extract a shared partial. Duplicate the chip markup in the Overview My Group card/slim line; leave `group_formations/show` as is. | Existing chip classes; no new abstraction. | **Answered (Q5)** |
| **OV19** | Ordering. | My Group before My Submission. | My Submission is the only student block. | Render My Group then My Submission. | — | — |

### 4.3 Student "My Submission"

The mockup's student branch (`course_overview.html.erb:217-226`):

- no group + open → `_empty_state` `together` (scene_5), heading "You're not in
  a group yet", body "Join or create a group before you can put together a
  project proposal.", CTA "Find or create a group" → formation.
- no group + closed → `_empty_state` `closed` (topics_disabled_banner.svg per
  X1), heading "Group formation is closed", body "Contact your coordinator if
  you are not in a group yet." (no CTA).
- group confirmed + project status → one `_list_item` row.
- group confirmed + no proposal → `_empty_state` `noProposal`
  (submission_empty_banner.svg), heading "No proposal submitted yet", body
  "Your group hasn't submitted a project proposal. Once it's in, you'll see its
  review status here.", CTA "Create proposal" → `new_course_project_path`.
- group not confirmed → **My Submission is hidden entirely**; the My Group card
  carries the next step.

Repo today (`courses/_overview_tab.html.erb:22-66`):

- `:no_group` → `_empty_state` heading/body already match the mockup; CTA is
  "Browse groups" → `course_group_formation_path(@course)`; illustration is the
  default `submission_empty_banner.svg`.
- `:no_proposal` → `_empty_state` "No proposal submitted yet" with the default
  illustration and a Create CTA (copy already matches).
- project statuses → `_list_item`.
- There is no closed/no-group state and no not-confirmed gating.

| ID | Gap | Mockup says | Repo today | Work | Reuse / do not invent | Blocked |
|---|---|---|---|---|---|---|
| **OV20** | No-group CTA label and illustration differ. | `Find or create a group` + `scene_5.svg`. | `Browse groups` + default `submission_empty_banner.svg`; route already goes to formation. | Change the label and pass `illustration: "illustrations/scene_5.svg"`. Keep the existing route. Do not change the heading/body. | `shared/_empty_state`; `scene_5.svg` exists. | **Answered (Q4)** |
| **OV21** | No closed/no-group state. | "Group formation is closed" + contact line, `closed` illustration. | `:no_group` always shows the open CTA, even when the window is closed. | Add a closed branch for grouped students with no group when the window is not open (closed by date or grouping disabled). Reuse one message for both causes. | `topics_disabled_banner.svg` (Q22); no CTA. | **Answered (Q4, Q22)** |
| **OV22** | Not-confirmed group is not gated out. | My Submission is hidden entirely for a not-confirmed group. | A not-confirmed group with no project gets `:no_proposal` and a Create CTA; a not-confirmed group with a legacy project could show it. | When `@group` is present and `!@group.confirmed?`, render no My Submission section. | `ProjectGroup#confirmed?`. | **Answered (Q3)** |
| **OV23** | O14 "awaiting confirmation" copy conflicts with the mockup. | Plan O14 says the Overview shows "waiting for your group to be confirmed"; the mockup hides My Submission and puts the hint in My Group. | Neither exists. | Hide My Submission; My Group carries the hint. Do not add an awaiting-confirmation empty state. | — | **Answered (Q3)** |
| **OV24** | CTA copy difference. | "Find or create a group". | Heading/body already match; CTA is "Browse groups". | Use the mockup CTA label. Do not invent coordinator/lecturer variants. | `shared/_empty_state`. | **Answered (Q4)** |
| **OV25** | `submission_state` machine. | Needs `:no_group_open`, `:no_group_closed`, `:awaiting_confirmation`/hidden, `:no_proposal`, project statuses. | Six states, no window/confirmation state (`courses_controller.rb:739`). | Keep `:no_group` as the state for any grouped student without a group (even when grouping is disabled); the view branches on `grouping_window_open?` for the open/closed copy. Not-confirmed is hidden by the presenter, not a new submission state. Keep `nil` for staff/non-students. | — | **Answered (Q3, Q4, Q19)** |
| **OV26** | Non-grouped courses must not change. | The mockup is a grouped course; no group UI on a solo/individual course. | `submission_state_for` returns `:no_group` only when grouped + grouping enabled; otherwise `:no_proposal`. | Keep the current behavior for `!course.grouped?`; for grouped courses, return `:no_group` even when grouping is disabled. | Existing tests. | — |
| **OV27** | Proposal start is not gated. | Plan O14: a student without a confirmed group must not create a proposal. | `ProjectsController#new` has no group gate; `submission_state_for` produces `:no_proposal` for a not-confirmed group, and the CTA is a plain link. | Add the O14 gate (confirmed group required when grouped + grouping enabled; no group is always blocked in a grouped course). Redirect to the course Overview with an explanatory flash. | Q19; no new route. | **Answered (Q19)** |

### 4.4 Overview presenter/controller

| ID | Gap | Work | Blocked |
|---|---|---|---|
| **OV28** | `OverviewPresenter` only knows student/staff, Project Details and submission state. | Extend it with `course`/`group` (or explicit booleans/counts) and methods for: formation visibility, window open/closed/off, total/confirmed/unconfirmed group counts, ungrouped students, my-group present/confirmed/leader, and the refined submission state. Keep the existing API shape for `show_supervised_projects?` etc. | — |
| **OV29** | Counts can be inconsistent if recomputed in two places. | Compute once in the controller/presenter and pass to the partial; do not call `.count` from the view. | — |
| **OV30** | Role/formation audience. | Add `show_group_formation?` (coordinator or lecturer, grouped + grouping enabled + not before opens) and `show_my_group?` (student, grouped, group present). | **Answered (Q2, Q5)** |
| **OV31** | No tests for the new states. | Add presenter tests (all states) and system tests (`test/system/courses/overview_tab_test.rb`) for coordinator/lecturer/leader/member, open/closed/off, no group/not confirmed/confirmed, and no-proposal/project statuses. | — |

---

## 5. Groups tab gaps

The mockup's Groups tab (`groups_tab_mockup.html.erb`) is a server-rendered
table plus coordinator-only chrome. It does not add client-side state; the
existing htmx filter/search behavior stays.

### 5.1 Header and controls

| ID | Gap | Mockup says | Repo today | Work | Reuse / do not invent | Blocked |
|---|---|---|---|---|---|---|
| **GT1** | No Group formation button. | While `isOpen()`, a filled `Group formation` button with a `groups` icon sits top-right of the `Groups` header. | No button. | Add a full-width-on-mobile button → `course_group_formation_path` for everyone while the window is open. | `GROUP_FILL_BUTTON`; material icon. | **Answered (Q15)** |
| **GT2** | Header count uses all groups. | Count = `pl(vis().length, 'group')`, i.e. the D30 visible list. | `pluralize(@group_list.size, "group")` (line 10) = all groups, including unconfirmed while open. | Base the header count on the D30 base list (`@group_list`), before search/status filters. Keep the footer's filtered/pagination counts as they are. | `@group_list` / `@filtered_group_list` semantics (Q10, GT16). | **Answered (Q1, Q10)** |
| **GT3** | No closed/off banner. | Coordinator only, `!open` with `nc>0` or `ug>0`: amber banner with bold "Group formation is closed.", "N groups are not confirmed, so their members cannot submit a proposal. Review and confirm them.", optional "N students are not in a group.", and a white `Show not confirmed` pill. | No banner. | Add the banner above `#groups-table-container` for coordinators whenever the window is not open (including disabled/before-open) and `nc>0` or `ug>0`. Link/GET to the `draft` filter. No mockup JS. | Warning tokens; add `GROUP_WARNING_BUTTON`; `_flash` is not this. | **Answered (Q1, Q4, Q12, Q20)** |
| **GT4** | Status filter lacks Not confirmed. | Option `Not confirmed` appears only when `!isOpen()`, between All Statuses and Approved; selected value `notconf`. | Options are `all` + the five project statuses (approved, pending, redo, rejected, not_submitted). | Add the option only when the window is not open; use param value `draft`; map it to the group axis. Ignore a stale `draft` when the window is open. | `groups_with_status` extension and `PARTICIPANT_FILTER_KEYS` (WG5). | **Answered (Q1, Q12)** |
| **GT5** | The banner needs counts. | `nc` = unconfirmed groups in the visible list; `ug` = ungrouped students. | No count locals on the Groups tab. | Add `@unconfirmed_group_count`, `@ungrouped_student_count`, `@grouping_window_open`, `@grouping_enabled` to `groups#index`. | `Course#ungrouped_students`; `Course#grouping_window_open?`. | **Answered (Q1, Q10)** |
| **GT6** | No Manage column. | Coordinator only: sticky right column `w-[104px]`, `Manage` button per row, `aria-label="Manage {group}"`, `event.stopPropagation()`. The header has an `sr-only` Manage label. | No Manage column; `_groups_table` has 5 columns, `min-w-[650px]`. | Add the coordinator-only column, header and cell; render `_manage_dialog` once per row. | `group_formations/_groups_table.html.erb:58` precedent; `_manage_dialog`. | **Answered (Q11)** |
| **GT7** | Manage row click must not toggle expansion. | The mockup stops propagation. | `expandable_rows_controller` ignores clicks inside `[data-expandable-ignore]` (`:61`). | Put `data-expandable-ignore` on the Manage cell/button. | Existing pattern. | — |
| **GT8** | Mobile/table width. | `min-w-[760px]`, sticky Manage, horizontal scroll wrapper. | `min-w-[650px]`, 5 columns, no sticky. | Raise the min-width and add `sticky right-0 bg-inherit` on the Manage cells; ensure the detail row background shows through. | Sticky Manage at all widths (Q11). | **Answered (Q11)** |
| **GT9** | Coordinator `group_add`/`download` icons. | Two round icon buttons right of the filters. | Already present in `_groups_tab.html.erb` (around lines 64-79) — **not a gap**. | Keep. | — | — |
| **GT10** | Existing search/sort/lecturer filter/pagination. | Mockup keeps search, supervisor filter, sortable headers, status filter, footer count. | Implemented (htmx + `sort_header` + `participant_pagination_threshold`). | Keep; only add the new filter/count/banner. | Existing. | — |

### 5.2 Visibility and rows (D30/O11)

| ID | Gap | Mockup says | Repo today | Work | Reuse / do not invent | Blocked |
|---|---|---|---|---|---|---|
| **GT11** | Unconfirmed groups are always listed. | `vis() = isOpen() ? G.filter(g => g.c) : L()` — unconfirmed groups are listed **only when formation is not open**. `L()` is `both` (all) or `confirmed` (students-only sample). | `groups#index` always includes all groups. | When the formation window is open, exclude `confirmed: false` from the D30 base list and from its counts; coordinators use the formation page to manage them. When closed/disabled/before-open, include them. | `GroupsController#index` base list; `Course#groups_with_status`. | **Answered (Q1, Q23)** |
| **GT12** | Row status is project-status only. | `stat(g) = !g.c ? 'notconf' : g.p ? g.p[1].toLowerCase() : 'not_submitted'` — unconfirmed wins; otherwise project status. Badge: `Not confirmed` (gray), `Approved` (green), `Pending` (blue), `Redo` (amber), `Not Submitted` (gray). | `_group_row` maps only project status; a not-confirmed group with no project shows "Not Submitted". | Pass the group confirmation state separately from the project status; render Not confirmed when `!confirmed?`. Keep project statuses for confirmed rows. | `_group_row` status locals; the formation `_status_pill` is not this badge (which has a dot). | **Answered (Q14)** |
| **GT13** | Row highlight is size-invalid, not D30. | `y = banner() && !g.c` → warning background only when the coordinator banner is active and the row is unconfirmed. Separately, `bad(g)` renders the size warning icon. | `invalid = group_size_state != :ok` always paints the row and detail row warning. | Keep the existing invalid-size row paint **and** add the unconfirmed amber background only when the coordinator banner is active. Keep the size warning icon separate. | `group_size_state`, `_size_warning_icon`. | **Answered (Q1, Q13)** |
| **GT14** | The badge is interactive? | The badge is display-only; the row expands on click. | `_group_row` badge is inside the clickable row. | Keep display-only. | — | — |
| **GT15** | Detail row colspan and empty colspan. | `staff() ? 6 : 5`; the mockup's empty row uses `colspan="6"` unconditionally (a bug for non-staff). | `colspan="5"` in both the detail row (`_group_row:65`) and the table empty state (`_groups_table:43`). | Use `manage_groups ? 6 : 5` (and the same for the empty state) when the Manage column exists. | `_groups_table` locals. | **Answered (Q11)** |
| **GT16** | Header/footer count semantics. | Header = visible D30 list count; footer = `Showing {rows.length} of {all.length} groups`. | Header = all groups; footer uses `displayed_count` / `total_count` from the filtered list. | Header uses the D30 base list count (pre-filter); footer keeps the filtered/pagination counts (`displayed_count` / `total_count`). | `@group_list` vs `@filtered_group_list`; `displayed_count`/`@total_group_count`. | **Answered (Q1, Q10)** |
| **GT17** | Empty vs no-matches. | Mockup always shows "No groups match your current filters." | `_groups_table` uses `shared/table_empty_state` with `state`/`filters_active` (empty vs no-matches). | Keep the existing distinction; do not collapse it into the mockup's single line. | `table_empty_state`, `list_state`, `filters_active?`. | — |
| **GT18** | Filter auto-expand. | Mockup expands rows when `q`, filter or supervisor is active; mockup-only. | Existing `expandable_rows` expands based on `filters_active`. | Keep existing behavior; ensure the new not-confirmed filter is included in `PARTICIPANT_FILTER_KEYS`. | `ParticipantBrowsing`. | — |
| **GT19** | Raw gray/green classes. | Mockup uses raw `text-green-700`, `bg-gray-*`, `text-gray-*`. | `_groups_tab` / `_groups_table` / `_group_row` already use raw classes in many places. | Do not do a broad colour refactor; convert only lines a gap forces us to rewrite. | Q24. | **Answered (Q24)** |
| **GT20** | `status_filter` reset when the window opens. | Mockup `draw()` resets `S.filter='notconf'` to `all` when `isOpen()`. | No client state; a stale param could show an empty list. | If the window is open and the param is `draft`, ignore it (render all) server-side. | `GroupsController#index`. | **Answered (Q1, Q12)** |

---

## 6. Manage modal gaps

The existing Manage modal is `groups/edit.html.erb` loaded lazily by
`group_formations/_manage_dialog`. It already has:

- staff status pill (`groups/edit:26-30`),
- member management, add/remove, delete group, Done (`:132` ff.),
- `staff = policy(@course).manage_groups?` (`:2`),
- `leader_edit = !staff && !@group.confirmed?` (`:3`).

It does **not** have the mockup's Status section.

### 6.1 Status section

| ID | Gap | Mockup says | Repo today | Work | Reuse / do not invent | Blocked |
|---|---|---|---|---|---|---|
| **MM1** | No Status section. | Coordinator-only section at the top of the modal body: heading "Status", then either the not-confirmed pill + `Confirm group` / confirmed pill + `Reopen group`. | Only the staff pill at `groups/edit:26-30`; no actions. | Add a `Status` section before Members; fold the existing staff pill into it. It appears in the Groups-tab Manage modal and the formation-page Manage modal. | `_status_pill`, `GROUP_FILL_BUTTON`, `GROUP_SMALL_BUTTON`. | **Answered (Q7, Q9)** |
| **MM2** | No Confirm action. | Not confirmed → `Confirm group` (FILL); if size illegal → `confirmAnyway` dialog first. Copy under it: "Confirming renames Tmp to G number." | No coordinator confirm; `GroupConfirmer` is leader-centric and blocks `:window_closed`, `:already_confirmed`, `:size_illegal`. | Add `Groups::Coordinator::Confirmer` (bypasses window + size, assigns the lowest free `G` name) and wire a coordinator-only button. | Plan P4b/D6; `GroupConfirmer` as the template; `Course#lowest_free_confirmed_group_name`; `with_no_key_update_lock` + `with_group_lock`. | **Answered (Q7)** |
| **MM3** | No illegal-size override dialog. | `bad(g)` → `confirmAnyway` with title "Confirm {group} anyway?", body "This group has N members; the minimum is MIN.\n\nConfirming overrides the size limit. The group will be renamed to a G number.", ok "Confirm anyway". | No dialog. | Use the existing `data-confirm-submit` + `shared/_confirm_dialog` pattern; the body states the broken minimum or maximum (the size state decides which); do not add a new dialog controller. Confirm-bypass is a coordinator action, not a student path. | `shared/_confirm_dialog`; `_size_warning`. | **Answered (Q7)** |
| **MM4** | No Reopen action. | Confirmed + no project + not imported → `Reopen group` (SMALL); dialog "Reopen {group}?", body "The group becomes Not confirmed and is renamed to a Tmp number. Members can't start a proposal until it is confirmed again.", ok "Reopen group". | No coordinator reopen; `GroupReverter` is leader-centric and blocks `:window_closed`, `:already_draft`, `:imported_group`, `:has_project`. | Add `Groups::Coordinator::Reopener` (bypasses the window; keeps imported + has-project guards; deletes pending join requests) and wire the button. | Plan P4b/D6; `GroupReverter` as the template; `Course#lowest_free_tmp_group_name`; shared invite cleanup. | **Answered (Q7)** |
| **MM5** | Reopen visibility. | `canReopen = confirmed && !project && !origin_import`; otherwise the button is hidden (plan D9: no explanatory line). | No button. | Hide the button unless the same predicate holds; do not add copy. | `ProjectGroup#project`, `#origin_import?`. | **Answered (Q7)** |
| **MM6** | No coordinator confirm/reopen service. | The mockup mutates `g.c` and renames synchronously. | `GroupConfirmer`/`GroupReverter` are the only services; both require the window open and are leader-oriented. | Implement the coordinator variants in the same lock pattern. Do not reuse the leader services with a bypass flag. | `Groups::GroupLocking`. | **Answered (Q7)** |
| **MM7** | Route/verb. | Buttons in the modal. | `resource :confirmation, only: %i[create destroy]` under `groups`; `GroupConfirmationsController#create/#destroy` call the leader services and redirect to the formation page. | Use the same `confirmation` resource, branching by `policy(@course).manage_groups?` (coordinator) vs the leader service. No new route. | Existing route. | **Answered (Q7, Q9)** |
| **MM8** | Redirect target. | Mockup closes the modal and shows a flash; the page remains the Groups tab. | Both controller actions always redirect to `course_group_formation_path` (`:14,16,26,28`). | When invoked from the Groups tab, return to the Groups tab preserving the current filters; otherwise keep the formation page. | `url_from(params[:return_to])` with a safe fallback. | **Answered (Q8)** |
| **MM9** | Flash copy. | Success: "{old} is now confirmed as {new}." / "{old} is reopened as {new}." | `GroupConfirmer`/`GroupReverter` return a `Result` with `message`; the controller flashes `notice`/`alert`. | Reuse the service result message or set the coordinator-specific copy; keep `notice`/`alert` only. | Existing flow. | **Answered (Q7, Q8)** |
| **MM10** | Modal is only opened from the formation page today. | Manage is also on the Groups tab rows. | `_manage_dialog` is used by `group_formations/_groups_table`. | Reuse the same partial on the Groups tab; ensure the lazy `edit` URL resolves. | Existing. | — |
| **MM11** | Permissions. | Coordinator only (non-admin staff). | `ProjectGroupPolicy#confirm?`/`#revert?` already return `true` for `manage_groups?` (`:18-30`); `#edit?` allows `manage_groups?` (`:39-40`). | No new predicate. The coordinator service bypasses only the window/size, not authorization. | Existing policy. | — |
| **MM12** | Existing leader behavior. | Not shown in the mockup. | Leader confirm/revert already exist on the formation page. | Do not change their guards, copy or redirects in this pass. | Existing services/controller. | — |

---

## 7. Student-side behaviour, wiring/backend, and plan corrections

### 7.1 Student-side behaviour at HEAD (unchanged)

The six flows below must behave exactly as at HEAD. The only student-visible
changes in scope are (a) D30 hiding not-confirmed groups from the Groups tab
while formation is open, with the student's own group still shown in My Group,
and (b) the O14 proposal-start gate redirecting to the Overview. Neither changes
the flows themselves.

| Flow | Current behaviour to preserve |
|---|---|
| Leader confirms | `GroupConfirmer` (`group_confirmer.rb:14-17`): requires the window open, group not already confirmed and size legal; assigns the lowest free `G` name under both locks. |
| Leader reopens | `GroupReverter` (`group_reverter.rb:14-19`): requires the window open, group confirmed, not imported and no project; assigns the lowest free `Tmp` name. |
| Join | `GroupMembersController#create` (self-join) → `GroupJoiner`; `GroupJoinRequestsController` for requests; no change. |
| Leave | `GroupMembersController#destroy` → `Groups::Leaver`; no change. |
| Invite | `GroupInvitationsController`, `GroupInviteLinksController`, `GroupDirectInviter`, `GroupInviteLinkGenerator`; no change. |
| Kick / remove | `GroupMembersController#destroy` → `Groups::Kicker` / `Groups::Coordinator::MemberRemover`; no change. |

`ProjectGroupPolicy#confirm?` / `#revert?` already allow coordinators
(`manage_groups?`) and leaders; do not add a predicate. The coordinator services
only bypass the window/size guards, not authorization.

### 7.2 Wiring/backend items (WG)

| ID | Gap | Work | Blocked |
|---|---|---|---|
| **WG1** | Coordinator Confirm/Reopen does not exist. | Add `Groups::Coordinator::Confirmer` and `Groups::Coordinator::Reopener` (plan P4b), following `GroupConfirmer`/`GroupReverter` but bypassing only `grouping_window_open?`; keep `origin_import?` + `project.present?` guards; Confirmer may override size after the confirm-anyway dialog; Reopener deletes pending join requests; rename with `lowest_free_*_group_name`; use `with_no_key_update_lock` + `with_group_lock`; return a `Result` with `message`. | **Answered (Q7)** |
| **WG2** | Controller branching. | `GroupConfirmationsController#create/#destroy` must choose the coordinator service when `policy(@course).manage_groups?`, otherwise the existing leader service. Keep the same `confirmation` route. | **Answered (Q7, Q9)** |
| **WG3** | Groups tab visibility. | `GroupsController#index` needs the D30 base list: all groups when the window is not open (closed, disabled, before-open); confirmed-only when open. Counts and `list_state` must use that list; coordinators manage unconfirmed groups on the formation page while open. | **Answered (Q1, Q23)** |
| **WG4** | Groups tab counts/state. | Expose `grouping_window_open?`, `grouping_enabled?`, `unconfirmed_group_count`, `ungrouped_student_count`, and the visible/base group counts to `_groups_tab`/`_groups_table`. Header uses the base count; footer keeps filtered/pagination counts. | **Answered (Q1, Q10, GT16)** |
| **WG5** | Not-confirmed filter. | Extend `Course#groups_with_status` (or the controller) to filter `confirmed: false` under the `draft` param; add the param to `participant_browsing`/`PARTICIPANT_FILTER_KEYS`; ignore a stale `draft` filter when the window is open. | **Answered (Q1, Q12)** |
| **WG6** | Overview presenter. | Extend `OverviewPresenter` (or a small, named collaborator) with formation/window/counts/my-group/submission-state helpers. Keep the existing constructor/API compatible or update the tests in the same PR. | **Answered (Q2, Q3, Q5)** |
| **WG7** | `submission_state_for`. | Return `:no_group` for any grouped student without a group (even when grouping is disabled); the view branches on `grouping_window_open?` for the open/closed copy. Not-confirmed is hidden by the presenter, not a new state. Keep the existing behavior for non-grouped courses. | **Answered (Q3, Q4)** |
| **WG8** | Proposal-start gate. | Add the O14 guard in `ProjectsController#new` (and any other create entry point) for grouped + grouping enabled + no confirmed group; a no-group student in a grouped course is always blocked. Redirect to the course Overview with an explanatory flash. | **Answered (Q19)** |
| **WG9** | Anchor. | Add `id="grouping"` to the Grouping card in `courses/settings.html.erb` (section starts at line 204; controller at 207) and a scroll offset. | **Answered (Q21)** |
| **WG10** | Shared banner/copy. | The same "Group formation is closed…" copy appears on Overview and Groups tab; avoid two divergent strings. Use a helper/partial with locals (no new service). | — |
| **WG11** | Table columns/colspan. | `_groups_table` header + `colspan` (detail + empty) + `_group_row` detail colspan + width/min-width/sticky for the Manage column. | **Answered (Q11)** |
| **WG12** | Status local. | `_group_row` currently receives one `status`; add `confirmed`/`group_status` separately so the badge can choose Not confirmed vs project status without overloading `status`. | **Answered (Q14)** |
| **WG13** | Redirect/flash return. | `edit_course_group_path` receives `return_to: request.fullpath`; the Manage actions use `url_from(params[:return_to])` with a safe fallback, preserving filters/sort. Do not add a warning flash variant. | **Answered (Q8)** |
| **WG14** | Tests. | Add/extend: `test/presenters/overview_presenter_test.rb`, `test/system/courses/overview_tab_test.rb`, `test/controllers/groups_controller_test.rb`, `test/integration/group_formation_page_test.rb`, plus service/controller tests for coordinator confirm/reopen (plan T15) and O11/O14 (T18/T19). | — |
| **WG15** | Flash is not rendered on the Groups tab. | `courses/_flash` is rendered only by `courses/settings.html.erb`; the Groups tab shell does not render it. Q8 returns Manage actions to the Groups tab, so render the flash there (or emit a Turbo Stream) and keep `alert`/`notice`. Correct X5. | **Answered (Q8)** |

### 7.3 Plan-document corrections (PD)

These are discrepancies between the current plan (rev 9), the mockups and the
repo. They should be fixed when the answers land, and the plan renumbered to
rev 10.

| ID | Correction |
|---|---|
| **PD1** | Plan status is stale. Its header still says HEAD `13f5a33`, while branch HEAD is `4bb76b57`; P2b/P3a/P4 are marked TODO, but commits `cc99ea0` … `13f5a33` already touched the group-name/Tmp-G logic and policies. Rev 10 reconciles the status column at `4bb76b57`. |
| **PD2** | **1d vs the mockup on lecturers.** Rev 10 records that lecturers get the formation block without Settings/banner; they follow the non-coordinator copy. Plan 1d's "lecturer = student minus the contact line" is replaced. |
| **PD3** | **O14 vs the mockup on not-confirmed My Submission.** Rev 10 records the mockup: hide My Submission and put the hint in My Group. No "waiting for your group to be confirmed" empty state. |
| **PD4** | **D30 "formation is off" is defined.** It means the window is not open: closed by date, grouping disabled, or before-open. The mockup's `isOpen()` treats only `win === 'open'` as open, and `vis()` shows unconfirmed groups in all other cases. |
| **PD5** | **1d "one message works for both closed causes" is accepted.** The closed-by-window and grouping-disabled student messages are the same. There is no staff "Enable it" copy or Off staff block; disabled/before-open hide the staff block. |
| **PD6** | **1d scheduled open** ("Group formation opens on {date}", no button) is replaced: the staff block is hidden before the window opens; no separate title or status. |
| **PD7** | **D30/O11 row wording is fixed.** O11 now says unconfirmed rows/banner/pill/filter apply only when the window is not open; unconfirmed groups are hidden while it is open. |
| **PD8** | **O11 banner counts stay in one banner.** The unconfirmed-group sentence and the ungrouped-student sentence share one amber banner. |
| **PD9** | **O14 `projects/new` response is chosen.** Redirect to the course Overview with an explanatory flash. |
| **PD10** | **D6/P4b scope is one pass.** The coordinator services and the Status section ship together in P4b; no read-only/hidden interim state. |
| **PD11** | **1d/Overview placement is widened.** The block is static for coordinators and lecturers, not a coordinator-only summary card. |
| **PD12** | **D30 student visibility has the My Group consequence.** A student in a not-confirmed group no longer sees it on the Groups tab while formation is open, but still sees it, with members and hint, in My Group/Overview. |
| **PD13** | **OPEN_ITEMS #4/#10 are respected.** Do not build the new Overview on `@my_group_can_confirm` (slated for removal). Flash has only `alert`/`notice`; do not add a third variant. |
| **PD14** | **Button constants are added.** Add `GROUP_SECONDARY_BUTTON` and `GROUP_WARNING_BUTTON` to `GroupFormationsHelper`; use them on both surfaces. |
| **PD15** | **X5 flash claim is corrected.** `courses/_flash` is not rendered on the Groups page today (only `courses/settings.html.erb:34-35`). Add it to the Groups tab (WG15); X5 now says so. |

---

## 8. Work order

Split into these PRs; each is one concern and includes its tests. PRs 1–7
are built in the working tree, uncommitted; PR 8 is done (plan rev 10).

1. **WG/presenter foundations** — `OverviewPresenter` state/counts,
   `submission_state_for`, no view changes. Tests only.
2. **Overview: staff Group formation block** — OV1-OV11. No D30 dependency if
   counts are computed from all groups and the block is coordinator/lecturer
   only.
3. **Overview: student My Group + My Submission** — OV12-OV27, including the
   O14 gate (WG8). Depends on Q3/Q4/Q19.
4. **Groups tab: visibility + counts + badge** — GT2, GT4, GT11, GT12, GT16,
   GT20, WG3-WG5. Depends on Q1/Q10/Q12/Q14.
5. **Groups tab: banner + button + Manage column** — GT1, GT3, GT5-GT8,
   GT13, GT15, WG11. Depends on Q1/Q11/Q13/Q15.
6. **Manage Status section** — MM1-MM12, WG1/WG2/WG13/WG15. Depends on
   Q7/Q8/Q9.
7. **Settings anchor + button constants** — WG9, Q20, Q21, Q22.
8. **Plan reconciliation** — PD1-PD15, rev 10; delete the answered questions
   from this doc and leave the work list.

Do not start PR 6 before PR 1-5 unless Q7 explicitly splits the backend into its
own earlier PR.

---

## 9. Definition of done for this analysis

- Every `BLOCKED(Q#)` in sections 4-7 is answered (decisions recorded in the plan, rev 10).
- No item invents a route, policy, service or predicate beyond the plan's
  named scope.
- Every UI item names the existing component it reuses or explicitly says
  "new inline markup".
- The plan corrections in section 7.3 are applied as rev 10.
- Student confirm/reopen/join/leave/invite/kick behave exactly as at HEAD,
  except the D30 visibility change and the O14 proposal-start gate, and both
  of those have tests.
- The mockups are not modified by the implementation.
