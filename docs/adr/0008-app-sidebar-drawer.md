# ADR 008 — App sidebar: off-canvas drawer below lg; chrome breakpoint independent of content

Date: 2026-08-29
Status: Accepted

## Context

The app-wide sidebar (`shared/_sidebar`) was a static `w-[280px]` column that
squeezed page content on small screens, and the header menu button was
cosmetic. `sidebar_controller` was wired to a contract the markup never
spoke: it toggled `w-64`/`w-48`/`w-0` plus opacity classes on an aside styled
`w-[280px]`, and showed a backdrop through `opacity-0/opacity-100` while the
backdrop's real visibility was gated by the `hidden` utility (display:none)
it never touched. The "desktop collapse-to-rail + localStorage" behavior in
that controller was dead weight — those width classes never matched the
markup, so it never worked. Further, the controller was scoped on the
application-layout flex wrapper, while `projects/show` and `courses/show`
render `shared/_sidebar` directly inside their own body (not via the
`:sidebar` slot), so on those pages the targets were out of scope entirely.

## Decision

Make the sidebar a drawer below `lg` (1024px) using the exact idiom already
established for the comments drawer, and leave it a static column at `lg`
and up:

- One element, two presentations: `fixed top-0 left-0 h-full z-50
  -translate-x-full` below `lg`, `lg:static lg:translate-x-0 lg:transition-none`
  at `lg`+; backdrop `hidden fixed inset-0 z-40 lg:hidden`.
- The controller only toggles `-translate-x-full` / `hidden` / body scroll
  lock / `aria-expanded`; no resize listener, no width-class juggling, no
  localStorage, no desktop collapsible rail.
- **Chrome breakpoint is deliberately independent of content:** `lg` (1024)
  for the app chrome, vs `min-[1245px]` for content-level layouts like the
  comments drawer on `projects/show`. At 1024–1244px the sidebar is static
  while comments are already a drawer.
- Controller scope moved to `<body>` (`data-controller="scroll-spy
  sidebar"`) so it resolves wherever the sidebar is embedded — directly
  (`courses/show`, `projects/show`) or via the `:sidebar` slot. The legacy
  `render_sidebar` helper (`courses/profile`, `lecturers/show`) migrated to
  the same target names and classes.
- `Escape` closes; `turbo:before-visit` resets drawer + scroll lock so a
  navigation from an open drawer can't strand `overflow-hidden` on `<body>`.

## Consequences

- Menu button now works on every page that renders the sidebar; hidden at
  `lg`+ (`lg:hidden`), so desktop shows the static column with no collapse.
- One mental model for "drawer over content" across the app — the sidebar
  and the comments drawer share the translate/backdrop/reset idiom.
- Sidebar drawer (`z-50`/`z-40`, left edge) and comments drawer (same
  z-levels, right edge) coexist on the same page; both open only one at a
  time in practice, but a future change that can open both simultaneously
  must re-audit z-index and body-lock interplay.
- `rack_test` system tests cannot resize the viewport, so coverage is
  structural (targets + aria attrs present); behavioral/visual verification
  requires a real browser pass.