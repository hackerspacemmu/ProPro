# ADR 015 — Server-rendered fragment swapping: htmx vs Turbo Frames vs Turbo Streams

Date: 2026-09-07
Status: Accepted

## Context

ProPro is server-rendered Rails with Hotwire (Turbo + Stimulus) via importmap. It
swaps rendered HTML fragments in response to requests in three ways, and all
three are live today:

- **htmx** (`import "htmx.org"` in `app/javascript/application.js`, re-processed
  with `window.htmx.process(document.body)` on every `turbo:load`). Used
  extensively on `courses/show` for the People, Groups, and Topics-directory
  interactions — search, sort, filter, paginate — across `_groups_tab`,
  `_topics_section`, `_students_section`, `_sort_header`, `_students_table`,
  `_groups_table`, `_topics_by_supervisor_list`, plus `settings.html.erb`.
- **Turbo Frames** — `turbo_frame_tag "overlay_content"` with `data-turbo-frame`
  form navigation, driving the multi-step copy-topic and copy-course overlays.
- **Turbo Streams** — the coursecode widget (`turbo_stream.replace` applied via
  `Turbo.renderStreamMessage` in `coursecode_form_handler_controller.js`, plus
  `turbo_stream.update('flash', ...)`).

The correctness audit (docs/correctness_plan.md §7) flagged this as reading like
"two different answers to 'how do we swap HTML'" living in different corners of
the same app, with the next contributor having no guidance on which to reach for
on the next table.

## Decision

Pick the mechanism by the **shape of the interaction**, not by preference:

- **htmx** — the request composes **multiple sibling filter/sort/pagination
  inputs** and re-renders a whole region (table body, list, section). `hx-include`
  / `hx-vals` fold several controls into one round-trip declaratively, and the
  request lands on a controller action that re-renders a partial with locals.
  This is the default for table- and directory-style browse/filter interactions.
- **Turbo Frames** — the response is driven by **navigation itself**: a frame
  targets a named region and swaps it with the body of a real GET navigate
  (link or form). Use for step-wise modal content where each step is its own
  URL/render — the copy-topic and copy-course overlays.
- **Turbo Streams** — the swap is a **single surgical fragment** that has side
  effects or must update unrelated target(s) out of band (the coursecode
  widget plus the flash message in one response). Not used for browse/filter;
  used when "re-render this one thing, and maybe that other thing too".

The deciding question is: *Is this a multi-input partial re-render (htmx), a
navigable frame (Turbo Frames), or a targetable single-fragment update
(Turbo Streams)?*

## Consequences

- A contributor building a new table/filter reaches for htmx and follows the
  existing partial + locals + `hx-include` pattern, rather than inventing a new
  mechanism.
- Multi-step dialog content stays on Turbo Frames; single-fragment surgical
  updates with side effects stay on Turbo Streams.
- Because htmx re-renders destroy Stimulus-bound DOM, Stimulus controllers that
  live inside htmx-swapped regions must keep working through delegated
  listeners or (`re`)subscription on `htmx:afterSwap` — the existing
  `students_select_controller.js` / `expandable_rows_controller.js` pattern —
  rather than `connect()`-time mutation of swapped children.
- No new mechanism is banned outright; a future genuinely different shape of
  interaction can be added to this mapping via a new ADR.