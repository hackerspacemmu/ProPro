# `refactor/design` — QA Sanity Check List

For manual pass, not a replacement for the automated suite (list of what's already automated is at the bottom — don't duplicate effort there, go deeper where automation can't see: layout, responsiveness, visual state). Built from the actual `main`...`refactor/design` diff, so this should cover everything touched, not just the pages that look different.

---

## 0. Read this before starting — merge-base gap

`refactor/design` branched off a commit that's now **16 commits behind `main`**. That's not just churn — three of those commits are full features `main` has that this branch doesn't:

| On `main`, not in `refactor/design` | What it means for testing |
|---|---|
| **Email domain restriction** (course settings) — full feature: migration, controller action, form partial | `refactor/design`'s rewritten `courses/settings.html.erb` has **no email-restriction UI at all** — the column doesn't even exist in this branch's schema. Testing settings on this branch today can't catch this; it'll surface as a missing feature the moment this merges into `main` unless someone re-adds the form to the new design first. |
| **OTP removed** from sign-in | This branch's `db/schema.rb` still has the `otps` table and `User has_one :otp`. Sign-in itself looks fine here (no OTP field in the form either way), but this is a live merge-conflict risk in the auth flow — worth a full sign-in retest right after merge, not just now. |
| **Self-service sign-up + `is_staff` removed** | This branch still has `is_staff` in 7 files (`courses_controller`, `user_controller`, mailers, `course_policy`, schema). `user/new_staff.html.erb` / `user/new_student.html.erb` on this branch reflect the *old* registration model. |

**Recommendation: don't treat a pass on `refactor/design` today as a pass on what actually ships.** Either get `main` merged/rebased into this branch before the full QA pass, or plan on a second, shorter pass focused specifically on settings/sign-in/sign-up right after that merge lands.

---

## 1. High-priority — specific regressions to verify, not just "does it look right"

These aren't visual — they're the diff calling out actual behavior changes. Test these deliberately, they won't show up from casually clicking around.

1. **Enrolment removal — authorization fix.** `EnrolmentsController#destroy` used to trust a client-submitted `coordinator_id` param to decide who's allowed to remove someone from a course; it now checks the actual logged-in user against the course's real coordinators, and scopes the enrolment lookup to that course. This is a real fix, so verify it didn't overcorrect:
   - As a coordinator: remove a student/enrolment from **your own** course → should still succeed.
   - As a lecturer or student (non-coordinator): attempt the same action (via UI, and via direct request with a crafted `coordinator_id` if you're comfortable poking at it with devtools) → should be rejected/redirected, not succeed.
   - As a coordinator of Course A, try to affect an enrolment id belonging to Course B → should fail (previously this may have worked with the right `coordinator_id`).
2. **Progress update redirect no longer passes `tab: 'progress'`.** Create, edit, and delete a progress update → confirm you land back on the **Progress Updates tab**, not silently reset to Overview/Project Details. If tab state is meant to come from the cookie-persistence mechanism now instead of the query param, confirm that actually happens — don't assume it does.
3. **Dangling breadcrumb reference.** `config/breadcrumbs.rb`'s `crumb :topic` block was deleted, but `topics/show.html.erb` still calls `breadcrumb :topic, @topic`. Load **any** topic's show page and confirm: no error, and the breadcrumb trail at top renders sensibly (even if it's now just blank/generic — check it's not throwing).
4. **`/courses/:id/participants` route is gone entirely** (controller, route, and view all deleted) — confirm nothing in the app still links to it. Check the People tab on `courses/show` is a complete replacement, not a partial one (filters, sorting, search all present).

---

## 2. Global chrome — test once, applies to (almost) every page

The header, sidebar, and footer are shared partials rendered on ~30 views. Bugs here have the widest blast radius, so give this section real time.

- **Header:** desktop shows ProPro wordmark + breadcrumb trail + Log out; mobile (<640px) shows the current page name only, no wordmark/breadcrumb/Log out. On mobile, the settings-gear and edit-template icons should appear **only** for a coordinator, and only in the header — never doubled up with a desktop-tab version at the same width.
- **Sidebar:** hamburger toggle opens/closes it as a drawer on mobile/tablet; on desktop it's persistent and collapsible (icon-rail mode) — check the collapse/expand toggle, and that it **remembers its collapsed state across a page navigation** (cookie-based).
  - Confirm the "Enrolled" course list, "Edit profile", and "Log out" nav items all work from the collapsed (icon-only) state — hover tooltips, not just icons with no label anywhere.
- **Footer:** now rendered globally from `application.html.erb` instead of per-page. Confirm it does **not** appear on pages that are supposed to suppress it (`project/edit`, `project/new`, `topics/edit`, `topics/new`, `courses/settings`, `project_groups/index`, `sessions/new`, `passwords/new`, `passwords/edit`, `project_templates/edit`) and **does** appear everywhere else.
- **Pages with no `@course` in scope** (homescreen, static pages, `user/profile`, sign-in, password reset): confirm the header renders without error and without any course-specific icons — this was flagged in code review as guarded, but worth eyeballing directly.
- **Pages that render `shared/_sidebar` but aren't one of the three fully-redesigned show pages** (`courses/profile.html.erb`, `lecturers/show.html.erb`) — confirm the sidebar actually appears there (it's wired via `content_for(:sidebar)` rather than the inline render the redesigned pages use — different mechanism, same partial, worth checking it actually fires).
- **Pages with no sidebar at all** (`participants` doesn't exist anymore, but `progress_updates/*`, `project_groups/index`, `static_pages/*`, `user/profile` currently render with no nav chrome) — confirm that's the intended interim state and not something that reads as broken navigation to a real user.

---

## 3. Responsive matrix

Test breakpoints actually in use in this branch: **`sm` (640px)**, **`lg` (1024px)**, and a custom **`1245px`** breakpoint (`--breakpoint-comments` — governs when the comments drawer docks permanently vs. slides in as an overlay). Test at minimum these widths: **360px** (smallest supported per the docs), **639px**, **640px**, **1023px**, **1024px**, **1244px**, **1245px**, and a normal desktop width (≥1440px).

- `courses/show` — 4 tabs (Overview/Topics/People/Groups) stay visible at every width, no overflow/"More" menu, no horizontal page scroll, at 360px specifically (called out in the code as the design floor).
- `projects/show` and `topics/show` — content tabs scroll horizontally on narrow widths with a fade mask on the trailing edge that appears **only** when tabs are actually cut off (not permanently visible).
- Comments drawer: static docked column above 1245px; below that, off-canvas slide-in triggered by the chat-bubble icon in the tab bar, with a backdrop that dismisses it on tap and closes on Escape.
- Mobile review action bar (bottom-pinned version switcher + actions) — visible on mobile only, thumb-reachable, doesn't overlap the comments trigger.
- Course settings page and new/edit project & topic forms — these are full-screen "takeover" layouts (no sidebar/header/footer). Confirm they're still usable and non-overflowing down to 360px.

---

## 4. Per-role critical paths

Run each of these end to end as the actual role, not just by eyeballing the page as an admin.

**Student**
- Browse Topics Directory, propose a new project (both "Propose to Lecturer" and "Base on a Topic" paths via the method picker modal), edit a pending proposal, view own project status/history, add a comment, view/download the diff between versions, submit a progress update if the course has them enabled.
- Join a course via course code.
- Confirm a student **cannot** see coordinator-only controls anywhere in the redesigned chrome (settings gear, edit-templates icon, review-approve actions).

**Lecturer / Supervisor**
- Review a pending proposal (approve / reject / request redo), leave a comment, use the version switcher on a project with multiple versions.
- View own supervision capacity indicator where shown (People tab, lecturer card).
- `lecturers/show.html.erb` (Follow-up page, untouched styling) — confirm it still works end-to-end wrapped in the new header/sidebar.

**Coordinator**
- Course settings: every section (Class Details, General incl. coursecode widget, Permissions and Rules, Grouping) — save each independently, confirm no cross-section data loss.
- Add students / add lecturers (CSV and manual), remove a student/enrolment (see §1.1), toggle "Base on a Topic", copy a course, copy a topic between courses.
- People / Groups / Topics-directory tabs: search, sort, filter, "show all" expansion — all of these are htmx-driven partial swaps, see §6.
- Export CSV.

---

## 5. Feature-by-feature checklist

- **Course tabs (Overview/Topics/People/Groups):** switching tabs persists the active tab via a per-course cookie — reload the page and confirm it reopens on the last tab, not always Overview. Same check on `projects/show` and `topics/show` content tabs (separate cookie key).
- **Topics Directory:** supervisor groups collapse/expand individually and via "Collapse all"/"Expand all"; the current viewer's own group (staff only) is always pinned first, even at zero topics; students see plain A→Z with no pinned group.
- **`/` search shortcut on `courses/show`:** focuses the current tab's search box; if the current tab has none, jumps to the Groups search as fallback (and that jump itself gets written to the tab-persistence cookie). Confirm it's a no-op while typing in any input/textarea/select/contenteditable, and while a dialog/overlay is open.
- **Copy Topic / Copy Course overlays (Turbo Frame):** open, submit, cancel, and error paths (e.g. submitting with a required field missing) all render inside the frame correctly — confirm a validation error doesn't blow away the whole page or leave the frame in a broken state.
- **Coursecode widget:** Generate and Re-generate (this is a formless control living inside the settings form without nesting a `<form>` — worth specifically confirming the containing settings form doesn't get submitted accidentally by clicking these), and the enable/disable toggle (fires its own request outside the main form).
- **Template fields (project templates):** add/remove/reorder fields, all field types (short text, textarea, dropdown, radio), the "free-edit" flag, "is project title" flag, required/hint text — both in the template editor and reflected correctly on the actual proposal form.
- **Markdown editor (EasyMDE)** on template textareas and progress-update feedback fields — toolbar, preview mode, and that content round-trips correctly through create/edit.
- **Grouping settings / grouping preview (htmx):** changing group size min/max live-updates the preview count without a full page reload; confirm it doesn't silently show a stale preview if you change the inputs rapidly.
- **Record Progress Update modal** — open, submit, validation errors, close/cancel without submitting.
- **Empty states:** each redesigned section (My Submission with nothing submitted, no topics, no groups, no pending proposals, etc.) — confirm the actual empty-state illustration/copy shows, not a blank gap or a stray leftover element from the old styling.
- **Flash messages** — trigger a notice and an alert (e.g. failed sign-in for alert, a successful save for notice) — you mentioned these move to the bottom and expire; confirm timing/position/dismissal actually work as intended and don't stack/overlap if two fire close together.

---

## 6. JS controller interaction checklist

Each of these is new or touched this branch — exercise the actual interaction, not just page load:

| Controller | What to click/do |
|---|---|
| `sidebar` | Toggle open/close on mobile; collapse/expand on desktop; refresh and confirm collapsed state persisted |
| `tabs` / `tab-fade` | Switch every tab on `courses/show`, `projects/show`, `topics/show`; narrow the window until tabs overflow and confirm the fade mask appears/disappears correctly |
| `comments-drawer` | Open/close via trigger button and Escape key, at widths above and below 1245px |
| `modal` | Every modal-driven flow (method picker, record update modal, copy overlays where applicable) — open, close via backdrop click, close via explicit cancel |
| `dropdown` | Any dropdown/context menu introduced or restyled |
| `collapsible-sections` / `expandable-rows` | Overview section collapse, Topics-directory supervisor-group collapse — individually and via "collapse/expand all" |
| `search-shortcut` | `/` key behavior described in §5 |
| `students-select`, `expandable-rows` (post-htmx-swap) | After an htmx table swap (search/sort/filter), confirm selection state and row-expand state don't silently break — these controllers use delegated listeners specifically because the DOM gets replaced under them |
| `copy-topic` | Full copy-topic dialog flow |
| `coursecode-form-handler` | Generate/Re-generate/toggle, see §5 |
| `method-picker` | Choosing "Propose to Lecturer" vs "Base on a Topic" and confirming the right fields show |
| `version-select` | Jumping between project/topic versions from the review card and the mobile review action bar |
| `record-update-modal` | See §5 |
| `textarea-resize` | Comment box and progress-update feedback box auto-grow as you type |
| `scroll-spy` (if still wired anywhere) | Confirm intentional — this was on `main`'s old layout; check it wasn't left half-wired |

---

## 7. Regression check — Follow-up (intentionally untouched) pages

These pages weren't restyled, but they now sit inside the **new** header/sidebar/footer, so they need a smoke test even though nobody touched their content:

- Topics index (`topics/index.html.erb`) — flagged for removal later, but should still function today
- `lecturers/show.html.erb` (Lecture profile)
- `courses/profile.html.erb` (Groups profile)
- `user/profile.html.erb` (Edit profile)
- Static pages: About, Privacy Policy, Terms of Service
- `project_templates/edit.html.erb`
- Course settings' Grouping section (restyle explicitly deferred)
- Coursecode component styling (restyle explicitly deferred, functionality above is in scope)
- Flash message positioning (old behavior expected here until the restyle lands)
- "Reuse details from another topic" flow — confirm current (pre-fix) behavior is at least not worse than on `main`

For each: load it, confirm no console errors, confirm the new sidebar/header/footer don't clip or overlap its (unrestyled) content, and confirm nothing in the old markup was relying on something this branch removed from the layout (old topbar, old font stack, old breadcrumb structure).

---

## Appendix — already covered by the automated suite

Don't spend manual time re-verifying these in detail; skim them instead and go deep on gaps.

`test/system/courses/{course_tab_persistence,course_tabs,overview_tab,settings_coursecode,settings_save,solo_topics_toggle}_test.rb`, `test/system/projects/{change_status,mobile_overflow,project_form,project_show_responsive,project_versioning}_test.rb`, `test/system/topics/{change_status,copy_topic_dialog,topic_versioning}_test.rb`, `test/system/{sidebar_collapse,tabs_sticky,form_overflow}_test.rb`.

Not covered by any system test today, worth flagging to the team as an automation gap once manual QA confirms behavior: the enrolment-authorization fix (§1.1), the progress-update redirect/tab behavior (§1.2), and the People/Groups/Topics-directory htmx search-sort-filter-paginate flows (§6).