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

## Template fields

- **template fields** — `project_template_fields` on a course's template; typed `shorttext`/`textarea`/`dropdown`/`radio`, with `required`, `hint`, `free_edit`, `is_project_title`, and `applicable_to` attributes.
- **free-edit field** — a template field that stays editable after the proposal is approved.
- **supervisor capacity** — `approved_count / effective_cap · pending_count` for a lecturer in a course, computed by `SupervisorCapacityCalculator`.

## Project show (review + comments)

- **content tabs** — the Project Details / Compare Versions / Progress Updates tab set in the sticky tab bar. Constant at every width; screensize never adds tabs.
- **review actions** — the shared version switcher + policy-driven actions (`_review_actions`), rendered in either the review card (desktop) or the review action bar (mobile).
- **review card** — the desktop-only Review Project card (title + Active badge) hosting `_review_actions`.
- **review action bar** — the mobile-only pinned bottom bar (version switcher + actions) hosting the same `_review_actions`; thumb-reachable on every tab.
- **comments drawer** — one element, two presentations: the static sticky comments column on desktop; a backdrop-toggled off-canvas slide-in on mobile (`top-0 right-0 bottom-0` + `translate-x-full`, escaped by `min-[1245px]:translate-x-0`), opened by the comments trigger. Controlled by `comments-drawer`.
- **comments trigger** — the mobile-only tab-bar button (chat bubble + count badge) that opens/closes the comments drawer (`aria-expanded` mirrors open state).

## App chrome

- **app sidebar** — `shared/_sidebar`: app-wide nav (Home / courses / Edit profile), plus the `render_sidebar` helper widget for legacy pages. One element, two presentations: a static left column at ≥`lg` (1024px), an off-canvas drawer below it opened by the header menu icon. Controlled by `sidebar`. Its breakpoint is chrome-level and deliberately independent of content breakpoints (e.g., the `min-[1245px]` comments drawer).
- **drawer idiom** — the shared pattern for "drawer over content": a single element that is a static in-flow column on desktop (`lg:static lg:translate-x-0` / `min-[1245px]:translate-x-0`) and an off-canvas panel below it; the controller only toggles the translate class, the backdrop `hidden`, body scroll lock, and `aria-expanded`. Used by `sidebar` and `comments-drawer`.

## Form actions

- **Discard Changes / Cancel** — the same behavior by either name: leave the form without saving.