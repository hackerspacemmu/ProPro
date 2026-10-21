# ADR 0019 — Course tabs are routes: one URL per tab, plain Turbo Drive links

Date: 2026-10-08
Status: Accepted

## Context

The Overview / Topics / People / Groups tab set on `courses/show` was a
client-side panel switch: one action rendered all four panels hidden or
un-hidden, the `tabs` Stimulus controller swapped their visibility, and the
selected slug was persisted to a per-course cookie (`propro_tab_course_<id>`)
so the server could pick the right panel on the next full load. The htmx
filter branches for the Groups, Students, and topics lists rode along in
`courses#show`, dispatched by a `section` param.

That design had four costs:

- **The URL lied.** A student could not link a colleague to the People tab;
  back/forward stepped through pages, not tabs, and a reload raced the cookie
  against the server's default.
- **Every tab paid for every tab.** `courses#show` loaded the students maps,
  the group list, the topics directory scope, and the capacity calculator even
  for a coordinator who only wanted Overview, and its view concatenated four
  tab bodies into one response.
- **The cookie had to be trusted.** `current_tab_index` read it back on every
  load, and `connect()` had to avoid fighting it (the flash-of-wrong-tab
  problem), which is state the server and client must agree on at runtime.
- **The `section` param was a hidden router.** Three htmx branches inside one
  action duplicated route-shaped behavior that routes already express.

ADR 0015 had already settled that fragments are server-rendered and swapped
wholesale; the missing piece was that a *tab* is a page, not a fragment.

## Decision

Each course tab gets its own route, and the tab strip becomes plain Turbo
Drive links — the URL is the source of truth.

- **Routes.** `courses#show` stays Overview-only (no separate overview route).
  New: `people#index` (`/courses/:course_id/people`) and `groups#index`
  (`/courses/:course_id/groups`); the nested `topics` resource gains `:index`
  so `topics#index` serves `/courses/:course_id/topics`. Each controller
  includes the shared `ParticipantBrowsing` concern for the filter/search/sort
  helpers that moved out of `courses#show`.
- **Links, not frames.** The strip (`courses/_tab_strip`) renders `<a>` tags
  inside a `<nav aria-label="Course sections">`; the active tab is
  server-rendered as `aria-current="page"` plus the blue underline. No
  `role="tablist"`/`aria-selected` (there are no tab panels anymore), and no
  client-side panel swap. The shared chrome — breadcrumb, sidebar,
  capped-height `<main>` scroll pane, strip, and the `#panel-<slug>` content
  div tests scope against — lives in `courses/_tab_shell`, rendered by all
  four pages.
- **Gating.** `groups#index` raises `ActiveRecord::RecordNotFound` when the
  course is not grouped (the tab does not exist, so the route does not either;
  test env renders 404). `topics#index` is exempt from the `toggle_topics`
  redirect: it renders (200) with the disabled empty state, which is content,
  not a redirect. Authorization matches `courses#show` exactly —
  `authorize @course, :show?`, so a non-enrolled user is redirected to root
  with the standard alert on every one of the four routes (the bare
  `authorize` would resolve `ApplicationPolicy#index?` and deny everyone).
- **htmx branches move with their tabs.** The `section=` dispatch in
  `courses#show` is deleted; `GroupsController#index`, `PeopleController#index`,
  and `TopicsController#index` each render their table partial directly on
  `HX-Request`, and the partials' `hx-get` now points at the tab's own URL
  with the `section` key dropped from `hx-vals`.
- **The shortcut crosses routes honestly.** The `/` search shortcut's fallback
  jump is a real click on the Groups link (tagged
  `data-search-shortcut-target="fallbackLink"`), so Turbo Drive navigates.
  The "focus the search after arrival" flag lives at module scope in
  `search_shortcut_controller.js`, because a Drive visit swaps the body and
  re-connects a fresh controller instance — per-instance state would not
  survive — and it is honored in both `connect()` and a `turbo:load` listener.
- **What keeps the old controller.** `tabs_controller.js` and
  `current_tab_index` remain for projects/show and topics/show, which are
  still cookie-persisted panel sets; only the courses cookie wiring is gone.
  *(Resolved by ADR 0022: projects and topics also became route-per-tab, so the
  controller and helper are now deleted entirely.)*

## Consequences

- Every tab is linkable, bookmarkable, and back/forward-navigable; the
  per-course cookie and its flash-of-wrong-tab constraints disappear from
  `courses/show`.
- Each tab page loads only its own data: Overview no longer precomputes the
  students/group maps or the topics scope, and each response carries one tab's
  markup instead of four.
- The three htmx endpoints are now ordinary routes, so their filter requests
  hit the same authorization as the page path for free.
- `test/system/courses/course_tab_persistence_test.rb` (cookie guard) was
  replaced by `course_tab_navigation_test.rb` (URL + browser-back guard), and
  the search-shortcut fallback gained its own system coverage
  (`search_shortcut_test.rb`) — both behaviors changed shape.
- Headless-Chrome caveat recorded in that file: `document.hasFocus()` is false
  for the test window, so focus is asserted through `document.activeElement`,
  never the `:focus` pseudo-class; and the key is dispatched as a
  `KeyboardEvent` on `window` because OS-level `send_keys` drops keys when the
  window is unfocused (same finding as ADR 0007's Escape dispatch).

## References

- ADR 015 — server-rendered fragment swapping (htmx) for filter updates
- ADR 018 — browse-table empty state decided in the controller
- ADR 013 — topics directory (the `topics/index` page it deleted, reintroduced here as the tab's route)
