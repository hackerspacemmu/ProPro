# ADR 009 — Sibling forms on course settings

Date: 2026-08-29
Status: Superseded by ADR-0010

## Context

The course settings redesign (Google-Classroom-style mockup) renders the
coursecode subsection inside SECTION 2 (General), which on `main` lives inside
the outer settings `<form>`. But `_course_code_form.html.erb` opens its own
`<form>` (posted to `update_coursecode`, wired to the `coursecode-form-handler`
Stimulus controller and the `course_code_form` turbo frame). A `<form>` nested
inside another `<form>` is invalid HTML5; browsers silently drop the inner
`<form>` open tag, so the Stimulus controller never connects and Generate /
"Allow joining via course code" silently no-op. The page has zero system,
request, or policy test coverage, so nothing in CI can catch it.

The alternative — merging the coursecode fields into the settings form and
moving persistence into `handle_settings` — was rejected for two reasons:

- A regenerate-credential control (Join Code, API key, invite code) is a
  distinct, idempotent, side-effecting action expected to fire immediately and
  independently of unsaved form state. Tying it to the settings Save couples
  two unrelated persistence moments in both directions.
- `Course#generate_coursecode!` does its own `save!` and raises for grouped
  courses. Called inside `handle_settings`'s transaction, that guard failing
  would roll back the entire settings save (course name, permissions, grouping,
  supervisor capacity).

The mockup's "General wraps Coursecode" is a design-sketch consequence of
nesting; it cannot be reproduced with a DOM-sibling form using ordinary flow
CSS, and position tricks are fragile.

## Decision

Course settings is a **sibling-forms page**:

- The settings `<form id="course-settings-form">` (posted to
  `handle_settings`) wraps Class Details, Supervisor Capacity, Permissions and
  Rules, Grouping, and the footer actions.
- `_course_code_form` keeps its own `<form>`, the `update_coursecode` endpoint,
  the `coursecode-form-handler` controller, and the `course_code_form` turbo
  frame. It renders as a peer section card below the settings form, restyled to
  match the other section cards, and its Generate/toggle persist immediately.
- The `form="..."` attribute may be used to associate a submit button that
  lives outside its form (ADR-0005), but is not required while the sticky
  header stays inside the settings form.

Invariant: **a partial that contains its own `<form>` renders only as a
page-level sibling of any other form, never inside one.**

## Consequences

- Generate / Re-Generate and the enable toggle keep immediate, independent
  persistence with their own flash messages; no cross-action transaction
  coupling.
- The mockup's "General" container is dropped; Coursecode and Supervisor
  Capacity are standalone section cards, and there is no valid-HTML violation.
- `update_coursecode`, `coursecode_form_handler_controller.js`,
  `_course_code_form.html.erb`, and `update_coursecode_test.rb` are untouched
  (aside from restyling and the locals-only `course:` conversion).
- `handle_settings`'s whitelist never gains `coursecode` / `coursecode_enabled`
  (unchanged anchor).
- A new system test exercises the coursecode generate/toggle path through the
  settings page DOM.