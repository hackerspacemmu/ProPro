# ADR 005 — Full-screen takeover layout for the proposal forms

Date: 2026-08-28
Status: Accepted

## Context

The redesigned `show` keeps the shared sidebar. The mockup for `edit`/`new`
is a full-screen takeover: `no_sidebar`, `hide_toggler`, `hide_breadcrumbs`,
a sticky action header, and a single centered form column.

## Decision

`edit.html.erb` and `new.html.erb` use the takeover layout exactly as the
mockup specifies. Header actions ("Discard Changes", submit) and the bottom
bar (Cancel, submit) are bound to the form element via `form=` (the header
sits outside the `<form>` tag for sticky layout).

## Consequences

- Editing is an interruption-free, focused surface.
- Header submit buttons must reference the form by `id`; both submit buttons
  share one form and one action.