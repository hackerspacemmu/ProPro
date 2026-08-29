# ProPro Design Refactor — Overall Plan & Index

Umbrella doc for the ProPro UI redesign. The design work was intentionally
split into tracks, each with its own detail plan in `docs/`. This file indexes
those tracks and hosts the tickets that span or follow them (responsiveness
hardening, cross-cutting fixes). Glossary of terms lives in `CONTEXT.md`;
individual decisions live in `docs/adr/`.

## Tracks

| Track | Detail plan | ADRs | Status |
|---|---|---|---|
| Proposal forms (edit/new) | `projects_forms_refactor_plan.md` | `0001`–`0006` | ✅ done |
| `projects/show` redesign + app sidebar | `projects_show_refactor_plan.md` | `0007`–`0008` | ✅ done |
| Responsiveness hardening | this doc, Ticket 10 | — | ✅ done |
| `topics/show` migration | (follow-up) | — | 🔲 deferred |

## Completed inventory

### Forms track (`projects_forms_refactor_plan.md`)
- In-form method pickers (lecturer/topic modal), overwrite-on-method-switch,
  EasyMDE restyle, policy-authoritative gating, full-screen takeover layout,
  course-config gating. All 7 system tests green.

### Show page track (`projects_show_refactor_plan.md`)
- Tickets 1–9: tab shell (`tabs_controller`), Compare Versions extraction,
  header decomposition, comments restyle, progress-updates timeline + record
  modal, two-pane shell wiring, `_project_fields`/`_comments_panel` deletions,
  **comments drawer + pinned review action bar (ADR-0007)**, **app sidebar
  drawer (ADR-0008)**.
- Tests: `test/system/projects/project_show_responsive_test.rb` (4 structural
  tests / 12 assertions, `rack_test`). Pre-existing broken tests documented in
  the show plan (see "Backlog" below).

## Browsers & drivers

| Concern | Value |
|---|---|
| Default system-test driver | `rack_test` (`test/application_system_test_case.rb`) — no JS, no viewport, structural asserts only |
| Real-viewport driver | Selenium headless Chrome (already a Gemfile dep) — used by `mobile_overflow_test.rb` |
| Local prerequisite | Chrome/Chromium must be installed (`which` should find it). chromedriver resolves itself via Selenium Manager |
| CI | `browser-actions/setup-chrome@v1` step before `bin/rails test:system` (`.github/workflows/ci.yml`) |

---

## Ticket 10 — 360×760 horizontal overflow on `projects/show`

**Delivered.** Fixes the "whole page scrolls sideways" regression that shipped
with the Ticket 9 drawer/action-bar work on the redesigned show page (found in
a 360×760 emulation screenshot, not by CI).

### Root cause

`app/views/projects/_project_header.html.erb` — the sticky tab row:

```
<div class="flex items-center justify-between gap-8">
  <div class="flex gap-8">
    ... three whitespace-nowrap tab buttons ...
  </div>
  <!-- Ticket 9 addition -->
  <button data-comments-drawer-target="trigger" class="min-[1245px]:hidden ...">
```

Three `whitespace-nowrap` labels in an unconstrained `justify-between` row,
plus the comments trigger bolted on as a 4th flex item. No `flex-wrap`, no
`overflow-x-auto`, no shrink/truncation anywhere. At 360px (minus `px-8`
container padding, ~296px usable) the row just doesn't fit — "Progress
Updates" was already clipping to "Progress" before Ticket 9.

The row sits in the left pane (`show.html.erb:24`:
`flex-1 flex flex-col overflow-y-auto ...`). Setting only `overflow-y-auto`
makes `overflow-x` compute to `auto` too (spec behavior when one axis is
`auto` and the other stays `visible`). At mobile widths the sidebar is
off-canvas and the comments panel/action bar are `position: fixed`, so the
left pane *is* the visible screen — its internal horizontal scroll reads
exactly as "the page scrolls sideways," with the chat-bubble trigger pushed
off the right edge.

### Ruled out (not the cause)

- Sidebar drawer (`_sidebar.html.erb`) — correctly `-translate-x-full` gated.
- Breadcrumb — `flex flex-wrap` + `break-all` on the last crumb.
- Comments drawer panel (`show.html.erb`) — `fixed right-0 w-[360px] max-w-[90vw] translate-x-full`, flush off-screen when closed.
- The corner resize grip in screenshots is Chrome DevTools' device-toolbar handle, not app chrome.

### Why it shipped

`project_show_responsive_test.rb` (Ticket 8/9 era) only asserts **presence**
(`assert_selector 'button[data-comments-drawer-target="trigger"]'` ...). It
never resizes the driver window and never checks `scrollWidth` vs
`clientWidth`, so "4/12 ✓" proved the drawers are wired but nothing in CI
could catch a 360px overflow.

### Fix

1. **`app/views/projects/_project_header.html.erb`** — scope the scroll to the
   tabs and keep the trigger pinned outside it:

   ```
   <div class="flex items-center gap-3">                      (was justify-between gap-8)
     <div data-testid="content-tabs"
          class="flex flex-1 min-w-0 gap-6 overflow-x-auto [scrollbar-width:none]
                 [&::-webkit-scrollbar]:hidden [-webkit-overflow-scrolling:touch]">
       ... tab buttons (unchanged, whitespace-nowrap) ...
     </div>
     <button data-comments-drawer-target="trigger"
             class="min-[1245px]:hidden shrink-0 relative w-9 h-9 ...">
   ```

   - `flex-1 min-w-0` (not `shrink-0`) lets the wrapper shrink below its
     content width, which is what converts the overflow into an **internal**
     tab scroll; `shrink-0` on the wrapper would have kept the row at content
     width and still overflowed the pane.
   - `shrink-0` only on the trigger (keeps the 36px icon on-screen).
   - Scrollbar hidden for a clean look; scrollbar never renders at deskop
     widths because tabs fit and nothing overflows.
   - Sticky bar keeps `px-8 pt-6` (aligned with the `p-8` content column).

2. **`app/views/projects/show.html.erb`** — belt-and-braces: left pane
   `overflow-y-auto` → `overflow-y-auto overflow-x-hidden`, so no future
   child can ever make the pane (and therefore "the page") scroll sideways.

### Regression guard

New `test/system/projects/mobile_overflow_test.rb` — Selenium headless Chrome,
windowed `screen_size: [360, 760]`:

1. No page-level horizontal overflow: `document.documentElement.scrollWidth <= clientWidth`.
2. Tabs really scroll internally at 360px: `[data-testid="content-tabs"]` has `scrollWidth > clientWidth` (proves the mechanism is live, not dead).
3. The comments trigger stays on-screen: `getBoundingClientRect().right <= clientWidth`.

Setup uses `use_progress_updates: true` + `number_of_updates: 10` so all three
tabs render (2 tabs would fit at 360px and the scroll assert would go stale).

### CI

`.github/workflows/ci.yml` — `browser-actions/setup-chrome@v1`
(`chrome-version: stable`, `install-chromedriver: true`) ahead of the existing
`bin/rails test:system` step.

### Verification status

- `app/views/...` linted clean (`@herb-tools/linter`, 0 offenses).
- `bin/rails test` — 95 runs / 204 assertions / 0 failures.
- `test/system/projects/project_show_responsive_test.rb` — 4 / 12 still green.
- `mobile_overflow_test.rb` — **green**: 2 runs / 6 assertions (Selenium
  headless Chrome, 360×760). Requires Chrome/Chromium locally (CI gets it via
  the action); chromedriver resolves itself via Selenium Manager.

### Selenium test gotchas (learned here, worth re-reading before the next real-browser test)

1. **`use_transactional_tests = false`**: with a real browser the app runs on a
   server thread whose DB connection cannot see rows still uncommitted in the
   test's transaction, so FactoryBot users are invisible to `login_as`. This
   class opts out of transactions and cleans up its own records.
2. **Teardown must bypass callbacks**: the course factory's project template
   has an `is_project_title` field whose `before_destroy` throws — destroying
   a course graph via `dependent: :destroy` raises `RecordNotDestroyed`. The
   teardown `delete_all`s in FK order instead.
3. **Turbo races `click_button`**: `login_as` returns while Turbo's fetch
   navigation is still in flight; Chrome cold-start can blow the 2s implicit
   wait. The class overrides `login_as` to `assert_current_path root_path`
   (post-login landing) before proceeding.
4. **`evaluate_script` rejects top-level `const`** (chromedriver parse quirk) —
   wrap measurement payloads in an IIFE.
5. **`factory :enrolment` auto-creates a user** (`association :user`, so any
   `create(:enrolment, :lecturer, course:)` without an explicit `user:` mints
   an untracked user). Capture it via `create(...).user` and delete it in the
   teardown — the original teardown leaked 4 users per run this way.
6. **Tests in one class share one browser session** — `window.resize_to` from
   one test leaks into the next. Reset the viewport in `setup`
   (`page.driver.browser.manage.window.resize_to(360, 760)`) or metrics/
   visibility expectations silently break (a wide leftover hides `.hidden`
   desktop-only triggers like the comments trigger).
7. **Linux Chrome reserves a ~15px scrollbar** — `innerWidth` ≠ layout
   `clientWidth` once the page scrolls vertically, and `scrollWidth` can
   flicker during the first frames after load (fonts/layout settling). The
   overflow test polls until two consecutive `scrollWidth`/`clientWidth`
   reads agree before asserting.
8. **`assert_selector .hidden` needs `visible: :all`** — a node matching the
   `.hidden` class is `display:none`, so Capybara's default visibility filter
   reports "matched but not all filters". Widen the filter for hidden-class
   assertions.
9. **Close the drawer with Escape in tests** — when open, the drawer overlaps
   the comments trigger (both right-aligned), so a second
   `find(trigger).click` is click-intercepted by the drawer's own content.
   `show.html.erb` already wires `keydown.esc@window` →
   `comments-drawer#closeOnEscape`.

### Ticket 11 — post-response work: mobile bar, drawer edge, tab fade, header overflow

Follow-up round from inspecting real markup + real-browser runs at 360px.

- **Mobile review bar spacing.** `_review_action_bar.html.erb` was a plain
  block `div`; `render` inlines `_review_actions`'s two blocks flush. Desktop
  gets the rhythm for free from `_project_review_card`'s `flex flex-col
  gap-5`. Fix: `flex flex-col gap-3` on the mobile wrapper. Pixel-verified:
  the white run between the version select and the green Approve button grew
  23→35px (exactly +12 = `gap-3`).
- **Closed-drawer edge smear ("hairline").** The drawer's `shadow-2xl` (and
  its `border-l`) were unconditional, so they painted into the viewport while
  closed (`translate-x-full` sits its left edge at the viewport right edge,
  and `overflow-hidden` on `<main>` does not clip `position: fixed`
  descendants — no transform/filter/contain ancestor). Fix:
  `comments_drawer_controller` toggles `shadow-2xl` and `border-l`/border
  color in `open()`/`close()`; static panel classes carry neither. The
  desktop (`min-[1245px]`) overrides stay as belt-and-braces. Pixel-verified
  with a decoder script: right-edge columns (x 320–340) went from a
  white→238-gray gradient to pure 255.
- **Tab fade mask.** Ticket 10 hid the scrollbar, killing the "more content
  this way" affordance. New `tab_fade_controller.js` (auto-registered via
  `index.js`) toggles a trailing white-to-transparent gradient mask only when
  `scrollWidth > clientWidth`, clears it when scrolled to the end, and
  re-evaluates on window resize. `.hidden` by default; wired on the
  `relative flex-1 min-w-0` wrapper around `data-testid="content-tabs"`.
- **Header root cause found.** The "360 overflow" persisted beyond the tabs:
  `shared/_header.html.erb`'s `justify-between` row, with a breadcrumb group
  lacking `min-w-0` (so it couldn't shrink) and a default-shrink `Log out`
  button, overflowed the 345px layout viewport by 5–34px (jittery across
  loads). Fix: `min-w-0` on the left group, `shrink-0` on the menu, wordmark,
  and the `button_to` form. This also made the Ticket 10 overflow test
  deterministic (its single read was flaky — `scrollWidth` 345 vs 350 vs 353
  across runs).

### Notes on discovering an edge case

The mobile test's first attempt surfaced a course factory validation:
`use_progress_updates: true` without `number_of_updates` fails
(`Course` validates positive-whole updates count when enabled). Fixed in the
test setup — not a production bug.

---

## Backlog

- **`topics/show`** — keeps its old `mobile-tabs` + comments-column layout,
  with the same class of sub-`min-[1245px]` overflow. Migrate to the
  comments-drawer idiom (ADR-0007) and the sidebar contract (ADR-0008) in a
  follow-up.
- **Known pre-existing broken system tests** — `project_versioning_test.rb`
  (3) + `change_status_test.rb` happy-path reference removed testids
  (`version-back`/`version-next`/`current-version`/`status-select`/
  `change-status-submit`). Documented in `projects_show_refactor_plan.md`.
- **Compare toolbar** — mockup's two-`<select>` arbitrary version-pair
  comparator, deferred (flag in `_compare_versions_tab.html.erb`).
- **Housekeeping (unrelated to design)** — 22 herb offenses across
  `app/views/**` (`courses/*`, `project_groups/*`, `lecturers/show`,
  `topics/_topic_actions`) surfaced during the design lint sweep; 17
  `--fix`-autocorrectable. Decision pending.

## How to verify

```sh
bin/rails test                                                        # 95 runs, no system tests
bin/rails test test/system/projects/project_show_responsive_test.rb   # rack_test structural
bin/rails test test/system/projects/mobile_overflow_test.rb           # needs Chrome/Chromium installed
npx @herb-tools/linter app/views/projects/_project_header.html.erb app/views/projects/show.html.erb
```