# courses/show — Tab & Header Navigation Plan

Suggested repo path: `docs/courses_show_tabs_plan.md`

**Replaces the tab-bar sections of `courses_show_refactor_plan.md`** for
implementation purposes. Kept short on purpose — no alternatives-considered
essay — so it fits easily in context.
okat
**Status:** mostly decided. Two open questions below block implementation.

---

## Confirmed: one IA at every breakpoint

Same tabs, same panels, regardless of screen width. No primary/overflow
"More" split is needed for the tab row — 4 tabs fit at any width. This makes
the earlier primary/overflow implementation work (§4.2 / "Ticket 1") for the
tab row unnecessary; don't build it if it hasn't started. (Breadcrumb
collapse can keep whatever breakpoint suits it on its own — it no longer
needs to be reconciled with a tab-overflow breakpoint, since tabs don't
overflow anymore.)  

---

## Tab structure

### Coordinator / Lecturer

| Tab | Contains |
|---|---|
| Overview | Project details, Supervised Projects (see Q1), Reviewed Proposals, Pending Topics |
| Topics | Topic Directory |
| People | Lecturers, Students |
| Groups | Own tab (see note below) |

### Student

| Tab | Contains |
|---|---|
| Overview | Project details, My Project (own section, not a separate tab) |
| Topics | Topic Directory |
| People | Lecturers, Students |
| Groups | *Assumed same as coordinator — see Q2* |

--- 

## Header icons (coordinator/lecturer only, same at every breakpoint)

| Icon | Notes |
|---|---|
| Settings | Coordinator only. Header, not the tab row, not a dropdown. |
| Project template | Coordinator only, out of scope for this ticket — reserve the header slot now so it isn't a layout change later. |

---

## Naming

"Project Details" tab renamed to "Overview" (unchanged from earlier draft).

---

# courses/show — Tab Bar Styling, Hover, Responsive & Tab Persistence Plan (agreed)

Supersedes the tab-bar sections of `courses_show_refactor_plan.md` for
implementation purposes. Decisions below were settled via a grilling session
(matching `ProPro_Design/course_show.html.erb` mockup + `style_guide.html.erb`)
against the current `app/views/courses/show.html.erb`.

**Status:** decided. One combined ticket — styling + hover + responsive +
`?tab=` persistence — because they all touch the same two files
(`show.html.erb`, `tabs_controller.js`).

**Revision:** the mockup's tab bar was updated (uncommitted diff to
`ProPro_Design/course_show.html.erb:79-98`) from the thin-underline style to
the **M3 filled-primary tab**: full-height `h-[3rem]` tiles, active = Primary
Blue `#0B57D0` text on a `#F0F4F9` container fill with a full-width 3px
indicator, inactive = on-surface `#1F1F1F` text with a `#F8F9FA` bg-wash hover.
The decisions and gap list below reflect the updated mockup.

**Revision 2:** the first implementation drew the 3px indicator as an always-on
`border-b-[3px]` — that lost the mockup's `rounded-t-[3px]`, so it was walked
back to the mockup's nested absolute indicator div (see D-1), lit by
`group-aria-selected`. `connect()` also grew a URL-first resolution so a Turbo
snapshot restore can't snap the active bar back to Overview against the URL.

---

## Ground truth

| Reference | Role |
|---|---|
| `ProPro_Design/course_show.html.erb` | the mockup — tab row at lines 79–98 |
| `ProPro_Design/style_guide.html.erb` | canonical tab reference (§Tabs, lines 255–265) |
| `app/views/projects/_project_header.html.erb` | existing tab-fade / hover precedent |
| `app/javascript/controllers/tabs_controller.js` | the generic tab controller |

The mockup is at `ProPro_Design/`, **not** `docs/`.

---

## Decisions (grilled & confirmed)

| # | Decision | Resolution |
|---|---|---|
| D-1 | Active-tab indicator | **M3 filled-primary tile**: `text-[#0B57D0] bg-[#F0F4F9]`, plus the mockup's own 3px indicator — an absolutely-positioned `div` inside the tile (`absolute bottom-0 left-0 w-full h-[3px] rounded-t-[3px]`), **not a border**. It lives in every tile and is lit by `group-aria-selected:bg-[#0B57D0]` on the tile's `group`, so the generic `tabs_controller` needs no inner-indicator target (it already maintains `aria-selected`). Restores the mockup's `rounded-t-[3px]`, which the earlier always-on-`border-b-[3px]` distillation lost. |
| D-2 | Hover on inactive tabs | **`hover:bg-[#F8F9FA]` bg-wash**; inactive text stays `#1F1F1F` (no text-color hover). Active tile never hovers (already filled). |
| D-3 | Where the state classes live | **`data-tabs-active-class` / `data-tabs-inactive-class` on `<main>`** — data-driven override in the view, keeping `tabs_controller` generic/reusable (its built-in defaults stay the old underline style for projects/show). |
| D-4 | Tab row | **`px-8` flush container**, tiles `h-[3rem] pt-[0.125rem] px-[1.5rem] flex items-center justify-center relative box-border whitespace-nowrap`; on wrap, **`gap-y-1`** for a breathing row (no `gap-x`). |
| D-5 | Scope | **One combined ticket** — styling + hover + responsive + persistence, not split. |
| D-6 | Controller refactor | **Fold the `setActive()` DRY refactor in** (single owner of "what does active mean"). |

---

## Target tab bar

`app/views/courses/show.html.erb`:

- `<main>` gains `data-tabs-active-index-value`, `data-tabs-active-class`,
  `data-tabs-inactive-class`, and the active index is computed server-side from
  `params[:tab]` (stable key, fallback to first key) so the server renders the
  correct initial tab — no JS flash on load.
- **Active-class string:** `text-[#0B57D0] bg-[#F0F4F9]`
- **Inactive-class string:** `text-[#1F1F1F] hover:bg-[#F8F9FA]`
- The `tabs` array entries get a stable `key` ("overview", "to_review",
  "topics", "people", "groups"), independent of DOM position.
- The tab row container: `border-b border-[#E0E0E0] px-8 bg-white shrink-0`;
  inner row `flex flex-wrap gap-y-1`.
- **ARIA split:** `role="tablist"` wraps only the real tab buttons. The
  Settings link stays visually in the row but **outside** the tablist (a
  tablist must contain only `role="tab"` items — the earlier draft put the link
  inside it, an ARIA violation). Settings renders as the **same inactive tile**
  (no border — it isn't a tab).
- Each tab: `role="tab"`, `aria-selected`, `aria-controls="panel-<key>"`,
  roving `tabindex` (0 active / -1 inactive), `data-tabs-index-param`,
  `data-tabs-key-param`, tile base class with `group` and an inner indicator
  `<div class="absolute bottom-0 left-0 w-full h-[3px] rounded-t-[3px]
  transition-colors bg-transparent group-aria-selected:bg-[#0B57D0]">`.
  No `border-b` anywhere on the tile — the indicator div IS the 3px bar.
- Panels: `role="tabpanel"`, `aria-labelledby="tab-<key>"`, `hidden` only on the
  non-active panel.

### vs current — gap list

| Gap | Mockup / target | Current |
|---|---|---|
| Tab look | full-height `h-[3rem]` tiles, active filled `#F0F4F9` + `#0B57D0` 3px indicator | underline strip under text, `#1A73E8`, no fill |
| Hover (inactive) | `hover:bg-[#F8F9FA]` wash | none |
| Row | `px-8` flush, no `gap-x`, `gap-y-1` on wrap | `px-8 pt-5`, `gap-x-8` |
| Inactive text | `#1F1F1F` | `#5F6368` / `#3C4043` on hover |
| Settings tile | inactive-tile look, no indicator | text link + underline |
| Active tab rendered server-side | yes, from `?tab=` | no (JS forces index 0) |

---

## Controller rewrite

`app/javascript/controllers/tabs_controller.js` — single `setActive(index)`
owns panel `hidden`, active/inactive classes, `aria-selected`, and roving
`tabindex`. Its **built-in defaults are unchanged** (the old underline style:
`text-[#1A73E8] border-[#1A73E8]` active, `text-[#5F6368] border-transparent`
inactive) because projects/show still mounts this controller without overrides;
courses/show supplies the M3 strings via `data-tabs-active-class` /
`data-tabs-inactive-class` on `<main>`.

- `connect()` prefers the URL's `?tab=` key (from `replaceState` clicks) over
  `activeIndexValue`, falling back to the baked value only when the URL has no
  `tab` param — so Turbo snapshot restores (where the baked index is stale) land
  on the same tab the URL advertises. Never writes the URL.
- `show(event)` → `setActive(Number(event.params.index))`, then
  `history.replaceState` writes `?tab=<key>` (not pushState — a tab switch
  isn't a back-button page). Reads `event.params.key`.
- A client-side test quirk surfaced here: headless Chrome intermittently drops
  synthetic *native* clicks sent right after load (~50%), while JS-dispatched
  clicks always work and real user clicks are unaffected. The persistence test
  drives the tab via `find_button(...).evaluate_script('this.click()')` for
  determinism.

Validation: `params[:tab]` is only `include?`-checked / used for keyed lookup,
never interpolated — nothing to sanitize.

---

## Responsiveness

- Row: `flex flex-wrap gap-y-1` + `whitespace-nowrap` tiles — wraps to a second
  row on narrow screens with a 4px breathing gap, no horizontal overflow.
  Consistent with the `course_tab_plan.md` "same tabs at every width" decision —
  no primary/overflow "More" split, no new breakpoint logic.
- Tiles carry no `gap-x` (the mockup spaces tiles only via their `px-[1.5rem]`).
- The `h-[3rem]` fixed height is constant per row; `gap-y-1` is the only added
  wrap affordance.

---

## Out of scope (decided)

- Mockup's sticky / `shrink-0` content-pane structure (`overflow-hidden flex-col`
  main with an independently-scrolling pane) — structural, beyond tab styling
  + hover.
- Setting relocation to a header icon — deferred per `course_tab_plan.md`.
- Arrow-key tab navigation — deferred; roving `tabindex` added without
  arrow-key handlers (note: affects AT verification).
- **Resolved, not out of scope:** the earlier "distil the indicator to an
  always-on `border-b-[3px]` (Option A)" decision was walked back — the mockup's
  nested absolute indicator div (with `rounded-t-[3px]`) is the implementation,
  lit via `group-aria-selected` so no controller target/`setActive` coupling was
  needed after all.

---

## Tests

- Existing `test/system/courses/course_tabs_test.rb` (9 tests) stays green —
  `click_button`, `assert_text`, `click_link 'Settings'` semantics unchanged.
- Add a persistence test: drive a tab, reload, same tab stays; and a direct
  `visit course_path(@course, tab: 'to_review')` lands on To Review.

---

## Grill-with-docs note

Per `grill-with-docs` the six decisions would normally land as a repo paper
trail (resolved terms → `CONTEXT.md`, gated decisions → an ADR under
`docs/adr/`), but its dependencies (`grilling`, `domain-modeling`) aren't
installed as skills in this repo. Decisions are therefore recorded in this
plan. If a paper trail is wanted when the implementation lands, capture it as
e.g. `docs/adr/0012-course-show-tab-bar-and-persistence.md`.

----