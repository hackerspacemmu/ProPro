# ProPro — courses/show — Header & Tab Bar Revision (v3)

Addendum to *"ProPro Redesign — courses/show — Breadcrumb, Tab Bar &
Empty-State Illustrations — Follow-up Plan (v2)."* Everything in v2 stands
**except** §0.1, §4.1, §4.2, Tickets 1–3, and the tab-bar/breadcrumb rows of
the §6 open-items table, which this doc supersedes. §2, §3.3, §3.4, §4.3,
Tickets 0 and 4–8 are unchanged and still apply.

**Trigger for this revision:** a direct side-by-side against Google
Classroom's mobile layout (Classroom: 4 tabs, no breadcrumb chain, gear icon
in the header) made it clear the six-tab-plus-Settings-plus-full-breadcrumb
row on mobile isn't a spacing problem to patch — it's carrying more
navigation than Classroom's equivalent row, full stop. v2's "responsive
More menu, nothing removed from the row" compromise (§0.1, Option B)
under-corrects for that. This revision goes further on two specific points
that v2 had explicitly deferred or rejected:

1. **Settings moves out of the tab row into the header, mobile only.**
   v2's §0.1 "Option A" considered this and rejected it as an IA change
   out of scope — but Alex has since confirmed this is exactly what's
   wanted, scoped to mobile only (desktop keeps Settings as the existing
   inline tab-row link, unchanged). This isn't the full Option A (Groups
   still stays a separate top-level tab, not merged into People) — just
   the Settings half of it, and only below `sm`.
2. **The mobile header drops both the ProPro wordmark and the full
   breadcrumb trail**, leaving only the truncated current-page name — v2
   had already decided to drop the trail below `sm` (§0.1), this extends
   the same logic to the wordmark, since a "ProPro" label plus a course
   name is redundant chrome on a screen this narrow, and the drawer
   (opened via the hamburger, which stays) already gets you home.

A third change follows from the first: since the header's mobile "action"
slot now holds the settings gear, **Log out no longer fits there** and
needs a new, permanent home — the sidebar drawer (see §3 below). This
wasn't part of the original ask but is a direct consequence of it.

---

## 0. Confirmed decisions

**All four tabs are always visible at every width.** No overflow menu, no
"More" dropdown, no horizontal scroll. The tab set is: Overview, Topics,
People, Groups. On narrow screens (<360px) the spacing between tabs is
tightened so all four fit. Settings gear moves to the header on mobile
(see §2) and is removed from the tab row entirely on mobile.

Styling matches Google Classroom: blue 3px underline on the active tab,
14px / 500 weight, `'Google Sans', Roboto, Arial, sans-serif` font stack.

---

## 1. What changed, in one table

| Element | v2 (previous plan) | v3 (this revision) |
|---|---|---|
| Settings, mobile | Rendered inline in tab row, hidden below `lg`, moved into "More" dropdown | Removed from tab row and "More" entirely; rendered as a gear icon in the header, mobile only |
| Settings, desktop | Inline tab-row link | Unchanged — inline tab-row link |
| ProPro wordmark, mobile | Unchanged (still shown) | Hidden below `sm` |
| ProPro wordmark, desktop | Shown, plain text | Shown, now also the Home link (wraps in `link_to`) |
| Breadcrumb trail, mobile | Collapses to truncated current-page name below `sm` (already decided in v2) | Unchanged — same collapse, now paired with the wordmark also hiding |
| Log out, mobile | Unchanged (still a header link) | Removed from header; added to the sidebar drawer, below "Edit profile" |
| Log out, desktop | Header link | Unchanged — header link |
| Primary tab count, mobile | 4 | 3 (assumed — see §0) |

---

## 2. Header — `app/views/shared/_header.html.erb`

```erb
<header class="flex items-center justify-between gap-3 px-4 py-3 min-h-[3.5rem]">
  <div class="flex items-center gap-2 min-w-0 flex-1">
    <% unless content_for?(:hide_toggler) %>
      <button type="button" data-sidebar-target="toggleButton" data-action="sidebar#toggle"
        aria-label="Toggle sidebar" aria-expanded="false" aria-controls="app-sidebar"
        class="lg:hidden shrink-0 p-2 rounded-full hover:bg-[#EEF0F4] text-[#5F6368] transition-colors">
        <span class="material-symbols-outlined">menu</span>
      </button>
    <% end %>

    <%# Desktop only (sm and up): wordmark, now also the Home link %>
    <%= link_to "ProPro", root_path,
          class: "hidden sm:inline shrink-0 text-[24px] text-[#5F6368] font-medium hover:text-[#3C4043] transition-colors" %>

    <% unless content_for?(:hide_breadcrumbs) %>
      <%# Desktop only: full trail (unchanged from v2 Ticket 2) %>
      <div class="hidden sm:flex sm:items-center sm:gap-2 sm:min-w-0">
        <% render_custom_breadcrumbs %>
        <%= yield :breadcrumbs if content_for?(:breadcrumbs) %>
      </div>

      <%# Mobile only: current page name, nothing else — no wordmark, no chevron chain %>
      <span class="sm:hidden truncate text-[17px] text-[#3C4043] font-medium min-w-0">
        <%= current_breadcrumb_page_name %>
      </span>
    <% end %>
  </div>

  <div class="flex items-center gap-1 shrink-0">
    <%# Desktop only: text log-out link, unchanged %>
    <%= button_to "Log out", session_path, method: :delete,
          form: { data: { turbo_confirm: nil } },
          form_class: "hidden sm:block m-0",
          class: "text-[15px] font-medium text-[#5F6368] hover:text-[#3C4043] transition-colors pr-2 bg-transparent border-0 cursor-pointer" %>

    <%# Mobile only: settings gear, replaces log-out's slot. Guarded — header is shared
        by ~30 views, not all of which have @course. %>
    <% if @course.present? %>
      <%= link_to settings_course_path(@course),
            class: "sm:hidden p-2 rounded-full hover:bg-[#EEF0F4] text-[#5F6368] transition-colors",
            aria: { label: "Course settings" } do %>
        <span class="material-symbols-outlined">settings</span>
      <% end %>
    <% end %>
  </div>
</header>
```

**Blocked on the same prerequisite v2 already flagged (its §4.1):**
`current_breadcrumb_page_name` needs to exist as a real accessor in
`breadcrumb_helper.rb` / `config/breadcrumbs.rb` before this ships — read
both files first. Do not stand in `@course&.course_name` as a placeholder;
it's wrong on the ~29 other views sharing this header.

**New, not in v2:** the `if @course.present?` guard on the settings gear.
Every other element in this header (wordmark, breadcrumb, log out) works
on any page; the settings gear specifically only makes sense inside a
course, so it needs its own conditional rather than assuming context.

---

## 3. Sidebar — `app/views/shared/_sidebar.html.erb`

Add Log out below the existing divider/"Edit profile" block, so removing
it from the mobile header doesn't strand the feature:

```erb
<div class="py-2">
  <div class="border-t border-[#DADCE0]"></div>
</div>

<% profile_active = current_page?(user_profile_path) %>
<%= link_to user_profile_path, ... %> <%# unchanged, existing Edit profile link %>

<%= button_to "Log out", session_path, method: :delete,
      form: { data: { turbo_confirm: nil } }, form_class: "m-0",
      class: "flex items-center gap-4 w-full text-left px-6 py-3.5 rounded-r-full text-[#3C4043] hover:bg-white/60 transition-colors bg-transparent border-0 cursor-pointer",
      style: "font-family: 'Google Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500; letter-spacing: 0; line-height: 1.25rem;" do %>
  <span class="material-symbols-outlined text-[#5F6368]">logout</span>
  <span>Log out</span>
<% end %>
```

This renders at every width (the drawer itself is what's mobile-only, via
the existing `-translate-x-full lg:static` treatment) — so on desktop, Log
out now exists in two places (header + drawer). That's an intentional,
Classroom-like redundancy (its "Log out"-equivalent lives in more than one
menu too), not a bug to dedupe.

---

## 4. Tab bar — `app/views/courses/show.html.erb`

Same primary/overflow mechanism as v2 §4.2 (scrolling-strip + fade mask
ported unchanged from `_project_header.html.erb`, `data-tabs-index-param`
still computed via `each_with_index` so the existing tab-index fix holds)
— only the membership of `primary_names` changes, and Settings is removed
from the loop entirely rather than being hidden/relocated into "More":

```erb
<%
  tabs = []
  tabs << { name: "Project Details", partial: "courses/project_details_tab" }
  tabs << { name: "To Review", partial: "courses/to_review_tab" }
  if @current_user_enrolment&.coordinator? || @current_user_enrolment&.lecturer?
    tabs << { name: "Supervised Projects", partial: "courses/supervised_projects_tab" }
  end
  tabs << { name: "Topic Directory", partial: "courses/topic_directory_tab" }
  tabs << { name: "People", partial: "courses/people_tab" }
  tabs << { name: "Groups", partial: "courses/groups_tab" }

  # Assumed per §0 — confirm before building.
  primary_names = ["Project Details", "To Review", "People"]
  overflow_tabs = tabs.reject { |t| primary_names.include?(t[:name]) }
%>

<div class="border-b border-[#E0E0E0] px-6 pt-4">
  <div data-controller="tab-fade">
    <div data-testid="content-tabs" data-tab-fade-target="scroller"
         class="flex flex-nowrap items-center gap-x-8 gap-y-1 overflow-x-auto
                [scrollbar-width:none] [&::-webkit-scrollbar]:hidden
                [-webkit-overflow-scrolling:touch]">

      <% tabs.each_with_index do |tab, index| %>
        <% is_overflow = overflow_tabs.include?(tab) %>
        <button type="button" data-tabs-target="tab" data-action="tabs#show"
                data-tabs-index-param="<%= index %>"
                style="font-family: 'Google Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500; letter-spacing: 0; line-height: 1.25rem;"
                class="pb-3 whitespace-nowrap border-b-4 transition-colors <%= is_overflow ? "hidden lg:inline-flex" : "" %>">
          <%= tab[:name] %>
        </button>
      <% end %>

      <%# Settings: desktop-only here. No mobile counterpart in this row —
          it lives in the header gear instead (see §2). %>
      <%= link_to "Settings", settings_course_path(@course),
            style: "font-family: 'Google Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500; letter-spacing: 0; line-height: 1.25rem;",
            class: "pb-3 whitespace-nowrap text-[#5F6368] hover:text-[#3C4043] border-b-4 border-transparent transition-colors hidden lg:inline-flex" %>

      <% if overflow_tabs.any? %>
        <div class="lg:hidden relative shrink-0" data-controller="dropdown">
          <button type="button" data-action="dropdown#toggle"
                  class="pb-3 whitespace-nowrap text-[#5F6368] hover:text-[#3C4043] border-b-4 border-transparent transition-colors">
            More <span aria-hidden="true">⌄</span>
          </button>
          <div data-dropdown-target="menu" class="hidden absolute right-0 top-full mt-1 min-w-[10rem] bg-white border border-[#E0E0E0] rounded-lg shadow-lg z-10">
            <% overflow_tabs.each do |tab| %>
              <button type="button" data-action="tabs#show dropdown#close"
                      data-tabs-index-param="<%= tabs.index(tab) %>"
                      class="block w-full text-left px-4 py-2.5 text-sm text-[#3C4043] hover:bg-[#F1F3F4]">
                <%= tab[:name] %>
              </button>
            <% end %>
            <%# No Settings item here — it's in the header gear on mobile, not this menu. %>
          </div>
        </div>
      <% end %>
    </div>
    <div data-tab-fade-target="rightMask"
         class="pointer-events-none absolute right-0 top-0 h-full w-8 bg-gradient-to-l from-white to-transparent hidden"></div>
  </div>
</div>
```

Two things worth calling out because they're easy to get wrong copying
from v2's version of this block:

- The Settings `link_to` is **not** duplicated into the "More" dropdown
  the way it was in v2 — v2 rendered Settings inline *and* in the menu
  (`hidden lg:inline-flex` + a menu copy) as parallel triggers for the same
  destination. Here there is exactly one Settings entry point below `lg`
  (the header gear) and one above it (this inline link) — never both at
  once, and never inside the dropdown.
- `settings_course_path(@course)` is called in two places now (header gear,
  desktop tab link) — same path helper, just gated by opposite breakpoints,
  so they never render at the same time and there's no duplicate-ID risk.

---

## 5. Ticket list (supersedes v2 Tickets 1–3)

### Ticket 1 — Header: mobile wordmark/breadcrumb drop + settings gear

Implement §2 above. Requires `current_breadcrumb_page_name` (blocked on
reading `breadcrumb_helper.rb` / `config/breadcrumbs.rb` — same
prerequisite v2 already flagged, now blocking two things instead of one).

### Ticket 2 — Sidebar: add Log out

Implement §3 above. No dependencies — can land independently and first.

### Ticket 3 — Tab bar: 3-tab primary set, Settings removed from row/menu

Implement §4 above. **Blocked on §0** — confirm the primary-3 list before
building; only the `primary_names` array changes if the assumed set is
wrong, but building against the wrong assumption wastes a review cycle.

### Ticket 4 — Breadcrumb helper truncation fix (unchanged from v2 Ticket 2)

`flex-wrap` → `flex-nowrap` on the trail container, `break-all` →
`truncate flex-1 min-w-0` on the final crumb — still needed at `sm` and up
regardless of the mobile collapse. No change from v2.

### Build order

```
2 (independent, do first)
1 → depends on the same breadcrumb-helper read as 4
3 → blocked on §0 confirmation
4 → unblocks 1 and 3's mobile-name display
```

v2's Tickets 0 (file-boundary check) and 4–8 (empty states, tests) are
unaffected by this revision and proceed as originally planned.

---

## 6. Open items (updates to v2 §6)

| # | Question | Status |
|---|---|---|
| OI-1 (v2) | Breadcrumb truncate + mobile collapse | Unchanged — resolved in v2, this doc just extends it to also hide the wordmark. |
| OI-6 (new) | Which 3 tabs are primary on mobile? | **Open — see §0.** Assumed Project Details/To Review/People pending confirmation. |
| OI-7 (new) | Settings-in-header gear: any other mobile pages besides courses/show need the same treatment, or is it courses/show-specific? | Open — not addressed in this revision; `_header.html.erb` is shared by ~30 views, and right now the gear only renders `if @course.present?`, which happens to be true elsewhere too (e.g. topics, lecturers pages) — worth deciding whether that's intended or should be scoped tighter. |
| — (v2, tab-row "More" superseded) | Permanent 4-tab merge vs. responsive "More" keeping all destinations | Still resolved as "responsive, nothing merged" per v2 §0.1 — this revision doesn't reopen that, it just also pulls Settings out of the *tab row* specifically (not a full IA merge). |

---

# Addendum (v4) — Content-tab scroll-lock + sidebar desktop collapse

Two new asks, unrelated to each other except that both touch shared chrome:

1. **Header tabs (the content-tab row, not the app sidebar) need to be
   scroll-locked** on `courses/show`, `projects/show`, and `topics/show`.
2. **The app sidebar (`shared/_sidebar`) should be collapsible at every
   width, not just below `lg`** where it already collapses to an off-canvas
   drawer today.

Everything in v3 above (§0–§6) still stands. This addendum doesn't touch the
header wordmark/breadcrumb/settings-gear work — it's a separate track that
happens to live in the same doc because it shares files (`_sidebar`,
`courses/show`) with v3's tickets.

**Before writing tickets, a grounding pass against the actual
`refactor/design` branch turned up two things worth flagging up front:**

- **v3 Ticket 2 (sidebar Log out) never shipped.** `_sidebar.html.erb`
  still has Log out as an inert `<span>` — no `href`, no `button_to`, no
  `session_path`. Clicking it does nothing. This addendum's sidebar work
  touches the same file, so Ticket 7 below folds the v3 Ticket 2 fix back
  in rather than leaving it stranded a second time.
- **v3 Ticket 3's own code sample (§4 above) is stale.** It shows a
  3-primary-tab-plus-"More"-dropdown mechanism for `courses/show`. That's
  not what's on the branch. `docs/tabs_to_cookies_refactor_plan.md`
  superseded it: `courses/show` now renders all four tabs unconditionally
  (`Overview`, `Topics`, `People`, `Groups`, no overflow menu at all),
  switched client-side by `tabs_controller.js`, with the active slug
  persisted to a plain cookie (`propro_tab_course_<id>`) so the server
  renders the right panel un-hidden on next load — no `dropdown` controller,
  no `data-tabs-index-param` computed against a filtered array. This
  actually *satisfies* v3 §0's "all four tabs always visible, no overflow"
  decision, just via a different, later mechanism than the one v3 §4
  sketched. Read the current `app/views/courses/show.html.erb` and
  `app/javascript/controllers/tabs_controller.js` directly — don't rebuild
  from v3's §4 snippet.

---

## 7. Current-state audit — what's actually on `refactor/design`

| Area | File(s) | Current state |
|---|---|---|
| `courses/show` tab bar | `app/views/courses/show.html.erb` L29 | `<div class="border-b border-[#E0E0E0] px-4 sm:px-8 bg-white shrink-0">` — **not sticky.** `main` (L23) has `overflow-hidden`, no `overflow-y-auto`, and no capped height, so the page scrolls at the **window** level, not in an inner pane. |
| `projects/show` tab bar | `app/views/projects/_project_header.html.erb` L41 | `<div class="border-b border-[#E0E0E0] px-8 sticky top-0 bg-[#FFFFFF] z-10">` — **already sticky**, inside a left pane (`projects/show.html.erb` L32, `flex-1 flex flex-col overflow-y-auto`) that is its own scroll container, separate from the window. |
| `topics/show` tab bar | `app/views/topics/_context_header.html.erb` L39 | Same as `projects/show`, byte-for-byte: `sticky top-0 bg-[#FFFFFF] z-10`, inside an equivalent `overflow-y-auto` left pane (`topics/show.html.erb` L34). **Already sticky.** |
| Sidebar drawer | `app/javascript/controllers/sidebar_controller.js`, `app/views/shared/_sidebar.html.erb` | Off-canvas drawer **below `lg` only**. `-translate-x-full` + backdrop + body-scroll-lock below `lg`; forced `lg:static lg:translate-x-0 lg:h-auto` at `lg`+ with **no** collapse capability and **no visible trigger** at `lg`+ (the hamburger button in the header is itself `lg:hidden`). No resize listener, no width toggling, no persistence of any kind. |
| Sidebar render sites | grep across `app/views` | Rendered directly on `courses/show`, `projects/show`, `topics/show`; via the layout's `:sidebar` slot on `courses/profile` and `lecturers/show`. Opted out (`content_for :no_sidebar`) on `projects/edit`, `projects/new`, `topics/edit`, `topics/new`, `topics/index`, `courses/settings`, `homescreen/show`. Controller is scoped on `<body>` (`app/views/layouts/application.html.erb` L27), so it already resolves on every render path — a desktop-collapse change has at least a 5-page blast radius, not a 1-page one. |

So: two of the three "scroll lock" targets are done. The third
(`courses/show`) is a small, well-understood gap. The sidebar ask is a
different size of problem entirely — see §9.

---

## 8. Ticket 5 — `courses/show` content tabs: add scroll-lock

**Not blocked. Small, mechanical, no JS changes.**

Bring `courses/show` to parity with `projects/show`/`topics/show` by making
its tab-bar row sticky. Since `courses/show`'s `main` has no inner
`overflow-y-auto` pane (unlike the other two), the scroll container here is
the window itself — so `sticky top-0` pins the row to the literal top of
the viewport once the (non-sticky, shared) header scrolls past it. That's
the same *visual* result as the other two pages produce inside their own
panes, via a different but equally valid scroll container.

```diff
- <div class="border-b border-[#E0E0E0] px-4 sm:px-8 bg-white shrink-0">
+ <div class="border-b border-[#E0E0E0] px-4 sm:px-8 bg-white shrink-0 sticky top-0 z-10">
```

That's the entire code change. `tab-fade` and `tabs_controller.js` are
untouched — sticky positioning is pure CSS and doesn't interact with either.

**Manual/visual check, not just a diff review:** confirm the sticky row
doesn't visually collide with the mobile sidebar drawer backdrop (`z-40`)
or the drawer itself (`z-50`) if a user opens the drawer while scrolled —
`z-10` is safely under both, so this should be a non-issue, but it's worth
eyeballing once since nothing currently tests it.

### Ticket 6 — Regression coverage for all three sticky tab bars

None of the three pages currently have a test asserting the tab row is
*actually* sticky (`projects/show` and `topics/show` are correct today, but
only by nobody having broken them yet — there's no test pinning that down).
`rack_test` can't check this (no real scrolling, no `getBoundingClientRect`)
— follow the existing `test/system/projects/mobile_overflow_test.rb`
pattern: `driven_by :selenium, using: :headless_chrome`, real viewport,
`page.evaluate_script` to scroll and read geometry.

Suggested shape, one test per page (or parametrize if the harness supports
it cleanly):

```ruby
visit course_path(@course) # or the project/topic equivalent
page.execute_script("window.scrollTo(0, 600)") # or scroll the inner pane for projects/topics
top = page.evaluate_script(
  "document.querySelector('[data-testid=\"content-tabs\"]').closest('.sticky').getBoundingClientRect().top"
)
assert_in_delta 0, top, 1
```

For `projects/show`/`topics/show`, scroll the **left pane**
(`document.querySelector('.overflow-y-auto').scrollTop = ...`), not the
window — scrolling the window there won't move anything, since the pane is
its own scroll container.

---

## 9. Sidebar desktop collapse — **open, not scoped yet, do not build**

This is the item to flag as undone. Don't turn it into a ticket with a diff
the way §8 got one — there isn't yet a single decision made about *how* it
should work, and the history here means guessing wrong is more expensive
than usual.

**Why this isn't a green light to just extend `sidebar_controller.js`:**
`docs/adr/0008-app-sidebar-drawer.md` (Accepted, 2026-08-29) is the ADR that
put the *current* mobile-only drawer in place, and it did so by **deleting**
a prior "desktop collapse-to-rail + `localStorage`" feature from that exact
controller, describing it as dead weight that never actually worked because
its width-toggling classes never matched the markup. The ADR's stated
decision going forward is explicit: *"no resize listener, no width-class
juggling, no localStorage, no desktop collapsible rail."* Reopening desktop
collapse now doesn't extend that ADR, it contradicts a clause of it — so
this needs either an amendment to ADR-0008 or a new ADR that supersedes
that clause, on paper, before code lands. Don't let this land as a quiet
diff against a controller whose commit history says the opposite was a
deliberate choice.

### Open questions (all unresolved — none of these have an answer yet)

| # | Question | Why it matters |
|---|---|---|
| OQ-1 | **Same `sidebar_controller.js`, or a separate controller?** (this is the question raised in chat, carried in here verbatim) | The mobile drawer and a desktop collapse are behaviorally opposite in three ways: mobile is a transient overlay that closes on every `turbo:before-visit` and locks body scroll via a backdrop; a desktop collapse is a persistent layout preference that should almost certainly *survive* navigation and has no backdrop or scroll-lock reason to exist. Cramming both into one controller means breakpoint-branching (`matchMedia`) inside `open()`/`close()`/`onBeforeVisit()` — which is close to the shape of complexity ADR-0008 removed once already. A separate controller avoids that, at the cost of two controllers sharing one `<aside id="app-sidebar">` element (manageable, since mobile uses a transform and desktop would use a width/class toggle — different properties, no direct collision — but still needs an explicit contract). No recommendation is being made here beyond naming the tradeoff; this needs an actual answer before Ticket 7 gets written. |
| OQ-2 | **Collapsed visual model:** icon-only rail (~64–72px, Drive/Classroom-style), or fully hidden (0px, content reflows full-width), or something else? | Changes ticket size by a lot. The current row markup (`flex items-center gap-4 ... <span>Home</span>`) isn't built to degrade to icon-only — every row's label would need its own hide/show state, padding and the `rounded-r-full` active treatment would need rework, and icon-only rows need `title`/`aria-label` for a11y that the label currently provides implicitly. "Fully hidden" is a much smaller change (closer to a wider version of what the mobile drawer already does) but reads less like a "collapse" and more like "also allow closing it on desktop." |
| OQ-3 | **Persistence:** in-memory only (resets on reload), `localStorage`, or a plain cookie read server-side at render (the pattern `tabs_controller.js` already established for tab selection, avoiding flash-of-wrong-state)? | ADR-0008 specifically named `localStorage` as one of the things it tore out — re-adding it needs to be a conscious, written decision, not a default. The cookie approach has direct precedent in this codebase (`propro_tab_course_<id>` etc.) and would avoid a flash of the wrong sidebar width on first paint, but nobody has confirmed that's the intended model here. |
| OQ-4 | **Breakpoint(s):** does desktop collapse apply at the existing `lg` (1024) cutoff, or does it need its own, given ADR-0008 already treats "chrome breakpoint" (`lg`) and "content breakpoint" (`min-[1245px]`, used by the comments drawer) as deliberately independent? A collapsed-but-not-hidden rail between those two breakpoints is a plausible third state nobody's asked for yet but which the layout may end up implying. | Affects how many responsive states the markup needs to account for. |
| OQ-5 | **Paper trail:** new ADR, or an amendment to 0008? | Process, not code, but should happen before or alongside implementation, not after. |

None of Ticket 7 (below) should start until at least OQ-1, OQ-2, and OQ-3
have real answers. OQ-4/OQ-5 can be resolved in parallel with early
implementation but need to land before merge.

### Ticket 7 — Sidebar: collapsible at every width (BLOCKED on §9's open questions)

Placeholder only. Once OQ-1–OQ-3 are answered, this ticket should specify:
the controller (existing vs. new, per OQ-1), the collapsed-state markup
(per OQ-2), the persistence mechanism (per OQ-3), and should fold in the
still-unshipped **v3 Ticket 2 fix** (sidebar Log out is currently a dead
`<span>` with no `href` — see the addendum intro above) since it's the same
file. Do not scope hours or write a diff for this until it's unblocked.

---

## 10. Updated build order (v3 §5 + this addendum)

```
2 (v3, independent — still not shipped, see addendum intro)
1 (v3) → depends on breadcrumb-helper read, shared with v3 Ticket 4
3 (v3) → superseded in practice by tabs_to_cookies_refactor_plan.md; verify
          current behavior against §0's "all four tabs, no overflow"
          decision rather than re-implementing from v3 §4's stale sample
4 (v3) → unblocks 1 and 3's mobile-name display
5 (this addendum) → independent, no blockers, do any time
6 (this addendum) → depends on 5 landing first (for courses/show); can
                     start immediately for projects/show + topics/show
7 (this addendum) → BLOCKED on §9 OQ-1 through OQ-3 (people decision,
                     not implementation work)
```

---

## 11. Open items (extends v3 §6)

| # | Question | Status |
|---|---|---|
| OI-8 | v3 Ticket 2 (sidebar Log out) — still not implemented on `refactor/design` | **Open — undone.** Dead `<span>`, no `href`/`button_to`. Should be folded into Ticket 7's diff since it's the same file, but is small enough to land standalone sooner if Ticket 7 stays blocked a while. |
| OI-9 | v3 Ticket 3 / §4 code sample vs. actual shipped tab mechanism | Resolved as "moot" — the branch already satisfies §0's decision via `tabs_to_cookies_refactor_plan.md`'s cookie mechanism instead. Noted here so nobody re-implements the stale "More" dropdown from v3 §4 by mistake. |
| OI-10 | Sidebar desktop collapse — same `sidebar_controller.js` or a separate one? | **Open — undone, needs a decision.** See §9 OQ-1. This is the question raised in chat; it is not answered in this doc on purpose. |
| OI-11 | Sidebar desktop collapse — collapsed-state visual model | **Open — undone.** See §9 OQ-2. |
| OI-12 | Sidebar desktop collapse — persistence mechanism | **Open — undone.** See §9 OQ-3, note the direct tension with ADR-0008's explicit removal of `localStorage`. |
| OI-13 | Sidebar desktop collapse — needs a new/amended ADR before merge | **Open — undone.** See §9 OQ-5. |