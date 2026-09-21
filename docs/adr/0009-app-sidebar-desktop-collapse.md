# ADR 009 — App sidebar: desktop collapsible icon rail (amends ADR-0008)

Date: 2026-09-06
Status: Accepted

## Context

ADR-0008 (2026-08-29) turned the app-wide sidebar into a mobile off-canvas
drawer and a static column at `lg+`, and in doing so deleted a prior
"desktop collapse-to-rail + `localStorage`" feature from `sidebar_controller`,
recording the decision going forward as *"no resize listener, no width-class
juggling, no localStorage, no desktop collapsible rail."*

This ADR reopens exactly that clause. Design review (Google Classroom
reference) and the working-tree reality both changed the calculus:

- The old feature was dead weight because its *width values lived in JS*:
  `w-64`/`w-48`/`w-0` toggled from the controller against an `<aside>` that
  was actually `w-[280px]` — the two never agreed, so it silently no-op'd.
- The app's persistence convention has since settled on **plain cookies read
  server-side** (`tabs_controller.js` → `current_tab_index`), which avoids the
  `localStorage` concern ADR-0008 flagged and eliminates the flash of the
  wrong sidebar width on first paint.

## Decision

Reopen desktop collapse — **not by restoring the 2026-08-29 feature**, but on
a mechanism that structurally removes the failure mode that killed it:

- **State lives in one attribute:** `data-collapsed="true|false"` on
  `<aside id="app-sidebar">`, server-rendered from
  `propro_sidebar_rail_collapsed` via `ApplicationHelper#sidebar_collapsed?`.
- **All visual differences are Tailwind CSS variants**
  (`group-data-[collapsed=true]/sidebar:lg:*`). No JS width-class juggling:
  the width value `w-[72px]` exists only in the markup class list and is
  referenced, never duplicated, by a CSS variant.
- **Persistence is a plain cookie** (`propro_sidebar_rail_collapsed`,
  `path=/`, `max-age=31536000`, `samesite=lax`, `secure` over HTTPS), written
  client-side exactly like `tabs_controller.js`, read server-side at render.
  `localStorage` remains banned.
- **Mobile off-canvas drawer is untouched.** Every collapsed-specific class is
  gated at `lg:`; `data-collapsed` never affects the below-`lg` drawer.
- **Chrome breakpoint stays independent of content breakpoints** (`lg` = 1024
  for chrome vs `min-[1245px]` for the comments drawer). The rail-collapse is
  a single state toggle at `lg+`, not a third mid-width state.
- **Legacy sidebar deleted.** The `render_sidebar` helper and its
  TOC/scrollspy pattern (`courses/profile`, `lecturers/show`) were the last
  consumers of a second, old-gray sidebar; both pages now render the shared
  partial. No page renders two sidebar implementations anymore.
- **One controller.** `sidebar_controller` keeps BOTH breakpoint behaviors;
  `toggle()` is breakpoint-aware (`matchMedia("(min-width: 1024px)")`), and
  `aria-expanded` reflects whichever state is relevant at the current width.

## Consequences

- The desktop rail collapses 280px → 72px, hiding labels and the entire
  "Enrolled" group (per the reference screenshots — gone, not icon-ified);
  expanded nav items remain scrollable, while collapsed content is short by
  construction and overflow-visible so the CSS hover tooltips can escape the
  rail.
- Persistence survives navigation and reload with no flash of the wrong width
  column for returning users.
- Collapse state arriving in a real rendered `<aside>` means the legacy
  class-list toggler (the thing ADR-0008 tore out) cannot silently drift from
  markup again — the state bit and the markup class list are one source.
- The `lg` chrome breakpoint decision in ADR-0008 stands unamended; only the
  "no desktop collapsible rail" clause is superseded.
- Two embedding styles of the same partial now coexist transiently: direct
  `render "shared/sidebar"` inside page-level flex rows (`courses/show`,
  `projects/show`, `topics/show`) and through the layout `:sidebar` slot
  (`courses/profile`, `lecturers/show`). Unifying those is out of scope here.

## Papers

- ADR-0008 §Decision (clause superseded): *"no resize listener, no width-class
  juggling, no localStorage, no desktop collapsible rail."*
- `docs/sidebar_collapsable_plan.md` — the design this ADR authorizes.