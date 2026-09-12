# ADR 010 — Formless coursecode widget on course settings

Date: 2026-08-30
Status: Accepted
Supersedes: ADR-0009

## Context

ADR-0009 kept the coursecode control as a standalone sibling `<form>` below the
settings form so it would never nest inside the settings form's HTML. That
worked but drifted from the Google-Classroom mockup on three fronts:

1. **Placement** — the mockup puts Coursecode inside SECTION 2 (General). A
   DOM-sibling form cannot live inside the settings form; position tricks were
   rejected in ADR-0009.
2. **Behavior** — Course code widgets (Classroom's "Manage invitation codes",
   an API-key rotate button) are not forms; each control fires its own
   immediate request, with no submit ceremony.
3. **Bug** — the standalone sibling card with an inner layout wrapper
   (`w-full max-w-4xl mx-auto px-4 sm:px-6 pb-8 -mt-8` around the
   `<turbo-frame id="course_code_form">`) made the card "keep getting slimmer"
   on every Generate click. Turbo Streams `replace()` swaps in the **entire**
   `<template>` content (`targetElement.replaceWith(this.templateContent)`
   where `templateContent` is a `cloneNode(true)` of the whole template), so the
   wrapper got re-nested inside itself on each swap, stacking the negative
   margin, padding, and max-width.

## Decision

The coursecode widget is **formless** — no `<form>` in the static DOM, like the
mockup and like every well-known regenerate/invite-code control:

- **Generate / Re-Generate** is a plain `link_to` to
  `update_coursecode_course_path(course, generate: true)` with
  `data: { turbo_method: :post }`. Turbo's link observer synthesizes a
  throwaway `<form>` at click time (`followedLinkToLocation`), copies the URL's
  search params into hidden fields so `params[:generate] == "true"`, and its
  `FormSubmission` renders the returned turbo stream in place. No page reload,
  no code, and nothing to keep in sync with the settings form.
- **Allow joining via course code** stays a toggle whose
  `coursecode-form-handler` controller fires its own `fetch()` POST body
  `course[coursecode_enabled]=1|0` (CSRF from the meta tag, `Accept:
  text/vnd.turbo-stream.html`) and renders the response with
  `Turbo.renderStreamMessage`.
- The partial's **single top-level node is exactly `<turbo-frame
  id="course_code_form">`** — `data-controller`, the url value, and the box
  styling live on the inner element. The frame sits inside the settings form's
  General section; because it holds no `<form>`, nesting is valid HTML.
- `update_coursecode` (controller, routes) and its integration tests are
  unchanged; `coursecode` / `coursecode_enabled` stay out of
  `handle_settings`'s whitelist.

## Consequences

- Coursecode and Supervisor Capacity now sit where the mockup puts them —
  subsections of a General card — while `handle_settings` and
  `update_coursecode` remain independent actions with their own flash messages.
- The settings form save no longer can be rolled back by a coursecode call, and
  a Generate click can no longer re-nest the frame layout.
- The old sibling-form protocol (`form_with`, hidden generate flag,
  `submitForm`) is deleted; ADR-0009 is superseded.
- A system test guards the widget (`settings_coursecode_test.rb`): it proves
  the page holds only one `<form>` (the settings form), that the widget renders
  **no** nested form inside `#course-settings-form` / `#course_code_form`, and
  drives generate/toggle through the real Turbo paths (re-generate swaps the
  code, toggle persists independently).
- **Invariant:** a partial served by a Turbo Stream `replace` must have
  exactly one top-level node, and it must *be* the replacement target frame —
  any wrapper gets cloned and re-nested with every stream.