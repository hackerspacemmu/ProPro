# ProPro — Sidebar desktop collapse/expand (Google Classroom icon-rail pattern)

**Status:** Designed — ready to ticket. Supersedes `course_tab_plan.md` §9
(OQ-1..OQ-5) and its Ticket 7 placeholder. Do not build the sidebar-collapse
work from `course_tab_plan.md`; build from this doc.

**Provenance:** source design by Claude (referenced Google Classroom
screenshots). This document is the resolved, audited version: every
assumption in the source was checked against the actual working tree and
the previously-open questions were answered on 2026-09-06.

**Gating prerequisite:** the content-tab scroll-lock fix must be in place
before this lands (it already is — see §3 audit), because this feature
changes the sidebar's width and the scroll-lock is what makes `<main>`
reliably reflow against that width change instead of falling back to
document scroll.

---

## 1. Confirmed decisions (from design review, 2026-09-06)

| # | Question | Answer |
|---|---|---|
| D-1 | Toggle at desktop | **Unhide the existing hamburger at `lg`** (remove `lg:hidden`). The same button toggles the off-canvas drawer below `lg` and the rail-collapse at `lg+`. Classroom-style — menu icon sits left of the ProPro wordmark, in the shared header. |
| D-2 | Legacy `render_sidebar` pages (`courses/profile`, `lecturers/show`) | **Migrate, then delete the legacy sidebar.** Reversed during review: migrate both pages to `render "shared/sidebar"` (via `content_for :sidebar`), then delete `render_sidebar`, `ApplicationHelper#sidebar_link`, `scroll_spy_controller.js`, and the legacy `sidebar_helper.rb`. All five sidebar pages render `shared/_sidebar`. |
| D-3 | Paper trail vs ADR 0008 ("no desktop collapsible rail") | **New ADR-0009 amending that clause** must land alongside implementation (see §9). Do not land the feature as a quiet diff against a controller whose commit history says the opposite was a deliberate choice. |
| D-4 | Automated test coverage | **Include a selenium system test** following the existing `mobile_overflow_test.rb` pattern (resize viewport, toggle, assert cookie + widths + a11y). See §10. |
| D-5 | Document placement | **This standalone document.** `course_tab_plan.md` §9/Ticket 7 updated to point here instead of holding a placeholder. |

---

## 2. Open questions from `course_tab_plan.md` §9 — now answered

| OQ | Question | Answer (this doc) |
|---|---|---|
| OQ-1 | Same `sidebar_controller.js` or a separate controller? | **Same controller**, extended with a breakpoint-aware `toggle()` (see §5). The desktop collapse has no backdrop, no scroll-lock, and must survive navigation — so it must be a *branch* inside the existing controller, not an overlay like mobile. `matchMedia("(min-width: 1024px)")` selects the branch. ADR-0008's complaint was width-class juggling that never matched markup — this design removes that anti-pattern (state in one attribute, visuals in CSS variants), so the "two controllers" option's complexity saving is not worth a second controller sharing one `<aside>`. |
| OQ-2 | Collapsed visual model | **Icon-only rail, `w-[72px]`, Classroom's exact shape:** labels hidden, the entire Enrolled group gone (not icon-ified), hover tooltip on the remaining icons, centered active highlight, no third mid-width state at `lg`. Only two states: expanded `280px`, collapsed `72px`. |
| OQ-3 | Persistence | **Plain cookie** `propro_sidebar_rail_collapsed`, read server-side at render via a helper so returning users never flash the wrong width. Exactly mirrors the `tabs_controller.js` → `current_tab_index` convention (plain unsigned cookie jar, allowlisted/boolean read). **Not** `localStorage` — that's what ADR-0008 tore out, and the cookie is the codebase's established persistence pattern. |
| OQ-4 | Breakpoint(s) | **Single breakpoint, `lg` (1024px), Tailwind default** — both for markup `lg:` variants and the controller's `matchMedia`. Chrome breakpoint stays independent of content breakpoints (`min-[1245px]` comments drawer) per ADR-0008; the collapsed rail does not add a third state between the two. |
| OQ-5 | Paper trail | **ADR-0009** (see §9). |

---

## 3. Current-state audit — ground truth this design is built on

### `shared/_sidebar.html.erb` (the aside, today)

```erb
<aside id="app-sidebar"
       class="
         w-[280px] shrink-0 py-3 bg-surface-tint
         fixed top-0 left-0 h-full z-50 -translate-x-full transition-transform
         duration-300 ease-out
         lg:sticky lg:top-header lg:translate-x-0 lg:transition-none lg:h-[calc(100vh-var(--spacing-header))] lg:overflow-y-auto lg:self-start
       "
       data-sidebar-target="container">
  <nav class="flex flex-col gap-1 pr-3">
    ... Home link / Enrolled header + course loop / divider / Edit profile / Log out ...
  </nav>
</aside>
<div class="hidden fixed inset-0 bg-black/30 z-40 lg:hidden"
     data-sidebar-target="backdrop"
     data-action="click->sidebar#close"></div>
```

Nav items (all share `flex items-center gap-4 px-6 py-3.5 rounded-r-full`,
inline `font-family: 'DM Sans', Roboto ... .875rem/500` style, `gap-4`
between icon span and label span):

- **Home** — plain `link_to`, icon `home`.
- **Enrolled header** — `px-6 py-2` `div`, `expand_less` icon.
- **Course loop** — `current_user.courses.distinct.each`; `link_to
  course_path(course)`; active item uses `mx-3 px-4 py-3.5 rounded-full`
  (not `rounded-r-full`); each row has a `w-9 h-9 rounded-full` initial
  avatar, label `<span class="truncate"><%= course.course_name %></span>`.
- **Divider** — `<div class="py-2"><div class="border-t border-outline"></div></div>`.
- **Edit profile** — plain `link_to`, icon `person`.
- **Log out** — **already a working `button_to` to `session_path`,
  method: :delete** (line 57). The "v3 Ticket 2 fix" (dead `<span>`) has
  already shipped — **no longer part of this work**.

### `sidebar_controller.js` (WIP, current working tree — 66 lines)

- Targets: `container`, `backdrop`, `toggleButton`. Controller is scoped on
  `<body>` (`layouts/application.html.erb` L27), so it resolves on every
  sidebar render path.
- `connect()`: `close()` right away, binds `Escape` keydown + `turbo:before-visit`.
- `toggle()`/`open()`/`close()`/`isOpen()`: **class-list toggling** of
  `-translate-x-full`, `hidden` on backdrop, `overflow-hidden` body
  scroll-lock, `aria-expanded` (`setExpanded`).
- **No** `localStorage`, no `matchMedia`, no resize listener, no cookies,
  no width juggling — this is exactly the post-ADR-0008 minimal controller.
- The legacy `localStorage.getItem("sidebar-collapsed")` key does **not**
  exist anywhere in the current working tree (checked). Nothing to collide with.

### Cookie persistence precedent to mirror (`tabs_controller.js`)

```js
persist(slug) {
  if (!slug || !this.hasPersistKeyValue) return;
  const secure = window.location.protocol === "https:" ? "; secure" : "";
  document.cookie = `${this.persistKeyValue}=${slug}; path=/; max-age=31536000; samesite=lax${secure}`;
}
```

Server read (`application_helper.rb` L9-11):

```ruby
def current_tab_index(persist_key:, slugs:)
  slugs.index(cookies[persist_key]) || 0
end
```

Plain (unsigned) cookie jar, deliberate — the value is written client-side
via `document.cookie` and can never be signed. The sidebar mirror reads the
same way.

### Scroll-lock status (the gating prerequisite)

| Page | Scroll-lock | Verdict |
|---|---|---|
| `courses/show` | `<main class="flex-1 ... overflow-y-auto h-[calc(100vh-var(--spacing-header))]">`, tab bar `sticky top-0 z-10` | **In place.** |
| `projects/show` | inner `overflow-y-auto` left pane, sticky tab row | In place (pre-existing). |
| `topics/show` | same as projects | In place (pre-existing). |

Pages render `<div class="flex"><%= render "shared/sidebar" %><main class="flex-1 ...">` — so `<main>` gets its new width for free from `flex-1`; no content-side layout change needed for the collapse. The width transition is a regression-sensitive zone for the just-stabilized `overflow-y-auto` panes (see §8).

### Tailwind

- `tailwindcss-rails ~> 4.3`, **Tailwind v4**, CSS-first `@theme` config, no
  `tailwind.config.js`. `group/data-*` arbitrary named-group variants
  (`group/sidebar`, `group-data-[collapsed=true]/sidebar:lg:*`) are
  supported in v4 — **smoke-test one instance in the real build before
  trusting it wholesale** (grep the emitted CSS for the compiled selector).

---

## 4. State model — one attribute, CSS variants, no JS class-list surgery

**Anti-pattern being explicitly avoided** (the root cause of the dead code
ADR-0008 removed): a width value living in a JS file that must be kept in
sync by hand with the markup's class list. The old `main`-branch controller
hardcoded `w-64` as "expanded" while the real markup used `w-[280px]` —
they already disagreed. Here:

- The single state bit is `data-collapsed="true|false"` on `<aside>`.
- Every visual difference is a Tailwind CSS variant
  `group-data-[collapsed=true]/sidebar:lg:*` on descendants — the width
  value `w-[72px]` exists in exactly one place (the ERB class list) and is
  referenced, never duplicated, by the variant.
- Every collapsed-specific class is gated at `lg:`, so the cookie value can
  never leak into mobile's off-canvas drawer behavior and vice versa. Mobile
  is untouched byte-for-byte.

```erb
<aside id="app-sidebar"
       class="group/sidebar
         w-[280px] shrink-0 py-3 bg-surface-tint
         fixed top-0 left-0 h-full z-50 -translate-x-full transition-[transform,width] duration-200 ease-out
         lg:sticky lg:top-header lg:translate-x-0 lg:h-[calc(100vh-var(--spacing-header))] lg:self-start lg:overflow-y-auto
         data-[collapsed=true]:lg:overflow-visible
         data-[collapsed=true]:lg:w-[72px]"
       data-sidebar-target="container"
       data-collapsed="<%= sidebar_collapsed? %>">
```

Changes versus today, annotated:

- `group/sidebar` — the named group the collapsed variants hang off.
- `data-collapsed="<%= sidebar_collapsed? %>"` — server-rendered initial
  state (no flash-of-wrong-state for returning users; see §6).
- `transition-[transform,width] duration-200 ease-out` — replaces
  `transition-transform duration-300 ease-out` + `lg:transition-none`. One
  transition covering the existing mobile transform *and* the new desktop
  width change.
- The aside's OWN responsive width/overflow use **self data variants**
  (`data-[collapsed=true]:lg:w-[72px]`, `data-[collapsed=true]:lg:overflow-visible`),
  not `group-data-[collapsed=true]/sidebar:lg:*`. The named-group variant
  emits `:is(:where(.group\/sidebar)[data-collapsed=true] *)` — it matches
  **descendants** of the collapsed group, so it can never restyle the
  `<aside>` itself. Width and overflow live on the aside; every other
  collapsed visual (labels, Enrolled group, centered caps, tooltips) is a
  descendant and uses the group variant. (Found by the system test: the
  rail stayed 280px collapsed.)
- `lg:overflow-y-auto` stays on the `<aside>`; collapsed mode flips it to
  `overflow: visible` via the self variant **plus** an unlayered
  `#app-sidebar[data-collapsed="true"] { overflow: visible }` fallback in
  `application.css` (unlayered, so it beats the layered utility), so
  tooltips escape the 72px rail. See §13 deviation 2.

Known, intentional side effects:
- Mobile drawer animation duration changes `300ms → 200ms` (same ease-out).
  Cosmetic; accepted.
- `lg:transition-none` removal means `transform`/`width` transitions are
  now active at `lg`, which is the point. Nothing else on the aside animates.

---

## 5. Controller — `sidebar_controller.js`

Extend the existing controller. The mobile paths (`open`/`close`/
`isOpen`/Escape/`turbo:before-visit`) stay exactly as they are; the desktop
fullness is a new breakpoint-aware branch, not a rewrite.

```js
static DESKTOP_QUERY = "(min-width: 1024px)";

toggle() {
  if (window.matchMedia(this.constructor.DESKTOP_QUERY).matches) {
    this.setCollapsed(!this.isCollapsed());
  } else if (this.isOpen()) {
    this.close();
  } else {
    this.open();
  }
}

isCollapsed() {
  return this.containerTarget.dataset.collapsed === "true";
}

setCollapsed(value) {
  this.containerTarget.dataset.collapsed = String(value);
  // Same write the tabs controller uses — verbatim, do not simplify.
  const secure = window.location.protocol === "https:" ? "; secure" : "";
  document.cookie = `propro_sidebar_rail_collapsed=${value}; path=/; max-age=31536000; samesite=lax${secure}`;
  this.syncExpanded();
}
```

`turbo:before-visit` and Escape **do not touch** `setCollapsed` — a
collapsed rail is a persistent preference and must survive navigation.
(`close()` running on `before-visit` at desktop is a visual no-op — it adds
`-translate-x-full`, which `lg:translate-x-0` overrides — but it currently
also forces `aria-expanded=false` at any width. Fix that next.)

**`aria-expanded` must reflect the relevant state at the current
breakpoint.** Replace `setExpanded` (which is only ever the mobile-open
state) with a breakpoint-aware sync, and call it after every state change
(open, close, setCollapsed, connect):

```js
syncExpanded() {
  if (!this.hasToggleButtonTarget) return;
  const isDesktop = window.matchMedia(this.constructor.DESKTOP_QUERY).matches;
  const relevantOpen = isDesktop ? !this.isCollapsed() : this.isOpen();
  this.toggleButtonTarget.setAttribute("aria-expanded", String(relevantOpen));
}
```

The header toggle button (`_header.html.erb` L4-12) currently hardcodes
`aria-expanded="false"` and is `lg:hidden`. Changes:

```diff
-        aria-expanded="false"
         aria-controls="app-sidebar"
-        class="lg:hidden shrink-0 p-2 rounded-full hover:bg-[#EEF0F4] text-on-surface-variant transition-colors">
+        class="shrink-0 h-10 w-10 flex items-center justify-center rounded-full hover:bg-[#EEF0F4] text-on-surface-variant transition-colors">
```

(`aria-expanded` is now owned by the controller via `syncExpanded`; leave
the hardcoded attribute out so the controller is authoritative. The button
remains suppressed on takeover pages via the existing `hide_toggler`
guard — every `no_sidebar` page also sets it, so unhiding at `lg` can't
surface a do-nothing button. The pinned `h-10 w-10 flex items-center
justify-center` box — replacing `p-2` — plus a parallel header `py-3 → py-2`
keep the header exactly 56px at every width: without it the icon glyph lays
the button out at ~47px and `min-h-header` lets the header grow to 71px,
breaking the `--spacing-header` arithmetic everything else assumes. §8 +
§13 deviation 11.)

---

## 6. Persistence — helper + cookie

`application_helper.rb`, next to `current_tab_index`:

```ruby
# Plain/unsigned cookie read for the sidebar rail-collapse preference,
# mirroring current_tab_index. Not signed because the value is written
# client-side by sidebar_controller.js (tabs_controller.js convention).
# Absent or anything but "true" means expanded.
def sidebar_collapsed?
  cookies[:propro_sidebar_rail_collapsed] == "true"
end
```

Cookie: `propro_sidebar_rail_collapsed=true|false`, `path=/`,
`max-age=31536000`, `samesite=lax`, `secure` when HTTPS — **verbatim the
`tabs_controller.js` convention.** Read server-side at render (§4) so the
right width appears on first paint. No `localStorage` anywhere.

---

## 7. Markup — `shared/_sidebar.html.erb`

### 7.1 Extract the nav-item helper (Phase 6, do as part of this change)

The nav-item recipe (icon + label + conditional active classes + repeated
inline font style) currently exists 5× (Home, course loop, Edit profile,
Log out) — plus a second, different active shape for courses. This feature
adds a third dimension (collapsed × active × item-kind), which turns 5
hand-synced copy-pastes into 5 places each needing a label-hide variant,
a tooltip span, and an `aria-label`. **Extract now, not as a follow-up.**

```erb
<%# shared/_sidebar_nav_item   %>
<%# kinds: :plain (icon link), :course (avatar link), :logout (button)  %>
<%= render "shared/sidebar_nav_item", kind: :home,     path: root_path,            label: "Home",         active: home_active %>
<%= render "shared/sidebar_nav_item", kind: :logout,                                                                        %>
<%# course loop: %>
<%= render "shared/sidebar_nav_item", kind: :course, path: course_path(course), label: course.course_name, active: (course == @course), avatar: course.course_name.first.upcase %>
```

The partial owns, exactly once per kind: the icon/avatar span, the
label span with its collapsed hide variant, the `aria-label`, the tooltip
span, and the active shape for **both** states. Every future nav item — and
any fix to collapse/active rendering — then happens in exactly one place.

### 7.2 Per-item markup (what the partial renders)

```erb
<%= link_to path, aria: { label: label },
      class: [
        "group/item relative flex items-center gap-4 px-6 py-3.5 transition-colors",
        # expanded state:
        active ? "rounded-r-full bg-primary-container-alt text-primary-strong font-semibold"
               : "rounded-r-full text-on-surface hover:bg-white/60",
        # collapsed (lg + data-collapsed=true) overrides:
        "group-data-[collapsed=true]/sidebar:lg:justify-center",
        "group-data-[collapsed=true]/sidebar:lg:px-0",
        active ? "group-data-[collapsed=true]/sidebar:lg:rounded-lg" : "",   # see 7.4
      ],
      style: "font-family: 'DM Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500; letter-spacing: 0; line-height: 1.25rem;" do %>
  <span class="material-symbols-outlined <%= ... %>"><%= icon %></span>
  <span class="group-data-[collapsed=true]/sidebar:lg:hidden"><%= label %></span>

  <%# Tooltip — hidden except collapsed+lg on hover. Never shown beside a visible label. %>
  <span class="hidden group-data-[collapsed=true]/sidebar:lg:group-hover/item:block absolute z-50 left-full top-1/2 -translate-y-1/2 ml-3 whitespace-nowrap rounded bg-black px-2 py-1 text-xs text-white shadow-lg pointer-events-none">
    <%= label %>
  </span>
<% end %>
```

Course rows differ only in their leading avatar (`w-9 h-9 rounded-full`
initial, replacing the material icon) and the expanded-active shape
(`mx-3 rounded-full` instead of `rounded-r-full`); both live inside the
partial's `:course` branch.

### 7.3 The whole Enrolled group disappears when collapsed

Not "icon-only Enrolled section" — gone, per the screenshots. Wrap the
header row, the course loop, and the divider in one container and hide the
container:

```erb
<div class="group-data-[collapsed=true]/sidebar:lg:hidden">
  <%# Enrolled header + course loop + divider %>
</div>
```

### 7.4 Collapsed-specific active shape (Phase 4)

The expanded active shapes are `rounded-r-full` (bleed to the right edge of
a 280px rail) and `mx-3 rounded-full` (courses) — both wrong on a 72px
rail (clipped or off-center). Collapsed gives **every kind one centered,
same-sized highlight** sized to the icon, not the row:

`group-data-[collapsed=true]/sidebar:lg:justify-center
 group-data-[collapsed=true]/sidebar:lg:px-0` on the row, with the active
background re-tinted as a centered icon-only pill. **Implemented as the
first option: a `h-9 w-9 rounded-full` circle centered on the icon**
(confirms the screenshot; the `rounded-lg` pill was not used). Active keeps
the expanded palette; see `_sidebar_nav_item.html.erb`.

### 7.5 Nav scroll container

Keep `lg:overflow-y-auto` on `<aside>` (as today), and let collapsed mode
flip the aside's overflow to `visible` (self data variant + unlayered
fallback; see §4). Rationale being reconsidered vs the source plan: an
`overflow-y-auto` aside computes `overflow-x` to `auto`, which would clip
the absolutely-positioned collapsed tooltips at the rail's right edge — so
the *expanded* state keeps its `lg:overflow-y-auto`, while the *collapsed*
state is `overflow: visible` (collapsed structurally can't grow: the
Enrolled group is hidden, so the rail never needs to scroll). Tooltips
escape over content exactly when they exist. Implemented with the aside
variant changes documented in §4, not the `<nav>` move the source proposed.

### 7.6 Accessibility (Phase 5)

- Every nav item (`link_to`/`button_to`/course row) carries an `aria-label`
  that does not depend on the visible label span: `Home`,
  `course.course_name`, `Edit profile`, `Log out`. A `display:none` span
  yields no name to a screen reader, and the hover tooltip is mouse-only.
- Avatar/icon spans are `aria-hidden="true"` inside the labelled item.
- The toggle button's `aria-expanded` is controller-owned (§5), reflecting
  drawer-open below `lg`, rail-expanded at `lg+`.

---

## 8. Regression risks (scoped to the just-stabilized scroll-lock area)

- **`<main>` reflow:** pages already wrap sidebar + main in a flex row with
  `flex-1` main, so the width transition needs no content-side change — but
  manually confirm the animation introduces no horizontal-scrollbar flash
  and doesn't visibly jump the `overflow-y-auto` panes' scrollbar position
  mid-transition (`courses/show` main, `projects/show` + `topics/show`
  left panes). This is the exact area the scroll-lock work just stabilized.
- **Mobile off-canvas:** byte-for-byte unaffected. All collapsed variants
  are `lg:`-gated; `data-collapsed` exists independently of mobile open/
  closed state; body scroll-lock, backdrop, escape, and
  `turbo:before-visit` reset are untouched.
- **Existing edge, not introduced here:** opening the mobile drawer then
  resizing to `lg` strands `overflow-hidden` on `<body>`. Pre-dates this
  feature; note it but do not fix it in this diff.
- **Header height (found by `tabs_sticky_test`, fixed here):** the icon
  button's glyph lays out at ~47px, so an unconstrained `min-h-header`
  header grows 56px → 71px on desktop the moment the hamburger becomes
  visible at `lg` — moving the sticky tab bar down 15px and making the
  window scrollable (everything assumes `--spacing-header`: `top-header`,
  `calc(100vh - header)`). Fixed by pinning the toggle to a 40px box
  (`h-10 w-10 flex items-center justify-center`, replacing `p-2`, which
  neutralizes the glyph line-height) and tightening the header
  `py-3 → py-2` so 40 + 16 = 56 exactly stays put. Visually identical:
  the `min-height` + `items-center` keep content centered at 56. The same
  hidden growth existed on mobile pre-change (hamburger was always there);
  this resolves it at all widths. Guarded by the `tabs_sticky` suite.

---

## 9. Paper trail — ADR-0009

ADR-0008 (Accepted, 2026-08-29) contains a clause this feature contradicts
by design: *"no resize listener, no width-class juggling, no localStorage,
no desktop collapsible rail."* Reopening desktop collapse requires a
written decision before/while the code lands.

`docs/adr/0009-app-sidebar-desktop-collapse.md` — Status Accepted, dated
with implementation. Content, minimally:

- **Amends** ADR-0008's no-rail clause. `localStorage` stays banned — the
  decision is specifically *not* "bring back the 2026-08-29 feature," it is
  "a desktop rail-collapse whose state is a `data-collapsed` attribute
  driven by CSS variants and persisted in a plain cookie (the
  `tabs_controller` convention), with the mobile drawer untouched."
- Records that the prior dead code was width values living in JS that
  never matched markup; this ADR's mechanism (single attribute, CSS-variant
  visuals) is the structural fix, not a reversion.
- Records the deliberately preserved independence of the `lg` chrome
  breakpoint from content breakpoints (`min-[1245px]`).

---

## 10. Automated test — `test/system/sidebar_collapse_test.rb`

Follow the existing `test/system/projects/mobile_overflow_test.rb` pattern:
`driven_by :selenium, using: :headless_chrome`, real viewport,
`page.execute_script` / geometry reads.

Coverage, one test per scenario (or parametrized if the harness cooperates):

1. **Desktop rail: collapse, persist across reload, never leak into mobile.**
   Sign in with a course; `resize_to(1280, 900)`; visit `courses/show`.
   Assert aside ≈ 280px. Click the (now visible at lg) hamburger → aside
   ≈ 72px; assert cookie `propro_sidebar_rail_collapsed=true` and the
   `aria-expanded` flip; reload → still 72px (server-rendered, no flash).
   Then `resize_to(600, …)`: the drawer is governed purely by the
   translate/backdrop mechanism — `data-collapsed` is inert below `lg`
   (aside back to 280px, translate applied, toggles open/close with
   backdrop).
2. **A11y.** Every nav item has a non-empty accessible name in both states.
3. **Desktop collapsed active shape** — covered by `_sidebar_nav_item`
   structure + the manual §7/§8 review pass.

Test-harness idioms (learned the hard way — keep them):
- `window.resize_to` commits asynchronously in ChromeDriver; **wait for the
  media query** (`window.matchMedia("(min-width: 1024px)").matches`) to
  actually flip before clicking anything after a resize, or the click takes
  the wrong breakpoint branch of `toggle()`.
- Headless Chrome drops ~50% of **native** clicks (toggle, backdrop);
  dispatch with `evaluate_script('this.click()')` like
  `course_tab_persistence_test.rb` does.
- Wait for two consecutive width reads to agree (the `wait_for_sidebar_width`
  idiom from `mobile_overflow_test.rb`) before any geometry assertion.
- Clear cookies in `setup`: one shared browser means a collapsed cookie from
  a prior test leaks into the next.

Manual §7/§8 checklist items (tooltip visuals, scrollbar stability,
transition smoothness) remain a reviewer pass; `rack_test` cannot cover
them.

---

## 11. Build order / tickets

```
1. ADR-0009 (§9) — first, small, unblocks the rest.   [independent]
2. Phase 1 — controller: data-collapsed attr, sidebar_collapsed? helper,
   setCollapsed + breakpoint toggle. Verify: flips on click, persists
   across reload, mobile unaffected.                      [independent]
3. Phase 2 — width + transition (§4); unhide hamburger (§5). Verify smooth
   reflow, no horizontal-scrollbar flash, scroll positions stable.
4. Phase 3 — label-hide variant + Enrolled-group wrapper (§7.2/7.3).
5. Phase 4 — collapsed active shape + icon centering (§7.4).
6. Phase 5 — tooltips + aria-labels + syncExpanded (§7.6/§5).
7. Phase 6 — extract shared/sidebar_nav_item, migrate all items (§7.1).
8. Regression checklist (§12) + system test (§10).
```

Phases 2-8 are one implementation push; the phase split is for review
granularity, not separate landings.

---

## 12. Regression checklist (complete before merge)

- [ ] Mobile off-canvas behavior byte-for-byte unaffected (backdrop, scroll-lock, Esc, `turbo:before-visit`).
- [ ] Collapsed state persists across reload; no wrong-width flash on first paint for returning users.
- [ ] `<main>`'s internal scroll regions unaffected by the width transition (no scrollbar flash/jump).
- [ ] Every nav item has a real accessible name in both states.
- [ ] Toggle button's `aria-expanded` reflects the relevant state at both breakpoints.
- [ ] Header stays exactly 56px (especially `tabs_sticky_test`) now that the hamburger is visible at `lg` — the `h-10 w-10` toggle + `py-2` pin §13 deviation 5.
- [ ] No leftover reference to the legacy `localStorage` `sidebar-collapsed` key (confirmed absent in audit; re-check at merge).
- [ ] ADR-0009 landed alongside the code.
- [ ] `group-data-[collapsed=true]/sidebar:lg:*` variant compiles in the real Tailwind v4 build (smoke-test; grep emitted CSS).

---

## 13. Deviations from the source plan (for the record)

1. **Toggle button:** source assumed the hamburger toggles desktop but never
   addressed that it's `lg:hidden`. Resolved: remove `lg:hidden` (D-1).
2. **Scroll container:** source kept `lg:overflow-y-auto` on `<aside>` and
   suspected problems; audit + tooltip geometry forced moving it to `<nav>`.
   The plan's §3.6 tooltip would have been clipped by the aside's overflow.
3. **Cookie write:** source's sample omitted `samesite=lax; secure` while
   telling implementers to reuse the tabs convention. Spec here is the tabs
   write **verbatim** (§5/§6).
4. **`aria-expanded`:** source wanted it dynamic but kept the concept of
   "the one open state"; spec replaces `setExpanded` with breakpoint-aware
   `syncExpanded` because `close()`/`setExpanded(false)` firing at desktop
   on `turbo:before-visit` would report the wrong state.
5. **Log-out fix:** source (§5/`course_tab_plan` Ticket 7) said to fold in
   the still-unshipped Log-out dead-`<span>` fix. It has **already shipped**
   (working `button_to` in `_sidebar` L57) — folded-in work is zero.
6. **ADR placement:** source didn't mention ADR-0008's conflicting clause;
   `course_tab_plan.md` §9 flagged it. ADR-0009 is now in the build order.
7. **Test coverage:** source had only a manual checklist; §10 adds a system
   test ticket.
8. **D-2 reversal — legacy sidebar deleted, not out of scope:** `courses/profile`
   and `lecturers/show` migrated to `render "shared/sidebar"` via
   `content_for :sidebar`; `render_sidebar`, `ApplicationHelper#sidebar_link`,
   `sidebar_helper.rb`, and `scroll_spy_controller.js` deleted; the layout body
   now holds only `data-controller="sidebar"`. §1 table updated.
9. **Aside width + overflow use self data variants** (`data-[collapsed=true]:lg:*`),
   not `group-data-[collapsed=true]/sidebar:lg:*`: the named-group variant only
   matches descendants (`:is(:where(.group\/sidebar)[data-collapsed=true] *)`),
   so it cannot restyle the `<aside>` itself. Discovered via the system test
   (rail stuck at 280px collapsed). §4 documents the final markup.
10. **Scroll container** kept on `<aside>` (with a collapsed `overflow: visible`
    override) instead of moving `lg:overflow-y-auto` to `<nav>` as the source
    proposed. §7.5 rewritten.
11. **Header height hardening:** unhiding the hamburger at `lg` exposed a
    15px header overgrowth (47px icon-button glyph + `py-3` > `min-h-header`),
    which broke the `tabs_sticky` pin and created a 15px window scroll. Fixed
    via `h-10 w-10 flex items-center justify-center` on the toggle (replacing
    `p-2`) + header `py-3 → py-2`; header is now exactly 56px at all widths.
    §8 documents the finding; §12 guards it.
12. **`aria-expanded` contract move:** removing the hardcoded attribute made
    `project_show_responsive_test` (rack_test, no JS) assert a stale false.
    Updated that test to assert only the static wiring + `data-action`, since
    the runtime value is now exercised by the selenium `sidebar_collapse_test`.
    The selenium `syncExpanded` contract (desktop rail vs mobile drawer) is
    unchanged from §7.6.

---

## 14. Supersedes

- `course_tab_plan.md` §9 ("Sidebar desktop collapse — open, not scoped
  yet, do not build") — replaced by this document.
- `course_tab_plan.md` §11 OI-10..OI-13 and Ticket 7 placeholder — answered
  in §2; the doc's pointer has been updated.