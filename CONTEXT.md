# ProPro Glossary

Shared vocabulary for ProPro. A term lands here the moment it is agreed. No
implementation detail, no spec — just the project's own words and tight
definitions.

## Projects & proposals

- **proposal** — a project before approval ("Pending" status). Called "Project" once approved.
- **project instance / instance / version** — a `project_instance` on a project; a new one is created on each edit. `current_instance` is the latest. Submitted values live on `project_instance_fields`.
- **proposal method** — how a proposal is submitted: **Propose to Lecturer** (own proposal) or **Base on a Topic**.
- **own proposal** — a proposal submitted directly to a lecturer. Encoded in `based_on_topic` as `own_proposal_<enrolment_id>`.
- **based_on_topic** — the single hidden form field carrying the proposal-method choice: `own_proposal_<enrolment_id>` or `<topic_id>`. Read by `create`/`update` to derive the supervisor enrolment.
- **method picker** — the in-form modal dialog that lists lecturers/topics and applies a proposal-method selection without navigating away.

## Courses

- **solo supervisor course** — a course with fewer than three lecturer+coordinator enrolments. No lecturer choice exists; proposals default to the single lecturer (`Course#solo_supervisor?`).
- **toggle topics** — `Course#toggle_topics`; gates whether "Base on a Topic" exists at all.

## Course settings

- **course settings** — the coordinator's settings page for a course: a takeover-layout form (`no_sidebar` + sticky top nav, Save inside the form) whose section cards are Class Details · General · Permissions and Rules · Grouping. General holds the **coursecode widget** and the Supervisor Capacity subsections.
- **settings sections** — the section cards on course settings: Class Details · General · Permissions and Rules · Grouping (headers styled `text-3xl font-normal text-gray-800 tracking-tight`, per the mockup). General's subsection cards are Coursecode and Supervisor Capacity. Grouping's two-mode card set is driven by `@course.grouping_enabled?` / `student_list_finalised?`.
- **coursecode widget** — the formless control inside General (ADR-0010): no `<form>` in the static DOM, so it lives inside `#course-settings-form` without nesting one. Generate/Re-Generate is a `data-turbo-method: :post` link to `update_coursecode_course_path(course, generate: true)`; the toggle fires its own `fetch` + `Turbo.renderStreamMessage`. Both keep `course_code_form`, `coursecode-form-handler`, and `Course#coursecode` semantics; `coursecode` and `coursecode_enabled` stay out of `handle_settings`' whitelist. Its partial's single top-level node must be the `course_code_form` turbo frame.

## Template fields

- **template fields** — `project_template_fields` on a course's template; typed `shorttext`/`textarea`/`dropdown`/`radio`, with `required`, `hint`, `free_edit`, `is_project_title`, and `applicable_to` attributes.
- **free-edit field** — a template field that stays editable after the proposal is approved.
- **supervisor capacity** — `approved_count / effective_cap · pending_count` for a lecturer in a course, computed by `SupervisorCapacityCalculator`.

## Project show (review + comments)

- **content tabs** — the Project Details / Compare Versions / Progress Updates tab set in the sticky tab bar. Constant at every width; screensize never adds tabs. Scrolls horizontally on narrow screens with the scrollbar hidden; a **tab fade mask** (`tab-fade`) paints a trailing-edge white-to-transparent gradient only while more tabs are actually cut off.
- **review actions** — the shared version switcher + policy-driven actions (`_review_actions`), rendered in either the review card (desktop) or the review action bar (mobile).
- **review card** — the desktop-only Review Project card (title + Active badge) hosting `_review_actions`.
- **review action bar** — the mobile-only pinned bottom bar (version switcher + actions) hosting the same `_review_actions`; thumb-reachable on every tab.
- **comments drawer** — one element, two presentations: the static sticky comments column on desktop; a backdrop-toggled off-canvas slide-in on mobile (`top-0 right-0 bottom-0` + `translate-x-full`, escaped by `min-[1245px]:translate-x-0`), opened by the comments trigger. Controlled by `comments-drawer`.
- **comments trigger** — the mobile-only tab-bar button (chat bubble + count badge) that opens/closes the comments drawer (`aria-expanded` mirrors open state).

## Course show (Overview)

- **course tabs** — the Overview / Topics / People / Groups tab set on `courses/show`. All four are always visible at every width; no overflow menu, no "More" dropdown, no horizontal scroll. Styled like Google Classroom: blue 3px underline on the active tab, 14px / 500 weight, tightened spacing so four names fit at 360px. Each tab carries a stable `slug` (`overview`/`topics`/`people`/`groups`), and the active tab is persisted to a per-course plain cookie (`propro_tab_course_<id>`) via `tabs`' `persistKey` value.
- **search shortcut / slash shortcut** — the `/` keyboard shortcut on `courses/show`. Pressing `/` focuses the current tab's search input; if the current tab has none, it jumps to the **fallback** (Groups) first. No-op while typing in an input/textarea/select/`contenteditable`, and while any `<dialog>` is open.
- **search-shortcut controller** — `search_shortcut_controller.js`, a Stimulus controller scoped to the same element as `tabs` on `courses/show`. It listens globally on `window` for the `/` key but queries only within its own element. Search inputs opt in via `data-search-shortcut-target`; running the shortcut always **persists** the landing tab to the cookie (the fallback jump is a real click, so it leaves a cookie trail like any manual tab switch).
- **fallback input / fallback destination** — the Groups search box (`#groups-search`), tagged `data-search-shortcut-target="input fallbackInput"`. The fixed destination the shortcut jumps to when the current tab has no search input (Groups search matches both groups and students). Hardcoded; never derived from tab order or saved preference.
- **kbd badge** — the visual `<kbd>/</kbd>` hint inside each search input (GitHub-style): a `<kbd aria-hidden="true">` positioned right inside the box, `hidden md:flex` (invisible on touch-only viewports), hidden on input focus via `peer-focus:hidden`, `pointer-events-none`. Purely decorative — no screen-reader or otherwise accessible equivalent.
- **settings gear** — the course settings link. On desktop, renders as an inline tab-row link (unchanged). On mobile (<sm / 640px), relocates to the header's action slot as a gear icon. Never appears in both places at the same width.
- **mobile header** — on mobile (<sm / 640px): hamburger menu · course name (truncated if long) · · · settings gear. No ProPro wordmark, no breadcrumb trail, no Log out. On desktop (≥sm): unchanged from current — wordmark, full breadcrumb trail, Log out link.
- **Overview** — the first content tab on `courses/show`, renamed from "Project Details". A max-w-[800px] centered column consolidating the Project Details card plus the Supervised Projects, Pending Proposals, Reviewed Proposals, and Pending Topics sections. A temporary consolidation while the To Review and Supervised Projects tabs remain (kept for a later deletion pass). Rendered by `_overview_tab.html.erb`.
- **section header** — the collapsible title row at the top of each Overview section (title + blue count + `expand_less` chevron). Toggles its own row list via **collapsible section**. Long titles truncate rather than wrap.
- **row item** — the mockup's list row language shared by proposals and topics: circular icon avatar, title + meta on the left, status pill inline at the end of the meta line, and the time line (`time_meta`, "Submitted X ago") as the right-side text at 1rem/400/1.5rem. One line at every width. Topics render as row items (not colored cards) at every `_topic_card` call site.
- **collapsible section** — an Overview section plus its row list, toggled by its **section header**; all four are toggled together by the **Collapse all / Expand all** button (`unfold_less`/`unfold_more`). Wired by the `collapsible-sections` Stimulus controller (`data-collapsible-sections-target="toggle"/"body"` paired by `data-collapsible-sections-section`). The section's top divider line lives outside the collapsible body (`_row_list` `borderless_first:`), so it persists when the section is collapsed. Sections load expanded, show their empty-state sentence when empty, and hold no state persistence.

## App chrome

- **app sidebar** — `shared/_sidebar`: app-wide nav (Home / courses / Edit profile), plus the `render_sidebar` helper widget for legacy pages. One element, two presentations: a static left column at ≥`lg` (1024px), an off-canvas drawer below it opened by the header menu icon. Controlled by `sidebar`. Its breakpoint is chrome-level and deliberately independent of content breakpoints (e.g., the `min-[1245px]` comments drawer).
- **drawer idiom** — the shared pattern for "drawer over content": a single element that is a static in-flow column on desktop (`lg:static lg:translate-x-0` / `min-[1245px]:translate-x-0`) and an off-canvas panel below it; the controller toggles the translate class, the off-state whitespace classes (`shadow-2xl`, `border-l` for `comments-drawer` so they can't paint into the viewport while closed), the backdrop `hidden`, body scroll lock, and `aria-expanded`. Used by `sidebar` and `comments-drawer`.
- **breadcrumb anchor / ProPro wordmark** — the first breadcrumb item: the "ProPro" wordmark link to `root_path`. Replaces the old "Dashboard" root crumb (which is no longer rendered). Desktop-only (rendered inside the `sm+` breadcrumb row). Google-Classroom-styled — bigger than the child crumbs (1.5rem/400) with a muted color that darkens on hover. Skipped (hidden) on pages under the **takeover layout**, which hide breadcrumbs.
- **breadcrumb chevron** — the inline-SVG right-pointing separator between breadcrumb items, replacing the old textual `>`. Purely decorative.
- **breadcrumb crumb** — any non-anchor breadcrumb item rendered by `BreadcrumbHelper#render_custom_breadcrumbs`, styled smaller than the anchor (1rem/500).
- **takeover layout** — the chrome-less full-screen form surface (ADR-0005): `no_sidebar`, hidden toggler/breadcrumbs, a sticky action header, and a single centered form column. Shared by projects/edit, projects/new, and course settings.

## Form actions

- **Discard Changes / Cancel** — the same behavior by either name: leave the form without saving.