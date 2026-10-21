# ADR 0021 — The landing page is a single self-contained view

Date: 2026-10-12
Status: Accepted

> Note: `docs/adr` is gitignored (as of `59042816`); this record is local-only
> by repo convention.

## Context

The landing page at root began as a working spike (`pages#showcase_test`) whose
design was signed off as-is: a hero, a sticky section-menu pill, three feature
sections that auto-advance between items, a stat and a closing CTA, with
screenshots enlarged in a lightbox. The spike was one 400-line view — inline
`<style>` and inline `<script>`, hardcoded hero copy, and a `signup_path`
placeholder.

Making it permanent surfaced two tensions with the app's usual conventions:

- The app renders chrome (sidebar/header/footer), tokens and Stimulus
  controllers everywhere else, and every page is partialized.
- The landing page is a deliberate brochure page: a frozen snapshot of copy and
  screenshots, built once and rarely touched, with no interaction with the rest
  of the app. Extracting its bespoke CSS into the shared token system would
  either pollute the global stylesheet with page-only rules or force a
  normalized palette onto a signed-off design.

## Decision

Ship the landing page as a **single self-contained view**
(`app/views/landing/show.html.erb`):

- Markup, a bespoke `<style>` block, its private `sections`/`screenshots`/`hints`
  data and the static inline SVG section icons all live in the one view. No
  partials, no token conversion, no i18n, no extracted stylesheet. A comment at
  the top of the view states this is intentional.
- The **JavaScript moves into three Stimulus controllers** (per repo
  convention), registered like every other controller via
  `pin_all_from`/`eagerLoadControllersFrom`:
  - `landing_controller.js` — one instance per feature section: 7s auto-advance,
    fill-bar growth, image swap, touch/swipe, off-screen and reduced-motion
    pausing, panel height-lock, full `disconnect()` teardown.
  - `lightbox_controller.js` — the enlarged screenshot as a native `<dialog>`
    (scroll lock, focus restore, Escape/button/margin close).
  - `jump_bar_controller.js` — the sticky pill's IntersectionObserver
    active-link highlighting and horizontal reveal.
- Screenshots are **static PNGs** from `app/assets/images/landing/`, not a live
  demo. The section icons are literal SVG constants (no user input) and stay
  inline with `.html_safe`.
- Route: `root 'landing#show'` (public, `allow_unauthenticated_access`).
  Signed-in visitors are redirected to `dashboard_path`; the dashboard keeps
  `/dashboard` and all post-login redirects stay on it. No logged-in variant of
  the landing page exists.
- Both call-to-action buttons read "Log in to ProPro" and point at
  `login_path`; the earlier plan to link self-sign-up (`user_new_path`) was
  dropped when the copy changed the primary action to logging in.

## Consequences

- The page's visual identity is frozen with its markup; a redesign touches one
  file and cannot drift from its CSS.
- The app's linters still cover the view (`@herb-tools/linter`) and the
  controllers (eslint/prettier); behavior logic is testable Server-side via the
  integration test (`landing_page_test.rb`).
- The page makes no requests and has no server-backed state; if a redesign ever
  needs shared styling or dynamic copy, this decision is revisited rather than
  the page being incrementally extracted.
- The landing page ignores the app's token system by explicit choice, which the
  glossary records so future work doesn't "fix" it by accident.

## References

- Related glossary: **landing page**, **showcase section**, **showcase item**,
  **jump bar**, **lightbox** (CONTEXT.md)
- Spike commit path: `pages#showcase_test` → `landing#show`