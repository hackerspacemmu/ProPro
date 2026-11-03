# Project groups: mockup → app migration plan (frontend wiring pass)

Branch: `feat/student-grouping-crud` @ `f997a60` ("refactor: routes for grouping"). The routes refactor described in `docs/Grouping/GROUPING_ROUTES_REFACTOR.md` **is merged on the branch** (flat controllers, `resource :group_formation`, `resources :groups` with sub-resources, legacy GET redirects, tests in `test/routing/group_routes_test.rb` and `test/integration/group_write_routes_test.rb`). This plan was re-audited against it; §10 lists what that changes for the frontend.
Source of truth for look: the hardcoded mockup (`COMP6000 - Group formation | ProPro`).
Source of truth for behaviour: the existing routes, policies, services and ivars in the app.

This pass wires the mockup into Rails/Stimulus/Tailwind conventionally. Services are not touched. Everything marked **Decision** needs an answer from the owner; each has a recommended default (✱) that the agent applies if no answer arrives.

---

## 0. Ground rules for the implementing agent

1. The mockup is a visual spec only. Do not copy any of: its `<script>`, its `<style>` block, its `tailwind.config`, the "Mockup controls" `<details>`, the hardcoded `groups` / `ungrouped` / `notifs` data, inline `onclick=` / `oninput=` handlers, the `.dm` class, or the JS button-class constants (`B_FILL`, `B_TONAL`, …).
2. No new routes, params, services or policies, except the small edits listed in §4.4 (an explicit `ProjectGroupPolicy#edit?`, `groups#edit` authorizing it, and the formation page's htmx filter branch). The only controller edits allowed in this pass are the ones listed in §4.4.
3. Do not reference an instance variable that the controller does not set (§4.1 is the complete list). Derived values go in a helper or in the view, except the htmx filter state the controller must compute for its partial branch.
4. Do not invent rules. Where the mockup implies a rule the app does not have, follow the app (§4.3) and list the gap in §9.
5. Tailwind: tokens from `app/assets/tailwind/application.css` `@theme` and the `/styleguide` page only (§6). No `gray-*`, `blue-*`, `amber-*`, `red-*`, `green-*`, `zinc-*`, no hex colours, no `<style>` block.
6. Stimulus: `data-controller` / `data-action` / targets / values only. No inline JS.
7. Partials are for reusable components only, and take **strict locals** (`<%# locals: (a:, b: nil) %>`, as `shared/_empty_state` does), never instance variables. Templates (`show.html.erb`, `edit.html.erb`) may read ivars and pass them down as locals. A partial needs at least two call sites (or a server re-render entry such as a `turbo_stream` target); a long single-use block stays inline in its template with an ERB comment banner. **Owner-approved exception: modals/dialogs** may be extracted as partials even with a single caller (strict locals still apply). See §5.3.
8. The old view files are rewritten, not patched. Delete what §1 and §5.4 mark for deletion in the same PR, then run the verification greps in §7.

---

## 1. Audit: existing grouping JS controllers

"Used by (old)" = which pre-migration views reference the controller (counted from `app/views`).

| Controller | Used by (old) | Verdict | Why |
|---|---|---|---|
| `group_browse_filter_controller.js` | `project_groups/index`, `_group_card` only | **DELETE** | Hard-codes All/Draft/Confirmed tab buttons and raw `bg-zinc-900` / `text-gray-500` class toggles. The mockup replaces tabs with a status `<select>`, a "Showing X of Y" footer and empty/no-match states. Replaced by new `list_filter_controller` (§5.2). |
| `combobox_modal_controller.js` | `project_groups/index`, `_my_group_panel`, `_group_card` only (3 files, all rewritten) | **DELETE** | Select-one-then-submit combobox with a hidden `user_id` input. The mockup's pickers are per-row buttons ("Invite" / "Add") over a search list capped at 6. Replaced by `list_filter` (with `limit`) + plain `button_to` per row. |
| `warning_modal_controller.js` | `group_members/_dissolve_warning_modal`, `groups/_delete_warning_modal` | **KEEP** | Generic server-appended warning `<dialog>` (opens on connect, closes on backdrop/button). It serves the `needs_confirmation` flows in `GroupMembersController` and `GroupsController`. |
| `invite_link_controller.js` | `_my_group_panel` | **KEEP + change** | Mockup shows a "Copied" state that the controller does not have (§2). |
| `expandable_rows_controller.js` | `courses/_groups_table`, `courses/_section_header` (Topics directory) | **KEEP + additive change** | Shared with the Groups tab and Topics directory. Changes must be additive (§2). |
| `modal_controller.js` | `courses/_add_students_modal` and 9 other files | **KEEP** | Generic `<dialog>` open/close/backdropClose. Used for every dialog in the new page. |
| `search_shortcut_controller.js` | `courses/_tab_shell`, Groups tab search | **KEEP** | `/` focuses `data-search-shortcut-target="input"`. The mockup's own `/` keydown handler is deleted. |
| `dropdown_controller.js` | 12 files | **KEEP** | Reused for the notifications bell popup. |
| `sidebar_controller.js` | layout + `shared/_sidebar` | **KEEP** | The mockup's sidebar/menu code is a hand-copy of `shared/_sidebar`; use the real partial. |
| `auto_submit_controller.js` | **0 files app-wide** | **REUSE** | Currently dead. Perfect fit for the "Require approval to join" switch (`change->auto-submit#submit`). Do not delete. |
| `grouping_settings_controller.js` | `courses/settings` | **KEEP, untouched** | Course Settings → Grouping card. Not part of this pass. |
| `students_select_controller.js`, `sortable_controller.js` | People tab / template editor | untouched | Not grouping logic. |
| `dynamic_form_action_controller.js` | **0 files app-wide** | flag only | Dead, but not part of project groups. Do not delete in this PR; mention in the PR description. |

Other dead code found in the old project_groups views (do not carry over):

- `_my_group_panel` uses `form: { data: { confirm: "…" } }` for Dissolve, Revert, Leave, Promote and Kick. Turbo does not honour `data-confirm` (only `data-turbo-confirm`) and there is no rails-ujs, so **those five confirmations never showed**. The destructive actions fired immediately. The new confirm dialog (§5.2) fixes this; do not reintroduce `data-confirm`.
- The old "Ungrouped students" search box had no controller attached (inert).
- `@my_requested_group_ids` is set in `project_groups#index` but no old view read it. The mockup's "Request sent" state needs it (§4.1).

---

## 2. Existing controllers vs mockup behaviour: drift

### 2.1 `expandable_rows` (Groups tab table) vs the formation table

What the controller does today: delegated click on any `[data-row-id]` row (skips `<a>`), toggles `hidden` on the `[data-detail-row-id]` sibling and `rotate-180` on `[data-row-chevron]`; header cell `[data-expandable-toggle-all]` toggles everything (`unfold_more` / `unfold_less`, "Expand all" / "Collapse all"). It has no `aria-expanded`, and initial state is whatever the server rendered (`expanded: filters_active`).

| Behaviour | Groups tab today | Old project_groups card | Mockup |
|---|---|---|---|
| Member detail layout | single column (`flex flex-col gap-4`, `pl-[10%]`, names `truncate`) | 2-col tile grid (`grid-cols-2`, bordered tiles with student ID, leader label, hover Remove) | 2-col list (`grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-3`, `pl-0 sm:pl-[10%]`), names wrap fully (`break-words`), no ID |
| Click target | whole row | `<details>` summary | members-cell button only (row also holds Join/Manage buttons) |
| `aria-expanded` | none | native `<details>` | set on the button |
| Default state | collapsed; expanded while a filter is active | open | demo hard-codes G001 open |
| Toggle all | yes, in "Members" `<th>` | no | no |
| Collapsed summary | avatar stack (first 3) + "n members" | avatar stack (first 4) + "n/max" | avatar stack of **all** members, shown `flex sm:hidden xl:flex`; text "n of MAX members" (or "n members" with no limit) + warning icon if invalid size |
| Row structure | one `<tbody>`, two `<tr>` per group | cards | one `<tbody class="grp">` per group (needed for the mobile card layout), `tr.main` + `tr.detail` |
| Pending-registration badge + "Resend invite" | yes | no | no |
| Group name | link to group profile | plain | plain |

The controller already works with one `<tbody>` per group (it only uses `this.element.querySelector`), so the structure change needs no JS change.

**Real risk:** the formation row contains action buttons (Join / Request / Cancel request / Manage). With today's delegated handler, clicking one of those would also toggle the row. Required additive change: the controller returns early when the click is inside `[data-expandable-ignore]`; put that attribute on the action cell. (Do not use `closest("button")`: the Topics directory header is a `div role="button"` that is itself the `[data-row-id]`, so a generic button exclusion is riskier than an opt-in hook.)

Additive changes to `expandable_rows` (must not alter Topics directory or Groups tab behaviour; re-test both):
1. `[data-expandable-ignore]` early return, as above.
2. Keep `aria-expanded` in sync on an optional `[data-row-toggle]` element inside the row (the members-cell button).
3. No `setAll` method and no `list-filter:change` hook. The formation table's auto-expand is server-rendered from `@filters_active` after the htmx swap (D7); the existing htmx Groups tab already works the same way.

### 2.2 `modal`

Fine as is (`open`, `close`, `backdropClose`). Differences to handle in markup, not JS:
- The mockup's modal is a `div` overlay with its own Esc handling. Use native `<dialog>` (focus trap, Esc, `::backdrop`, and `search_shortcut` already ignores `/` while `dialog[open]`).
- Dialog must be `p-0` with an inner flex column (header / scroll body / footer), otherwise `backdropClose` misfires (it checks `event.target === dialog`). Copy the structure of `courses/_add_students_modal`.
- Mobile full-screen: `max-sm:m-0 max-sm:h-dvh max-sm:max-h-none max-sm:w-screen max-sm:max-w-none max-sm:rounded-none`, `sm:max-w-lg sm:rounded-lg sm:max-h-[85vh]`.
- Lazy Manage frame (D5): add an additive `reset()` method to `modal_controller` (bound with `close->modal#reset` on the dialog) that restores the placeholder markup of any `[data-modal-target="frame"]` and removes its `src`/`complete` attributes. Precedent: `overlay_controller#returnToList` and `copy_topic_overlay` (dialog + `overlay_content` turbo frame).
- A `modal` controller needs its `dialog` target inside its own element. Pattern: wrap trigger + `<dialog>` together (e.g. a `<div data-controller="modal">` in the row's action cell for "Manage", one in the header for "students without a group").

### 2.3 `invite_link`

Today: copies the field, no feedback. Mockup: button text becomes "Copied". Add a `button` target and a 2 s label swap; fall back to `select()` when `navigator.clipboard` is unavailable.
Copy text: the mockup says "Link expires in 24 hours". `GroupInviteLinkGenerator` sets `expires_at: 24.hours.from_now` at generation, and `@my_group_invite_token` only carries the token (not the expiry, and it returns expired tokens too). Use **"Link expires 24 hours after it's generated."** (no new ivar).
The mockup shows a link always present. The real state machine is: no link yet → "Generate invite link" (PATCH `generate_invite_link`); link exists → input + Copy + "Generate new link" (same PATCH; it replaces the old link). Implement both states.

### 2.4 `dropdown` (bell)

Works for toggle / click-outside / close-others. Missing vs mockup: Esc to close. Add `keydown.esc@window->dropdown#close` as a `data-action` on the bell wrapper (no controller change needed; `close()` already exists). Mobile full-width positioning is CSS only (§6.2).

### 2.5 `flash`

The mockup's `showMsg` has info / warn / success / error variants and is dismiss-only. The app's `courses/_flash` has only `alert` (red) and `notice` (green) and auto-dismisses after 5 s (`persistent` value exists). Services only produce notice/alert. See **D10**.

### 2.6 `search_shortcut`

Page must live inside an element carrying `data-controller="search-shortcut"` (the `courses/_tab_shell` `<main>`), and the search input needs `data-search-shortcut-target="input"` and the `<kbd>/</kbd>` badge markup from `courses/_groups_tab`. Delete the mockup's `keydown '/'` listener.

---

## 3. Decisions

Status: D1–D7 are **decided by the owner** (text below is final). D8–D12 have safe defaults the agent applies unless told otherwise. Q1 and Q2 in D5 are decided.

**D1. Page chrome / tab strip. DECIDED.**
The formation page renders `courses/tab_shell` with a tab strip that has **only one tab, "Group formation"**, active. It is deliberately different from the four course tabs (it is one route deeper than them). `_tab_strip` gets an optional `tabs:` local; `_tab_shell` gets optional `tabs:` and `breadcrumb:` locals, both defaulting to today's course behaviour. Formation passes a single tab entry and `breadcrumb: :group_formation`. The four normal tabs are not shown here (breadcrumb + sidebar get you back). Coordinator icons follow the real shell (`lg`, gear in the header below `sm`), not the mockup's `sm`.

**D2. Closed or disabled grouping. DECIDED.**
When `!@course.grouping_window_open?` the page keeps its shell, h1 and rules line, and replaces the toolbar, my-group card and table with `shared/_empty_state` (styleguide §8: illustration + heading + description, no CTA). Heading: **"Grouping is closed by your coordinator"**; description is the agent's wording (one short sentence, e.g. where to see existing groups: the Groups tab). No policy change (`CoursePolicy#grouping?` stays as is). Consequences to be aware of:
- `grouping_window_open?` is also false **before** `grouping_opens_at` and when the coordinator has `grouping_open` off, so the same copy shows in those cases; "by your coordinator" is slightly off for a not-yet-open date window. Leave it, note it in the PR.
- Students lose sight of their own group on this page once closed; it remains visible on the Overview and Groups tab.
- The ungrouped-students button and notifications bell are not rendered while closed.

**D3. Features the mockup drops or changes. DECIDED.**
- **Promote to leader: stale.** Build no UI for it. `group_leaders#update` (`resource :leader`), `ProjectGroupPolicy#promote_leader?` and the route are marked for deletion in the backend pass (§9). Do not delete them in this pass.
- **Staff "Create group":** same button as the student's "Create group", copied with exact styling (tonal button, same toolbar position and classes). `ProjectGroupPolicy#create?` is now `staff? || student?` and `groups#create` does `@course.students.find(params.expect(:user_id))` for staff (a student's `user_id` is ignored), so a bare POST from staff is a 400. Same button, same styling; for `policy(@course).manage_groups?` (coordinator, or lecturer with the flag) it opens a page-level dialog with the student picker (verb "Create group") that submits `user_id` to `course_groups_path`. Students keep the plain `button_to`.
- **Cancel join request: no backend** (`join_requests` is `only: %i[create update]`; there is no `destroy`). Render "Request sent" (from `@my_requested_group_ids`) with **no cancel link**. Flagged for a later pass (§9).
- Lock/unlock = the "Require approval to join" switch (`locked?`), mapped 1:1.

**D4. Search/filter: htmx. DECIDED.**
The table filters server-side with htmx, following the Groups tab's structure (`hx-get` + debounce + `HX-Request` branch + re-rendered table partial + pagination threshold). The implementation is **copied and adapted into formation-specific code**, not extracted from `GroupsController`/`ParticipantBrowsing` and not shared with `courses/_groups_table`. `GroupsController#index`, `ParticipantBrowsing`, `courses/_groups_tab` and `courses/_groups_table` stay untouched. Search matches **group name and member names only** (no project title or supervisor), and the status filter is **All / Draft / Confirmed** (the group's confirmed state, not the project's status). The controller gains a small formation-only filter branch (see §4.4); `list_filter` stays only for the ungrouped dialog and pickers.

**D5. Manage dialog and student pickers. DECIDED: lazy frame on `groups#edit`.**
Each group row's action cell holds `<div data-controller="modal">` containing: a link to `edit_course_group_path(course, group)` with `data-turbo-frame="<%= dom_id(group, :manage) %>"` and `data-action="modal#open"`; a `<dialog>` (§2.2 structure); and, inside the dialog, an **empty placeholder** `turbo_frame_tag dom_id(group, :manage)` (same id as the one `groups/edit.html.erb` already renders). Clicking the link opens the dialog and fetches `groups#edit`, so the content is fresh on every open (the routes brief requires a reload on every open). The **table-row** Manage link is staff-only: rendered only when `policy(@course).manage_groups?` (coordinator, or lecturer with `lecturers_can_manage_groups`). **Leaders never see Manage on their row**; their "Manage group" button lives in the my-group card (separate partial, same lazy frame in leader mode, rendered only when `policy(group).edit?` is true for them, i.e. draft group inside the window). Never render the link when `edit?` is false: Pundit would redirect the frame request to the dashboard and the frame would show "Content missing".

Frame requirements:
1. `groups/edit.html.erb` must declare `turbo_frame_tag dom_id(@group, :manage), target: "_top"`. Every form inside it (approval switch, Remove, Delete, Invite, Add, Confirm for leader, Generate link) then performs a **full-page Turbo visit**. Without `_top`, the controllers' `redirect_to course_group_formation_path` would load the formation page into the frame, which contains the *empty* placeholder frame with the same id, so the dialog would blank out and the flash would never show.
2. Stale content on reopen: additive `modal#reset` (called via `close->modal#reset` on the dialog) restores the frame's initial placeholder markup and removes `src` / `complete`, like `overlay_controller#returnToList` does for the topic copy dialog.
3. Show a lightweight "Loading…" placeholder (token styling) in the placeholder frame.
4. `groups#edit` must set the ivars `groups/edit.html.erb` reads (the template passes them to partials as locals). Use the **same ivar names** as `GroupFormationsController#show` so partials can be shared and §4.1 stays the only contract: `@incoming_join_requests` (pending `direct_request` for **this** group), `@my_group_invite_token` (this group's link for `current_user`, leader only), `@my_invited_student_ids`, `@ungrouped_students` (only needed when a picker renders). This duplicates the queries in `group_formations#show`; extracting a `Course` scope is a backend-pass item (§9). This is the one place in this pass where a controller action is edited.
5. Pickers live inside the frame, so the ungrouped list is rendered for **one** group at a time (the N-groups × all-students DOM problem from the earlier plan is gone). They filter client-side with `list_filter` (`limit: 6`).
6. The page-level `<dialog>`s (ungrouped students, staff Create group picker, shared confirm dialog) are unchanged: their data is already on the page.
7. Stacking: the dissolve warning (server `turbo_stream.append('modals', …)`) currently renders a `div`, which would sit **behind** an open Manage `<dialog>` (top layer). Convert `group_members/_dissolve_warning_modal` to a `<dialog>` opened with `showModal()` on connect (later top-layer entries stack above earlier ones). The shared confirm dialog has the same property and is fine as long as it is opened after Manage.
8. Redirect-after-action is accepted for this pass: after any action the dialog closes with the page reload and a flash.

Decided by the owner:
- **Who can open Manage (Q1). DECIDED.** Staff only on the table: coordinator **and** lecturers who can manage groups. Because `update?` is coordinator-or-draft-leader (lecturers are denied), this needs a small policy edit in this pass: add an explicit `ProjectGroupPolicy#edit?` = `manage_groups_policy.manage_groups? || update?` and change `groups#edit` to `authorize @group, :edit?`. `update?` (the approval PATCH) is left unchanged, so lecturers still cannot lock/unlock. In staff mode the dialog shows Members + Remove, Add student, Delete group (only if `destroy?`), Confirm for leader (only if `confirm?` and draft); **no** approval switch, invite link, join requests or invite picker (those are leader mode, mockup parity). The leader of a **confirmed** group has no Manage button in the card (Reopen is there instead). The leader's "Manage group" in the card opens the **same** `groups#edit` frame in leader mode. The table-row Manage link (staff) and the card Manage button (leader) are mutually exclusive by role, so `dom_id(group, :manage)` is never rendered twice on one page.
- **After an action in Manage (Q2). DECIDED: hard redirect.** Every form inside the frame submits with `_top`, the controller redirects to `course_group_formation_path`, the dialog is gone and the flash shows. This is a Turbo Drive visit (body replace, scroll back to top), not a literal browser reload.
- **`lecturers_can_manage_groups` flag.** The owner is fine removing it. It has no settings UI (column default `true`), so today every lecturer can manage. The frontend only calls `policy(@course).manage_groups?`, so nothing here changes when the flag is dropped (backend pass, §9: `manage_groups?` becomes `coordinator || lecturer`).

**D6. Confirm button. DECIDED.**
Always-enabled `button_to confirm`; after the click the reason is shown by the existing flash from `GroupConfirmer#message`. `@my_group_can_confirm` becomes unused (keep it set; remove in the backend pass). Mockup copy such as "Needs 1 more member" / "would leave 1 student without a group" is not produced by the services (§4.3 R6). In default mode (`student_list_finalised? == false`) "Needs N more" / "Over the maximum" may be shown from counts and `course.group_min/max` via a helper; in Auto-Confirmability mode show only the service message.

**D7. Row expand behaviour. DECIDED.**
The entire row is clickable (except `[data-expandable-ignore]` cells, i.e. the action cell), with a real `<button aria-expanded>` in the members cell for keyboard/AT. Rows are **collapsed by default** and **auto-expand only while a search or filter is active**. Because the table is re-rendered by htmx, expand state is not client-side at all: the controller passes `@filters_active` and the table partial renders each row with `expanded: @filters_active`. No `setAll` method is added and no `list-filter:change` listener drives expansion. "Expand all" stays a client-side `expandable_rows` toggle in the Members `<th>` (desktop only). The shared `expandable_rows` controller only gains `[data-expandable-ignore]` handling and `aria-expanded`.

**D8. Member detail layout.** ✱ Use the mockup's 2-column grid in the formation table. Leave the Groups tab (`courses/_group_row`, single column, truncated names) alone this pass; the two will visibly differ. Align the Groups tab in a later pass. Collapsed summary: cap the avatar stack at 3 + "+n" (matches the Groups tab) instead of the mockup's all-members stack. Drop the "Pending / Resend invite" badge in the formation table (not a user-management surface).

**D9. Staff actions follow policy, not the mockup.**
The mockup shows "Delete group" to every coordinator and lecturer and "Confirm for leader…" to coordinators only. Policies (kept as is by the routes brief, D5/D7) say: `destroy?` lets a coordinator destroy only **confirmed** groups, a leader destroy a draft inside the window, and never a lecturer; `confirm?` is `manage_groups?` or the leader; `update?` (approval switch) is coordinator or draft-leader-in-window; `edit?` (Manage dialog, new) also allows `manage_groups?` (Q1).
✱ Gate every button with `policy(group).<action>?` (`update?`, `destroy?`, `confirm?`, `revert?`, `generate_invite_link?`, `direct_invite?`) and `policy(@course).manage_groups?` for staff Add student. In practice a coordinator sees Delete only on confirmed groups. If the owner wants coordinators to delete drafts, that is a policy change for the backend pass.

**D10. Message styling.** ✱ Reuse `courses/_flash` unchanged (alert/notice only). The mockup's `warn` and `info` variants have no Rails flash key behind them; adding `flash[:warning]` is a controller change (backend pass). Known visual difference: the shared flash still uses raw red/green classes.

**D11. Student IDs in pickers.** Old coordinator pickers showed `name (instid)`; the mockup shows names only. ✱ Names only for everyone in the lists; show `instid` (mono, muted) only inside pickers when `policy(@course).manage_groups?`, to disambiguate duplicate names. Never show `instid` to students.

**D12. "No size limit" mockup variant.** ✱ Do not build. `Course` validates `group_min` and `group_max` as required whenever grouping is enabled, so unlimited does not exist. Drop the `nolimit` branches ("n members" text, "No size limit", skipping size validation). The "Min/max, no end date" variant **is** real (`grouping_closes_at` is nullable; `grouping_window_open?` handles nil): render "Closes …" only when `grouping_closes_at` is present.

---

## 4. Rails contract to preserve

### 4.1 Instance variables (set by `GroupFormationsController#show`; the four marked † are also set by `GroupsController#edit`, §3 D5; the htmx rows are formation-only)

| Ivar | Old use | New use in mockup |
|---|---|---|
| `@course` | everywhere | rules line (`group_min`, `group_max`, `grouping_closes_at`), `grouping_window_open?` |
| `@current_user_enrolment` | hides my-group panel for coordinator/lecturer | `@current_user_enrolment&.student?` decides student vs staff surfaces, bell visibility |
| `@my_group` | panel, card (hide join when present) | my-group card; "Your group" tag; hide Join/Request in all rows |
| `@my_group_can_confirm` | disabled state of Confirm | unused after D6a (keep set) |
| `@my_group_invite_token` † | invite link field | Manage → Invite link |
| `@incoming_join_requests` † | leader column | bell (leader, from `show`) **and** Manage → Join requests (from `edit`, scoped to the edited group) |
| `@incoming_direct_invites` | amber banners | bell (student with no group) |
| `@my_requested_group_ids` | **unused** | "Request sent" in the action cell |
| `@my_invited_student_ids` † | "Invite sent" badge in `_ungrouped_student` | disable/label "Invite" in the picker rows and the ungrouped list |
| `@groups` | cards | table rows (order `created_at` already applied) |
| `@ungrouped_students` † | sidebar + comboboxes | "N students without a group" button, ungrouped dialog, staff Create group picker; Manage pickers (from `edit`) |
| `@filtered_groups` | — | htmx/initial table rows (filtered copy of `@groups`; §4.4) |
| `@filters_active` | — | server-rendered row expansion + no-matches state (§4.4) |
| `@group_list_state` | — | search/status values + "Showing X of Y" (§4.4) |
| `@total_group_count` | — | total before truncation, for the footer (§4.4) |
| `@show_all` | — | render every filtered row vs the pagination threshold (§4.4) |

These htmx ivars are the only additions to the contract. Everything else in the mockup is derivable:
- counts: `@groups.size`, `@groups.count(&:confirmed?)`, `@ungrouped_students.size`.
- size state and invalid flag: helper `group_size_state(group, course)` → `:ok | :under | :over` from `members.size` vs `course.group_min/max` (display only; amber row + warning icon).
- "your group": `group.id == @my_group&.id`.
- role predicates: see §8.
- approval switch: `group.locked?`.
- leader tag: **`group.leader_id`**, not "first member". The mockup tags `members[0]` as leader; in the app the leader is `leader_id` (it can differ from the oldest member after `promote_leader`). List the leader first in member lists via the helper, but tag by `leader_id`.

### 4.2 Routes and policies (post routes-refactor; UI gates must call these)

`c` = course, `g` = group. All writes redirect to `course_group_formation_path(c)` unless noted.

| Surface | Route | Gate |
|---|---|---|
| Open page | GET `course_group_formation_path(c)` | `authorize @course, :grouping?` |
| Create group (student) | POST `course_groups_path(c)` | `create?` = `staff? \|\| student?`; student's `user_id` ignored. Old display rule: only when `@my_group.nil?` and window open |
| Create group for a student (staff) | POST `course_groups_path(c)` + `user_id` | `policy(@course).manage_groups?`; missing `user_id` = 400 (D3) |
| Join | POST `course_group_members_path(c, g)` (no `user_id`) | `join?` (student enrolment). Display rule kept: nothing when `@my_group.present?`; `locked?` → Request, else Join; greyed out when `confirmed?` (services block `group_confirmed`) |
| Request to join | POST `course_group_join_requests_path(c, g)` | `request_to_join?` |
| Accept / decline request (leader) | PATCH `course_group_join_request_path(c, g, r)` + `status=accepted\|declined` | `ProjectGroupInvitePolicy#accept?/decline?` |
| Invite student | POST `course_group_invitations_path(c, g)` + `user_id` | `direct_invite?` (leader) |
| Accept / decline invite (recipient) | PATCH `course_group_invitation_path(c, g, i)` + `status` | `accept?/decline?` |
| Confirm / Reopen | POST / DELETE `course_group_confirmation_path(c, g)` | `confirm?` / `revert?` (leader or `manage_groups?`) |
| Approval switch | PATCH `course_group_path(c, g)` + `project_group[locked]=true\|false` | `update?`; lock is refused when `leader_id` is blank |
| Manage dialog | GET `edit_course_group_path(c, g)` (frame) | `edit?` (new: `manage_groups? \|\| update?`). Table link: `manage_groups?` only. Leader card button: `edit?` for the leader |
| Delete / dissolve | DELETE `course_group_path(c, g)` | `destroy?` |
| Make leader | PATCH `course_group_leader_path(c, g)` + `user_id` | `promote_leader?`: **stale, no UI** |
| Generate invite link | POST `course_group_invite_link_path(c, g)` | `generate_invite_link?` (leader) |
| Invite link URL to copy | `join_url(token)` | n/a |
| Add student (staff) | POST `course_group_members_path(c, g)` + `user_id` | `policy(@course).manage_groups?` (a student sending `user_id` is denied) |
| Remove / Kick / Leave | DELETE `course_group_member_path(c, g, m)` | `ProjectGroupMemberPolicy#destroy?` (self, leader, `manage_groups?`); services block a leader kick on a confirmed group and removals outside the window. Only grouping action with a Turbo Stream branch |
| Public invite page / redeem | GET `invite_link_path(token)` / POST `invite_link_redemption_path(token)` | `redeem?` |
| Staff Manage entry | n/a | `policy(@course).manage_groups?` (coordinator, lecturers who can manage) |

### 4.3 Rules the mockup implies that do not exist (do not implement; log in §9)

- R1. Cancel request (`join_requests` has no `destroy`; no policy/service).
- R2. Coordinators/lecturers deleting draft groups (D9).
- R3. Unlimited group size (D12).
- R4. Invite without page reload / in-place "Invite sent" (needs a turbo_stream response; Q2).
- R5. Server-side picker search with `limit 6` (replaced in this pass by a per-open lazy frame + client-side filter).
- R6. Specific confirm-failure messages ("Needs 1 more member", "would leave 1 student without a group"). `GroupConfirmer` only returns `window_closed`, `already_confirmed`, `size_illegal` messages.
- R7. Succession copy "`{members[1]}` becomes the leader". Succession picks the oldest remaining membership (`order(:created_at, :id).first`), which is not necessarily the second name on screen. Use generic copy: **"Another member becomes the leader."** Do not recompute the rule in the view.
- R8. Mockup remove-dialog text "becomes Not confirmed because it falls below the minimum". The service reverts a confirmed group when the member **self-leaves** (any size) or when `!confirmable?` (quota-aware in Auto-Confirmability mode). Copy must say "may become Not confirmed" for kicks, and "will become Not confirmed" for a member leaving a confirmed group. The mockup's member Leave dialog omits this entirely; add it.
- R9. "Accepting clears your other invites and requests" **is real** (`GroupInviteResponder#clear_conflicting_invites!`), so that copy stays.

### 4.4 Allowed controller edits

0. Policy: `ProjectGroupPolicy#edit?` explicit (`manage_groups_policy.manage_groups? || update?`); `GroupsController#edit` authorizes `:edit?` instead of `:update?`. `update?` unchanged.
1. `GroupsController#edit`: set `@incoming_join_requests`, `@my_group_invite_token`, `@my_invited_student_ids`, `@ungrouped_students` (same names and semantics as in `GroupFormationsController#show`; D5).
2. `GroupFormationsController#show`: add the formation-only htmx filter branch. Compute `@filtered_groups` from `@groups` by group-name/member-name search and the `All / Draft / Confirmed` status filter, plus `@filters_active`, `@group_list_state`, `@total_group_count` and `@show_all` (all listed in §4.1). On `HX-Request`, render only `group_formations/_groups_table`. Copy/adapt the logic from `ParticipantBrowsing`/`courses/_groups_table`; do not include or modify the shared code.
3. Eager loading (optional): `GroupFormationsController#show` `@groups` `.includes(:project)` and the two invite/request includes; keep the formation relation's `created_at` order.
4. `groups/edit.html.erb`: add `target: "_top"` to the frame (D5).
No other controller, service, model or policy edits (the routes brief's D5/D7 policy names stay). `GroupsController#index`, `ParticipantBrowsing`, `courses/_groups_tab` and `courses/_groups_table` are not touched.

### 4.5 DOM contracts with controllers (do not rename or drop)

- `<div id="modals"></div>` on the page: `GroupMembersController#destroy` appends `group_members/_dissolve_warning_modal` into it.
- `#ungrouped-students-list` and the partial `group_formations/_ungrouped_student` (root `id="<%= dom_id(student, :ungrouped) %>"`): the same action `turbo_stream.append`s into it (explicit partial path `'group_formations/ungrouped_student'`). The ungrouped dialog's list must keep this id and render rows with this partial.
- `id="<%= dom_id(group) %>"` on the group's `<tbody>` and `id="<%= dom_id(membership) %>"` on each member entry in the **table detail row**: `group_members#destroy` `turbo_stream.remove`s them.
  - Manage entries use `dom_id(membership, :manage)` (no duplicate ids). Manage forms do **not** send `data-turbo-stream` (they redirect via `_top`), except the last-member-with-project case below.
- `<div id="flash">` wrapper with `render "courses/flash"` at the top of the page.
- Keep the old `if will_dissolve_with_data` rule exactly: removing the **last member of a group that has a project** must skip the client confirm dialog and submit with `data-turbo-stream` so the server's `needs_confirmation` modal is appended (`member_count == 1 && group.project.present?`).
- The frame id `dom_id(group, :manage)` (placeholder on the page = frame in `groups/edit.html.erb`).
- `content_for :no_footer`, `breadcrumb :group_formation, @course` stay.

## 5. New version: gap analysis against the current setup

### 5.1 Instance variables

`@my_requested_group_ids` (previously unused) is now used; `@my_group_can_confirm` becomes unused (D6). `GroupsController#edit` sets four existing ivar names (D5, §4.4). `GroupFormationsController#show` adds the five htmx ivars in §4.1; no other new ivars. Optional eager-load tweaks (§4.4).

### 5.2 JS controllers

**Add**

1. `list_filter_controller.js` (replaces `group_browse_filter`, and the mockup's `filterRows`, `filterList`, `pickerRows`).
   - Targets: `input`, `select` (optional), `item`, `shown`, `total` (optional), `noMatch`, `empty` (optional), `container` (optional; hidden when nothing matches).
   - Values: `limit` (Number, optional; "show first N matches").
   - Items carry `data-list-filter-text` (lowercased haystack) and optional `data-list-filter-tags` (space-separated, e.g. `not_confirmed invalid`). Select value `all` matches everything, any other value must be present in `tags`.
   - Toggles the `hidden` class (not inline `style`). Runs once on connect. Dispatches `list-filter:change` `{ active, visible, total }`.
   - Two uses only: the ungrouped-students dialog (search only, no limit) and the pickers (`limit: 6`, "Showing n of m"). The groups table is server-filtered by htmx, so it does not use this controller.
2. `confirm_dialog_controller.js` (replaces the dead `data-confirm` strings and the mockup's `dialog(title, body, okLabel, danger, onOk)`).
   - Put on a `<form>` (a `button_to`): `data-controller="confirm-dialog" data-action="submit->confirm-dialog#ask"`, values `title`, `okLabel`, `danger` (Boolean), and a `<template data-confirm-dialog-target="body">` holding the rich body (member list, "proposal will be lost", etc.) rendered server-side. `ask` prevents the submit, fills one shared `<dialog id="confirm-dialog">` (partial `shared/_confirm_dialog`, rendered once on the page, same token styling as the mockup's `#dlg`), and on OK calls `form.requestSubmit()` with the listener bypassed.
   - Used for: Delete/dissolve, Reopen, Leave, Remove/Kick (except last-member-with-project, §4.5), Confirm for leader. (No Make leader: stale.) It works inside the `_top` Manage frame because `requestSubmit()` on a form in a `target="_top"` frame does a full visit.

**Change (additive)**: `expandable_rows` (§2.1; `ignore` + `aria-expanded` only, no `setAll`), `invite_link` (§2.3), `modal` (`reset`, §2.2), bell wrapper gets Esc via `data-action` on `dropdown` (§2.4).

**Reuse as is**: `modal`, `dropdown`, `search_shortcut`, `sidebar`, `flash`, `auto_submit` (approval switch inside the Manage frame: `form_with url: course_group_path(course, group), method: :patch, scope: :project_group, data: { controller: "auto-submit" }` with `f.check_box :locked, data: { action: "change->auto-submit#submit" }`; `groups#update` takes `params.expect(project_group: [:locked])`).

**Delete**: `group_browse_filter_controller.js`, `combobox_modal_controller.js`.

### 5.3 Partials: reusable components, plus modals (revised)

An earlier draft of this plan split the page into ~20 partials, most with a single caller. That is decomposition for readability, not reuse, so it is dropped. Rule: a partial needs two or more call sites, or a server entry point that renders it on its own (`turbo_stream` append, frame response), and takes strict locals. **Exception (owner decision): modals/dialogs may be partials even with one caller**, because they are self-contained blocks (dialog chrome + header/body/footer) that otherwise bury the page template. Strict locals still apply.

The old views were moved by the routes PR to `app/views/group_formations/` (`show.html.erb`, `_group_card`, `_my_group_panel`, `_ungrouped_student`), `group_members/_dissolve_warning_modal`, `invite_links/show`. Rewrite as follows.

**Templates (long, ivars allowed, sections marked with ERB comment banners):**
- `group_formations/show.html.erb`: shell, flash, page header + rules line, closed state (D2), bell, my-group card, toolbar, the `render "groups_table"` call, `#modals`, and the `render` calls for the dialog partials below.
- `group_formations/_groups_table.html.erb`: the htmx re-render target (`id="formation-groups"`), desktop table + mobile cards, one `<tbody>` per filtered group (row, member grid, action cell), empty/no-match states, and the "Showing X of Y"/Show all footer. Strict locals: `groups:`, `filters_active:`, `list_state:`, `total_count:`, `show_all:`.
- `groups/edit.html.erb`: the Manage frame content (`target: "_top"`) with leader-mode and staff-mode sections inline (join requests, members + Remove, invite link, approval switch, picker). This is frame content, not a modal shell, so it stays a template.

**Dialog partials (exception, strict locals):**

| Partial | Callers | Locals |
|---|---|---|
| `shared/_confirm_dialog` | formation page once (generic by design; title/body supplied by `confirm_dialog_controller`; kept in `shared/` so other destructive actions can adopt it) | none |
| `group_formations/_manage_dialog` | once per group row (collection loop) | `group:`; renders the `modal` wrapper, trigger link (`data-turbo-frame`), `<dialog>` and the empty placeholder frame (D5). Row Manage link: `policy(@course).manage_groups?`; the leader's card button reuses the same partial with `leader: true` and the policy gate `edit?` |
| `group_formations/_ungrouped_dialog` | formation page | `students:`, `invited_ids:`, `manage: false` |
| `group_formations/_create_group_dialog` | formation page, staff only | `students:`, `url:` |
| `group_members/_dissolve_warning_modal` (existing) | `group_members#destroy` `turbo_stream.append` | `member:`, `result:` |

**Reusable component partials:**

| Partial | Call sites | Locals |
|---|---|---|
| `shared/_person` (avatar initial + name, optional tag such as "Leader") | member grid, Manage members, join requests, notifications, picker rows, ungrouped rows, confirm dialog lists | `name:`, `tag: nil` |
| `group_formations/_status_pill` | table rows, my-group card, Manage header (staff) | `confirmed:` |
| `group_formations/_student_picker` | Manage Invite (leader), Manage Add (staff), staff Create group dialog | `students:`, `verb:`, `url:`, `disabled_ids: []`, `limit: 6`, `show_instid: false` |
| `group_formations/_notification` | invites and join requests in the bell (two kinds, one component) | `avatar_name:`, `text:`, `subtitle: nil`, `accept_url:`, `decline_url:` |
| `group_formations/_ungrouped_student` (existing) | ungrouped dialog and `group_members#destroy` `turbo_stream.append` | `student:` (+ `invited:`) |
| `courses/_tab_strip` (existing) | all course tabs + formation | add optional `tabs:` (D1) |
| `courses/_tab_shell` (existing) | all course tabs + formation | add optional `tabs:` and `breadcrumb:` (D1) |

`shared/_empty_state` (existing) is reused for the closed state (D2) and for "No groups yet" / "No groups match" (styleguide §8).

Helpers: `app/helpers/group_formations_helper.rb` holds logic only (`group_size_state`, `leader_first(members, group)`) plus the button class strings (constants, no markup; see §6.3). No helper builds HTML.

Strict locals note: dialog and component partials must not read `@ungrouped_students` / `@incoming_*`; the template passes them in.

### 5.4 Mockup-only code that must not ship

`tailwind.config` block; entire `<style>` block (translated in §6.2); "Mockup controls"; `render()`, `renderRows()`, `renderSlot()`, `renderHead()` and every other `render*`; `role()`, `mineId()`, `isLeader()` and the role/rules/table selects; `notifs`, `requested`, `expanded`, `groups`, `ungrouped`; `showMsg`, `dialog`, `openModal`, `openManage`, `openUngrouped`; the stub actions (`createGroup`, `tryConfirm`, `joinFail`, `reqJoin`, `cancelReq`, `acceptNotif`, …); the mockup's custom sidebar/header markup (use `shared/_sidebar` and `shared/_header`, and `courses/_tab_shell` per D1); the `ESC` and `/` keyboard handlers.

---

## 6. Tailwind tokens

Use `/styleguide` (dev only, `app/views/styleguide/show.html.erb`) as the reference. Note: the mockup's inline `tailwind.config` reuses the real token **names** (`primary-strong`, `surface-tint`, `on-surface`, …) with different hex values. The real values come from `@theme`; expect small colour shifts. Do not carry the config over.

### 6.1 Class mapping

| Mockup | App token class |
|---|---|
| `text-gray-900` | `text-on-surface-strong` |
| `text-gray-700` | `text-on-surface` |
| `text-gray-600`, `text-gray-500` (secondary) | `text-on-surface-variant` |
| `text-gray-500` (counts, timestamps), `text-gray-400` (icons) | `text-on-surface-muted` |
| disabled text (`text-gray-400` on disabled buttons) | `text-on-surface-disabled` |
| `bg-gray-50` (inputs) | `bg-surface-tint` (focus `focus:bg-surface focus:ring-2 focus:ring-primary`) |
| `bg-gray-100` neutral pill / disabled button | `bg-surface-variant` |
| `bg-gray-200` avatar | `bg-surface-variant-deep text-on-surface` |
| `hover:bg-gray-50` rows | `hover:bg-surface-hover` |
| `border-gray-200` dividers, cards | `border-outline-variant` |
| `border-gray-300` form controls, outlined buttons | `border-outline` |
| `bg-blue-100 text-blue-900` tonal button | `bg-primary-container-alt text-primary-strong hover:bg-primary-container-ring` (no tonal button in the styleguide yet: add one to §5 of `/styleguide`) |
| `bg-primary-strong hover:bg-primary-hover text-white` filled | same (matches styleguide §5) |
| `text-primary-strong hover:bg-primary-container` text button | same |
| `text-green-700`, `bg-success-container` | `text-success`, `bg-success-container` |
| `text-red-600/700`, `bg-red-50` | `text-error`, `bg-error-container` |
| `bg-red-600 hover:bg-red-700` danger | `bg-error hover:bg-error-hover` |
| `hover:bg-error-container` danger text button | same |
| `bg-amber-50 text-amber-700 border-amber-200` warn | `bg-warning-container-alt text-warning-on-container border-warning-border` |
| `text-amber-600` (warning icon) | `text-warning` |
| `bg-primary-container/40 border-outline-variant` card | same (opacity modifier OK) |
| `rounded-[8px]` card | `rounded-card` |
| `rounded-tl-panel` | same (token exists) |
| `.dm` DM Sans class | do not copy; use `font-['DM_Sans']` like `groups/show` (optional follow-up: add `--font-display` to `@theme`) |
| 11px eyebrow `text-[11px] uppercase tracking-wider` | `text-xs font-medium uppercase tracking-wider text-on-surface-variant` (styleguide eyebrow) |
| status pills | styleguide §4: `px-2.5 py-0.5 rounded text-[12px] font-medium tracking-wide` + Confirmed `bg-success-container text-success`, Not confirmed `bg-surface-variant text-on-surface-variant` |
| inline SVG icons | Material Symbols (`material-symbols-outlined`), as the rest of the app |

### 6.2 `<style>` block → utilities

| Mockup CSS | Utilities |
|---|---|
| `.pane` height | already in `courses/_tab_shell` (`h-[calc(100vh-var(--spacing-header))]`). The mockup's `dvh` fix is not applied there; changing it affects every tab, so leave it and note it |
| `.modal-card` | `max-sm:h-dvh sm:h-auto` (see §2.2) |
| `#bellPop` | `fixed inset-x-2 top-[calc(var(--spacing-header)+4px)] max-h-[70vh] overflow-y-auto sm:absolute sm:inset-x-auto sm:right-0 sm:top-12 sm:w-[340px] sm:max-h-[80vh]` |
| `tbody.grp tr.main td` border / hover | `border-t border-outline-variant` on cells; `hover:bg-surface-hover` on `tr.main`; detail `bg-surface-hover/50 border-t border-surface-variant` |
| invalid group bg `#fffbeb` / border `#fde68a` | `bg-warning-container-alt`, `border-warning-border` |
| `input,select{font-size:16px!important}` (iOS zoom) | `max-sm:text-base` |
| `min-height:44px` taps | `max-sm:min-h-11` |
| `#modalFoot` safe-area padding | `pb-[max(0.75rem,env(safe-area-inset-bottom))]` |
| mobile card layout (below 640px) | see below |

Mobile card layout without a stylesheet (use `max-sm:` variants; no `<style>`):
- `<table>`: `max-sm:block`; `<thead>`: `max-sm:hidden`.
- Each `<tbody class="grp">`: `max-sm:grid max-sm:grid-cols-[minmax(0,1fr)_auto] max-sm:gap-x-3 max-sm:gap-y-2 max-sm:items-center max-sm:p-4 max-sm:mb-3 max-sm:rounded-card max-sm:border max-sm:border-outline-variant max-sm:bg-surface`.
- `tr.main`: `max-sm:contents`. Cells become grid items: group `max-sm:order-1`, status `max-sm:order-2 max-sm:justify-self-end`, members `max-sm:order-3 max-sm:col-span-full`, action `max-sm:order-5 max-sm:col-span-full`, empty action cell `max-sm:hidden`.
- Detail `tr`: `max-sm:order-4 max-sm:col-span-full max-sm:border-t border-outline-variant max-sm:pt-3`. **Do not add `max-sm:block` or any `display` utility to it**: grid items are blockified automatically, and a display utility would override the `hidden` class that `expandable_rows` toggles (the mockup needed a special CSS rule for exactly this).
- Action buttons: `max-sm:w-full max-sm:min-h-11`.
- Desktop keeps the real table (`table-fixed`, column widths from the mockup `w-[14%] w-[34%] w-[24%] w-[28%]`).

### 6.3 Buttons

The mockup's JS constants map to inline class strings in this repo's style; they repeat 20+ times, so put them in `ProjectGroupsHelper` as frozen string constants (Tailwind scans `app/helpers`). Variants needed: filled, outlined, tonal, row-tonal (small), row-disabled, text, small-outlined, danger-text. Add tonal / text / danger-text to the styleguide in the same PR so the next page can reuse them.

---

## 7. Implementation order and verification

Routes are already done, so nothing waits on them. Suggested order (each step is independently shippable):

1. Helpers + `shared/_confirm_dialog` + `_status_pill`; styleguide additions (tonal/text/danger buttons).
2. `list_filter_controller`, `confirm_dialog_controller`; additive edits to `expandable_rows` (`ignore`, `aria-expanded` only), `invite_link` (copied state), `modal` (`reset`).
3. Page shell in `show.html.erb` (D1): header + rules line, closed state (D2), flash wrapper, `<div id="modals">`.
4. htmx filter branch in `GroupFormationsController#show` + `_groups_table.html.erb` (toolbar, one `<tbody>` per group, member grid, action cell; `_manage_dialog` added in step 5), `shared/_person`, `_status_pill`; mobile card utilities.
5. Manage: `GroupsController#edit` ivars and `edit?` (§4.4), `groups/edit.html.erb` (`target: "_top"`, sections inline), `_student_picker`; `_manage_dialog` (link, dialog, placeholder frame) rendered per row; `_ungrouped_dialog` and `_create_group_dialog`; restyled `_ungrouped_student`; dissolve modal as `<dialog>`.
6. My-group card and notifications bell (inline in `show.html.erb`; `_notification` partial for the bell items).
7. Delete the old `_my_group_panel`, `_group_card`, `show.html.erb` contents, `group_browse_filter_controller.js`, `combobox_modal_controller.js`; run the greps and tests below.

Verification (all must return nothing):

```
grep -rn "combobox-modal\|group-browse-filter\|data-confirm\|confirm: " app/views/group_formations app/views/group_members app/views/groups/edit.html.erb
grep -rnE "\b(bg|text|border)-(gray|zinc|blue|amber|red|green)-[0-9]" app/views/group_formations app/views/group_members app/views/shared/_confirm_dialog.html.erb app/views/group_formations/_student_picker.html.erb
grep -rn "<style\|onclick=\|oninput=" app/views/group_formations app/views/groups/edit.html.erb
git grep -nE "project_group_(invite_link|invite|member)s?_(path|url)|course_project_group|project_groups_path|redeem_project" -- . ':!docs' ':!test/routing'
```

Check every ivar used in the formation and Manage views is in §4.1:
```
grep -rhoE "@[a-z_]+" app/views/group_formations app/views/group_members app/views/groups/edit.html.erb app/views/group_formations/_student_picker.html.erb | sort -u
```

Regression: Topics directory (expand/collapse, "Collapse all"), Groups tab (row click, toggle-all, search `/`, htmx filter), course settings Grouping card, `invite_links#show`, the topic copy overlay (shares the dialog + frame pattern), `test/routing/group_routes_test.rb`, `test/integration/group_write_routes_test.rb`, service/model tests, `grouping_settings_surface_test.rb`. There are no system tests for the formation page today; the list to add is §11 (kept deliberately small).

---

## 8. Role/state matrix (mockup "View as" → real predicate and fixture)

| Mockup option | Predicate in the view | Make it real |
|---|---|---|
| Student, no group | `@current_user_enrolment.student? && @my_group.nil?` | student enrolment, no `ProjectGroupMember` |
| Student, leader, not confirmed | `@my_group&.leader?(current_user) && !@my_group.confirmed?` | `GroupCreator` self-create |
| Student, leader, group over maximum | same, `members.size > course.group_max` | lower `group_max` after members joined, or coordinator adds via `GroupMemberAdder` |
| Student, member, not confirmed | `@my_group.present? && !leader && !confirmed` | `GroupJoiner` |
| Student, leader, confirmed | leader + `confirmed?` | `GroupConfirmer` |
| Student, member, confirmed | member + `confirmed?` | |
| Coordinator | `@current_user_enrolment.coordinator?` (`grouping_coordinator?` was deleted by the routes PR) | coordinator enrolment |
| Lecturer (can manage) | `policy(@course).manage_groups? && !@current_user_enrolment.coordinator?`. Gets staff Create group and the table Manage link (`manage_groups?`); dialog is staff mode | lecturer + `lecturers_can_manage_groups: true` (schema default) |
| Lecturer (read-only) | lecturer enrolment `&& !manage_groups?` | `lecturers_can_manage_groups: false` |
| Leader (any state) on the table | never a row Manage link; own-group card has "Manage group" only when `edit?` (draft, in window) | |
| Rules: min/max + end date | `grouping_closes_at.present?` | |
| Rules: min/max, no end date | `grouping_closes_at.nil?` | |
| Rules: no size limit | **not built (D12)** | |
| Table: empty | `@groups.empty?` | |

Also test: window closed (D2), Auto-Confirmability mode (`student_list_finalised?`), group with a project (delete / last-member flows), group at max (action cell shows "Full"), student with pending request (`@my_requested_group_ids`), student with pending invite (bell badge), leader with pending request (bell + Manage).

---

## 9. Backend pass: consolidated to-do list

Sources: [R] routes brief (`docs/Grouping/GROUPING_ROUTES_REFACTOR.md`, things it deliberately left alone), [F] this frontend plan, [C] found while reading the code.

**Delete / cleanup**
1. [x] [F] Delete stale promote-to-leader: `group_leaders#update`, `resource :leader`, `ProjectGroupPolicy#promote_leader?`, the controller and its route test rows.
2. [F] Drop `lecturers_can_manage_groups` (column default `true`, no settings UI); `CoursePolicy#manage_groups?` becomes `coordinator || lecturer`. Frontend already calls only `manage_groups?`.
3. [R] Remove the two legacy GET redirects (`/courses/:id/project_groups`, `/project_group_invite_links/:token`) after one release, with their routing tests. Keep `join/:token`.
4. [F] Remove `@my_group_can_confirm` from `GroupFormationsController#show` (unused once Confirm is always enabled).
5. [C] `dynamic_form_action_controller.js` is unused app-wide (not grouping): delete in a separate cleanup.

**Policies**
6. [R] Policies kept as is by the routes brief: `destroy?`, `update?` (was `lock?`/`unlock?`), `promote_leader?` still use `coordinator?` rather than `manage_groups?`. Decide the intended matrix (e.g. coordinators deleting **draft** groups, lecturers deleting).
7. [F] Leader of a **confirmed** group cannot open Manage (`edit?` = `manage_groups? || update?`, and `update?` needs a draft). Revisit if that read-only view is wanted.
8. [R] One `ProjectGroupInvitePolicy` serves both kinds (`direct_request`, `direct_invite`) via explicit `:accept?` / `:decline?`; consider one policy per kind.

**Missing backend for UI**
9. [F] Cancel join request: `join_requests#destroy`, a sender-only policy query, service (mockup's "Cancel request"; UI shows "Request sent" only, no link).
10. [F] `flash[:warning]` / `info` variants (mockup message styles; shared flash is alert/notice only).
11. [F] Richer `GroupConfirmer` messages ("Needs 1 more member", "would leave 1 student without a group"); today only `window_closed`, `already_confirmed`, `size_illegal`.
12. [F] Leader succession message: succession picks the oldest remaining membership; the UI uses generic copy because the rule is not exposed.
13. [F] Self-leave of a confirmed group reverts it; expose that in the Result so the Leave dialog can say so precisely (UI copy is generic: "may become Not confirmed").
14. [F] Nullable/unlimited group max (`group_min`/`group_max` are required when grouping is enabled; the mockup's "No size limit" variant is not built).
15. [F] Closed-state wording: `grouping_window_open?` is also false before the open date and when `grouping_open` is off, but the empty state says "closed by your coordinator". Optional: split copy by cause.
16. [F] `@my_group_invite_token` ignores `expires_at`: an expired token still renders as copyable (UI says "expires 24 hours after it's generated").

**Refactors (no behaviour change)**
17. [F] `GroupFormationsController#show` and `GroupsController#edit` duplicate the ungrouped-students, pending-requests, invite-token and invited-ids queries: extract `Course` / `ProjectGroup` scopes.
18. [R/C] Eight nested controllers repeat `set_course` / `set_group` and the same `if result.x? redirect notice else alert` branch (~10 actions): extract a concern / a `redirect_with_result` helper (services and Result classes were untouched by the routes PR).
19. [C] `GroupMembersController#create` merges two flows (self-join vs staff add) on `params[:user_id].blank?`; consider splitting (e.g. join as its own resource) now that policies are explicit.
20. [C] `GroupsController` serves the Groups tab (index/show, htmx) and the write resource (create/edit/update/destroy); `rescue StandardError` in `update` / `destroy` / leaders is broad: narrow it.
21. [F] N+1 in the formation page (`group.project`, invites' sender/group) if the eager-load tweaks in §4.4 are skipped.
22. [F] Server-side picker search with `limit`, only if the ungrouped list becomes too large for a lazy frame; Turbo Stream responses to keep Manage open are **not** needed (hard redirect decided).
23. [F] Live updates for join requests/invites (the bell is only fresh on page load).

**Shared UI debt noticed**
24. [F] `courses/_tab_shell` uses `vh`, not `dvh` (mobile address bar); `courses/_group_row` and `courses/_flash` still use raw gray/red/green and the old rounded-full dot pill; Groups tab member detail is a single truncated column while formation uses the 2-column grid (D8).

---

## 10. Routes: done. What it changed for the frontend

`docs/Grouping/GROUPING_ROUTES_REFACTOR.md` is implemented on the branch. Facts the frontend must respect:

- The formation page is `group_formations#show` at `course_group_formation_path(c)`; `groups` is now both the Groups tab (`index`, `show`) and the write resource (`create`, `edit`, `update`, `destroy`). Do not infer URLs from the model (`redirect_to @group`, `form_with model:` without `url:`): `ProjectGroup` would resolve to `project_group_path`, which no longer exists. Scope form params under `project_group`.
- Verb changes: join, generate invite link and redeem are POST; lock/unlock are one PATCH on `course_group_path` with `project_group[locked]`; confirm/reopen are POST/DELETE on `course_group_confirmation_path`; accept/decline are PATCH with `status=accepted|declined` (the controllers reject anything else and 404 on a wrong-kind id).
- `join_url(token)` is the canonical shareable link; old emailed `/courses/:id/project_groups` and `/project_group_invite_links/:token` URLs redirect (GET only).
- `groups#edit` exists but is a stub (frame with the group name only) and has no link anywhere yet; this plan builds it out (D5).
- `grouping_coordinator?` is gone; use `manage_groups?` for "staff" and the enrolment role for "coordinator".
- Pundit denies by redirecting to the dashboard: never render a link or button whose policy query is false, especially the Manage link (a frame request would end in "Content missing").

Route-dependent view lines in the moved views already use the new helpers (the formation views contain only `course_group_*`, `course_groups_path`, `invite_link_redemption_path` and `join_url` helpers). New partials must use the helpers in §4.2.

---

## 11. System tests

Follow `docs/testing.md` and Copeland ch. 12: tests exist to reach confidence at the lowest carrying cost; system tests only for **major user flows**; unit tests for the rest. What already covers the layers below the UI: `test/services/group_*_test.rb` (rules), `test/routing/group_routes_test.rb` and `test/integration/group_write_routes_test.rb` (routes and authorization). The gap is the UI.

Conventions for every test below:
- `ApplicationSystemTestCase` (`:rack_test`) unless the flow needs JavaScript; `BrowserSystemTestCase` (headless Chrome) only where noted.
- Locate elements by markup and content (labels, button/link text, headings). **Do not pre-add `data-testid`s.** Per the repo convention, switch an assertion to `data-testid` the first time a DOM change forces a test edit.
- Assert resulting **state** on the page (who is in which group, Confirmed vs Not confirmed, "Your group", a flash is present), not exact service message strings: those messages are on the backend list (§9) and will change.
- Arrange with FactoryBot through one helper in `test/support/` (e.g. a grouped course with grouping open, a coordinator, a lecturer, students). Do not scatter `course.update!(grouping_*, group_*)` through tests, so schema changes in the backend pass touch the factories and that helper only. Do not set `lecturers_can_manage_groups` (rely on the default; the flag is slated for removal).
- Write each test in the same step that builds its UI (§7); the test drives the markup.

**Major flows, `:rack_test` (files under `test/system/group_formations/`)**

1. Student with no group creates a group: lands on the formation page, sees their group marked as theirs, with Confirm available.
2. Student joins an open group; the Join action is unavailable on a confirmed group.
3. Student requests to join a locked group (sees "Request sent"); the leader accepts from the bell and the student appears in the group.
4. Leader invites an ungrouped student (picker in Manage); the invitee accepts from the bell and is in the group.
5. Leader confirms a legally sized group (row shows Confirmed) and reopens it; confirming an illegally sized group leaves it Not confirmed and shows an alert.
6. A member leaves a draft group; the leader removes a member.
7. Staff: coordinator and a managing lecturer see Manage on every row and can add a student and create a group for a chosen student; a leader and a plain student see no Manage link on the table.
8. Leader generates an invite link; another student opens it and joins (redeem).
9. Grouping closed: the page shows the "Grouping is closed by your coordinator" empty state and no actions.

**JavaScript flows, `BrowserSystemTestCase`**

10. Manage lazy frame: staff opens Manage (content loads), removes a member through the confirm dialog, lands on the formation page with a flash and no open dialog; reopening Manage shows fresh data (no stale content).
11. Confirm dialog: a destructive action (e.g. leader deletes a draft group, member leaves) shows the dialog; Cancel changes nothing; OK performs it. (The old `data-confirm` confirmations never worked, so this is a regression-prone area.)
12. Dissolve warning: removing the last member of a group that has a project shows the warning **above** an open Manage dialog and confirming dissolves the group.
13. Table interactions (`BrowserSystemTestCase`): rows are collapsed by default; clicking a row expands it; clicking Join/Request does not toggle it; typing in search swaps the table over htmx (URL unchanged) with matching rows expanded, and clearing collapses them again; the status filter narrows rows and "Showing X of Y" updates.
14. Mobile (`viewport_size [390, 844]`): groups render as cards, collapsed detail stays hidden (the `hidden` vs `max-sm:` pitfall in §6.2), expanding shows it, no horizontal overflow (precedent: `projects/mobile_overflow_test.rb`).

**Guard tests for the shared controller (write first, run green on current code, then change `expandable_rows`)**, in `test/system/courses/`, `BrowserSystemTestCase`:

15. Groups tab: row click expands/collapses a group row and "Expand all" toggles all.
16. Topics directory: a supervisor section header expands and collapses.

**Deliberately not tested** (cost above value, already covered, or pending the backend pass): `/` search shortcut (existing `search_shortcut_test.rb`), bell Esc, invite-link "Copied" label, picker 6-row cap, empty-table copy, flash styling, cancel request, promote leader, the full policy matrix (integration tests), service message wording, Auto-Confirmability counts (service tests).

Cost: 9 rack_test + 5 browser + 2 guard tests. If this feels heavy, drop 14 and 16 first.

---

## Appendix A. How each feature is served (current → this plan)

| Feature | Current delivery | After this plan |
|---|---|---|
| Formation page | Server-rendered ERB; Turbo Drive navigation; no JS data layer | same |
| Rules line, group/ungrouped counts | server-rendered | same |
| Search + status filter on the groups table | Stimulus `group_browse_filter` (client-side tabs + card text search) | htmx `GET` to the formation route with a formation-only filter branch; search = group + member names, status = All/Draft/Confirmed |
| Row expand/collapse | (old) native `<details>` per card | Stimulus `expandable_rows` (client-side, no request); server-rendered auto-expand while filters are active |
| Create, Join, Request to join, Confirm, Reopen, Approval lock, Generate link, Invite, Accept/Decline, Delete, Leave | Turbo Drive form (`button_to`) → controller → `redirect_to` formation page with flash (full-page visit; `members#create` uses 303) | same, new routes; Delete/Leave/Reopen/Remove behind the shared Stimulus `confirm_dialog` instead of the dead `data-confirm` |
| Remove / kick a member | `group_members#destroy`: only grouping action with a Turbo Stream branch (remove node, append to `#ungrouped-students-list`, remove dissolve modal; `needs_confirmation` appends the dissolve warning to `#modals`; HTML fallback `redirect_back`). Old Kick used `turbo: false` | unchanged contract (§4.5); dissolve warning becomes a `<dialog>` |
| Warning dialog | Stimulus `warning_modal` over a turbo_stream-appended `div` | same controller contract, `<dialog>` |
| Student pickers (invite / add / create) | Stimulus `combobox_modal` over pre-rendered rows per card | `list_filter` (`limit: 6`); Manage pickers rendered inside the lazy frame; ungrouped dialog also `list_filter` |
| Manage dialog | did not exist (`groups#edit` was added as a stub) | native `<dialog>` + Stimulus `modal`; content from **Turbo Frame** GET `groups#edit` on every open; writes escape the frame (`_top`) and redirect |
| Notifications (invites/requests) | server-rendered banners in the panel | server-rendered partial + Stimulus `dropdown`; Accept/Decline = PATCH forms → redirect |
| Approval switch | PATCH `lock`/`unlock` buttons | Stimulus `auto_submit` on a PATCH form |
| Invite link copy | Stimulus `invite_link` (clipboard, client-side) | same + "Copied" state |
| Public invite page | `invite_links#show` server-rendered; redeem = POST form → redirect | same |
| Flash | Turbo Drive + Stimulus `flash` auto-dismiss | same |
| Mobile table → cards | n/a | CSS only (`max-sm:` utilities) |
| Groups tab (not this page) | htmx GET partial swap (`hx-get`, 300 ms debounce, `HX-Request` branch in `GroupsController#index`) + Stimulus `expandable_rows` | unchanged |
| Course settings grouping preview | htmx GET `grouping_preview` + Stimulus `grouping_settings` | unchanged |