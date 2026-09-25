# ADR 017 — Copy-topic step-1 rows reuse shared/list_item via defaults-preserving locals

Date: 2026-09-24
Status: Accepted

## Context

The "Select a Topic to Copy" list (step 1 of the `_copy_topic_overlay` modal) is
being redesigned to the `copy_topic_overlay_mockup`: a sticky header/footer with
a center-scrolling approved-topic list. The mockup's rows differ from today's
`shared/_list_item` chrome — roomier `p-5` padding, `hover:bg-surface-hover`,
`w-10 h-10` icon, `font-medium` title, no `more_vert` action button, and the
owner emphasized in the metadata line. The course name moves into the meta line
(`owner • course • Updated X ago`), replacing the old below-row "Course" chip
block.

`shared/_list_item` already hard-codes that chrome for every call site
(`_overview_tab`, `_topic_item`, `projects/_list_item`, the styleguide). The
tempting shortcuts are both wrong: (a) copy the row markup into the overlay
partial as a bespoke third row language that diverges from the shared one, or
(b) change the shared component's defaults app-wide to match the mockup, which
would silently re-skin the Overview, topic directory, profiles, and styleguide.

The codebase already has the right mechanism for "reuse a list row, vary its
chrome": domain wrapper partials (`courses/_topic_item`, `projects/_list_item`)
that build a `render_options` hash for `shared/_list_item`, gated by locals.

## Decision

Extend `shared/_list_item` with four default-preserving style locals, and render
the copy-topic rows through a new thin domain wrapper in
`topics/_copy_topic_list_item.html.erb` (mirroring `courses/_topic_item`), calling
`shared/_list_item` — never re-implementing row markup.

The new locals (all omit-able; omission = today's byte-identical output):

- `hide_more_vert` (bool, default `false`) — drop the hover-only action button.
- `title_weight` (int, default `400`) — title font weight; picker passes `500`.
- `density: :comfortable` (default `:default`) — one knob for the roomier row:
  `p-5`, `hover:bg-surface-hover`, `w-10 h-10` icon, and pill `py-1`, all
  together.
- `meta_first_strong` (bool, default `false`) — first meta part (the owner)
  renders `font-medium text-on-surface-variant`.

The overlay partial loops `@approved_topics` manually (not via `shared/_list`,
whose container hard-codes a `border-b` that would double the sticky footer's
border-t), passing `border_top: false` on the first row so it sits flush under
the header. Course name is passed as a second `meta_parts` entry.

The dialog stays `max-w-4xl` (one shared `<dialog>`, content-swapped by the turbo
frame; the step-1 mockup's `max-w-3xl` is stale).

## Consequences

- One row language: the picker, Overview, topic directory, profiles, and
  styleguide all still render through `shared/_list_item`.
- Defaults are preserved; every existing call site renders byte-identically
  (verified by the green suite).
- `shared/_list_item`'s local surface grows by four; each is narrow and
  explicitly default-preserving, not a free-form class escape hatch.
- The overall copy-topic step 1 chrome (sticky header/footer, full-bleed scroll
  region) lives in `_copy_topic_overlay.html.erb`; the rows live in the shared
  component. Any future "roomier list" reuses `density: :comfortable` for free.