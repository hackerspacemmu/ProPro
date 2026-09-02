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

- **Overview** — the first content tab on `courses/show`, renamed from "Project Details". A max-w-[800px] centered column consolidating the Project Details card plus the Supervised Projects, Pending Proposals, Reviewed Proposals, and Pending Topics sections. A temporary consolidation while the To Review and Supervised Projects tabs remain (kept for a later deletion pass). Rendered by `_overview_tab.html.erb`.
- **section header** — the collapsible title row at the top of each Overview section (title + blue count + `expand_less` chevron). Toggles its own row list via **collapsible section**. Long titles truncate rather than wrap.
- **row item** — the mockup's list row language shared by proposals and topics: circular icon avatar, title + meta on the left, status pill inline at the end of the meta line, and the time line (`time_meta`, "Submitted X ago") as the right-side text at 1rem/400/1.5rem. One line at every width. Topics render as row items (not colored cards) at every `_topic_card` call site.
- **collapsible section** — an Overview section plus its row list, toggled by its **section header**; all four are toggled together by the **Collapse all / Expand all** button (`unfold_less`/`unfold_more`). Wired by the `collapsible-sections` Stimulus controller (`data-collapsible-sections-target="toggle"/"body"` paired by `data-collapsible-sections-section`). The section's top divider line lives outside the collapsible body (`_row_list` `borderless_first:`), so it persists when the section is collapsed. Sections load expanded, show their empty-state sentence when empty, and hold no state persistence.

## App chrome

- **app sidebar** — `shared/_sidebar`: app-wide nav (Home / courses / Edit profile), plus the `render_sidebar` helper widget for legacy pages. One element, two presentations: a static left column at ≥`lg` (1024px), an off-canvas drawer below it opened by the header menu icon. Controlled by `sidebar`. Its breakpoint is chrome-level and deliberately independent of content breakpoints (e.g., the `min-[1245px]` comments drawer).
- **drawer idiom** — the shared pattern for "drawer over content": a single element that is a static in-flow column on desktop (`lg:static lg:translate-x-0` / `min-[1245px]:translate-x-0`) and an off-canvas panel below it; the controller toggles the translate class, the off-state whitespace classes (`shadow-2xl`, `border-l` for `comments-drawer` so they can't paint into the viewport while closed), the backdrop `hidden`, body scroll lock, and `aria-expanded`. Used by `sidebar` and `comments-drawer`.
- **takeover layout** — the chrome-less full-screen form surface (ADR-0005): `no_sidebar`, hidden toggler/breadcrumbs, a sticky action header, and a single centered form column. Shared by projects/edit, projects/new, and course settings.

## Form actions

- **Discard Changes / Cancel** — the same behavior by either name: leave the form without saving.