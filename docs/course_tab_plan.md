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