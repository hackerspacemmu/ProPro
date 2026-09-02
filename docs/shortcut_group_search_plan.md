# Implementation plan: `/` search shortcut + last-tab cookie + kbd badge

**Repo:** `hackerspacemmu/ProPro`, branch `refactor/design`
**Verified against:** current state of `refactor/design` (pulled directly from the branch — none of this exists yet; `search_shortcut_controller.js` is not present, `tabs_controller.js` has no persistence, no cookie code exists anywhere in the app).

## Scope

1. `/` jumps to the relevant search box (Groups/People tabs), falling back to the Groups tab if the current tab has no search box.
2. A per-course "last visited tab" cookie, read server-side, so the correct tab is already rendered on page load (no flash-of-wrong-tab).
3. A static `<kbd>/</kbd>` discoverability badge inside each search input, GitHub-style, hidden on focus and hidden on mobile (it's a keyboard hint — there's no keyboard to hint at on touch).

**Explicitly out of scope** (deferred, not part of this plan): moving the Groups table into Overview, role-based tab reordering, People-tab section reordering (Students-before-Teachers). None of the changes below touch Overview's layout or role-conditional rendering.

---

## 1. New file: `app/javascript/controllers/search_shortcut_controller.js`

Follows the existing manual-listener convention from `sidebar_controller.js` (bound `connect`/`disconnect` pair) rather than a declarative `data-action="keydown@window->..."`, to match that file's style.

```js
import { Controller } from "@hotwired/stimulus";

// Global "/" shortcut, GitHub/Gmail-style: focuses the search input on the
// current tab panel instead of opening anything new. If the current panel
// has no search input (Overview / To Review / Topics), switches to the
// Groups tab first — confirmed default, since Groups search matches both
// groups and students — then focuses that input.
//
// Scoped to the same element as the "tabs" controller in courses/show.html.erb
// (data-controller="tabs search-shortcut" lives on the same <main>), so every
// DOM query below stays within this page's tab bar/panels.
//
// Search inputs opt in with:
//   data-search-shortcut-target="input"                 <- any tab's search box
//   data-search-shortcut-target="input fallbackInput"    <- Groups tab's box only
export default class extends Controller {
  static targets = ["input", "fallbackInput"];

  connect() {
    this.boundOnKeydown = this.onKeydown.bind(this);
    window.addEventListener("keydown", this.boundOnKeydown);
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundOnKeydown);
  }

  onKeydown(event) {
    if (event.key !== "/") return;
    if (this.isTypingTarget(event.target)) return;
    if (document.querySelector("dialog[open]")) return;

    event.preventDefault();
    this.focusRelevantInput();
  }

  isTypingTarget(target) {
    if (!target) return false;
    if (target.isContentEditable) return true;
    return ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName);
  }

  focusRelevantInput() {
    const input = this.currentPanelInput();
    if (input) {
      input.focus();
      return;
    }
    this.jumpToFallback();
  }

  currentPanelInput() {
    const panel = this.element.querySelector('[data-tabs-target="panel"]:not(.hidden)');
    if (!panel) return null;
    return this.inputTargets.find((input) => panel.contains(input)) || null;
  }

  jumpToFallback() {
    if (!this.hasFallbackInputTarget) return;

    const panels = Array.from(this.element.querySelectorAll('[data-tabs-target="panel"]'));
    const panel = this.fallbackInputTarget.closest('[data-tabs-target="panel"]');
    const index = panels.indexOf(panel);
    if (index === -1) return;

    // Real click, not a direct call into the tabs controller — this keeps
    // the two controllers decoupled (DOM is the only contract between them)
    // and it means the fallback jump persists to the last-tab cookie the
    // same way a manual click would (see tabs_controller.js #persist).
    const tabButton = this.element.querySelectorAll('[data-tabs-target="tab"]')[index];
    tabButton?.click();
    this.fallbackInputTarget.focus();
  }
}
```

No manual registration needed — `app/javascript/controllers/index.js` already does `eagerLoadControllersFrom("controllers", application)`, so this file auto-registers as identifier **`search-shortcut`** from its filename.

---

## 2. Modified: `app/javascript/controllers/tabs_controller.js`

Two changes to the existing generic controller:

- `connect()` currently hardcodes `index: 0`. That's fine today because the server always renders panel 0 visible — but once the server starts rendering a *different* initial panel based on the cookie (see §3), a hardcoded `connect()` would immediately stomp that and flash back to Overview. Fix: `connect()` now reads whichever panel the server already left un-hidden, instead of forcing 0.
- New optional `persistKey` value. When the wrapping element sets `data-tabs-persist-key-value="..."`, every user-initiated `show()` writes the selected tab's slug to a cookie under that key. This is opt-in and backward-compatible — any other page already using `data-controller="tabs"` without the value keeps working exactly as before.

Full replacement:

```js
import { Controller } from "@hotwired/stimulus";

// Generic tab controller — deliberately NOT mobile_tabs_controller.js,
// which is hard-coded to 3 named targets for the project/topic show pages
// and out of scope for this work.
//
// Usage:
//   <div data-controller="tabs" data-tabs-active-class="..." data-tabs-persist-key-value="...">
//     <button data-tabs-target="tab" data-action="tabs#show"
//             data-tabs-index-param="0" data-tabs-slug-param="overview">...</button>
//     <div data-tabs-target="panel">...</div>
//   </div>
//
// data-tabs-persist-key-value is optional. When present, the selected tab's
// slug is written to a cookie under that key on every user-initiated switch,
// so the *server* — not this controller — can render the right panel
// un-hidden on the next full page load. See courses/show.html.erb, which
// reads the same cookie key to compute initial_tab_index before this
// controller ever runs. connect() below trusts whatever the server already
// rendered rather than forcing tab 0, so it never fights that server-side
// choice (that's what would reintroduce the flash-of-wrong-tab problem).
export default class extends Controller {
  static targets = ["tab", "panel"];
  static classes = ["active", "inactive"];
  static values = { persistKey: String };

  connect() {
    const alreadyVisible = this.panelTargets.findIndex(
      (panel) => !panel.classList.contains("hidden")
    );
    this.applyState(alreadyVisible === -1 ? 0 : alreadyVisible);
  }

  show(event) {
    const index = Number(event.params.index);
    this.applyState(index);
    this.persist(event.params.slug);
  }

  applyState(index) {
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index);
    });

    this.tabTargets.forEach((tab, i) => {
      const isActive = i === index;

      const activeClasses = (
        this.hasActiveClass
          ? this.activeClass
          : "text-[#1A73E8] border-[#1A73E8]"
      ).split(" ");
      const inactiveClasses = (
        this.hasInactiveClass
          ? this.inactiveClass
          : "text-[#5F6368] border-transparent"
      ).split(" ");

      if (isActive) {
        tab.classList.add(...activeClasses);
        tab.classList.remove(...inactiveClasses);
      } else {
        tab.classList.add(...inactiveClasses);
        tab.classList.remove(...activeClasses);
      }
    });
  }

  persist(slug) {
    if (!slug || !this.hasPersistKeyValue) return;
    const secure = window.location.protocol === "https:" ? "; secure" : "";
    document.cookie = `${this.persistKeyValue}=${slug}; path=/; max-age=31536000; samesite=lax${secure}`;
  }
}
```

---

## 3. Modified: `app/views/courses/show.html.erb`

Adds a `slug` per tab (stable identifier for the cookie — decoupled from array position, so reordering tabs later doesn't break anyone's stored preference), computes `initial_tab_index` server-side from the cookie, and wires `search-shortcut` onto the same element as `tabs`.

```diff
+<%# Cookie is plain/unsigned on purpose: it only ever holds one of the five
+    slugs below, and tabs.find_index ignores anything else, so there is
+    nothing to forge that does more than land the user on Overview. %>
 <%
   tabs = []
-  tabs << { name: "Overview", partial: "courses/overview_tab" }
-  tabs << { name: "To Review", partial: "courses/to_review_tab" }
-  tabs << { name: "Topics", partial: "courses/topic_directory_tab" }
-  tabs << { name: "People", partial: "courses/people_tab" }
-  tabs << { name: "Groups", partial: "courses/groups_tab" }
+  tabs << { name: "Overview", slug: "overview", partial: "courses/overview_tab" }
+  tabs << { name: "To Review", slug: "to_review", partial: "courses/to_review_tab" }
+  tabs << { name: "Topics", slug: "topics", partial: "courses/topic_directory_tab" }
+  tabs << { name: "People", slug: "people", partial: "courses/people_tab" }
+  tabs << { name: "Groups", slug: "groups", partial: "courses/groups_tab" }
+
+  tab_persist_key = "last_tab_course_#{@course.id}"
+  initial_tab_index = tabs.find_index { |t| t[:slug] == cookies[tab_persist_key] } || 0
 %>

 <div class="text-[#3C4043] font-['Roboto',sans-serif]">

   <div class="flex">
     <%= render "shared/sidebar" %>
     <main class="flex-1 bg-white rounded-tl-[28px] min-h-[calc(100vh-3.5rem)]"
-          data-controller="tabs">
+          data-controller="tabs search-shortcut"
+          data-tabs-persist-key-value="<%= tab_persist_key %>">

       <div class="border-b border-[#E0E0E0] px-6 pt-4">
         <div class="flex flex-wrap gap-x-8 gap-y-1">
           <% tabs.each_with_index do |tab, index| %>
-            <button type="button" data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="<%= index %>"
+            <button type="button" data-tabs-target="tab" data-action="tabs#show"
+                    data-tabs-index-param="<%= index %>" data-tabs-slug-param="<%= tab[:slug] %>"
                     style="font-family: 'Google Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500; letter-spacing: 0; line-height: 1.25rem;"
                     class="pb-3 whitespace-nowrap border-b-4 transition-colors"><%= tab[:name] %></button>
           <% end %>
           <%# Settings link unchanged %>
         </div>
       </div>

       <% tabs.each_with_index do |tab, index| %>
-        <div data-tabs-target="panel" class="max-w-5xl mx-auto px-6 py-8<%= index.zero? ? '' : ' hidden' %>">
+        <div data-tabs-target="panel" class="max-w-5xl mx-auto px-6 py-8<%= index == initial_tab_index ? '' : ' hidden' %>">
           <%= render tab[:partial] %>
         </div>
       <% end %>

     </main>
   </div>
 </div>
```

**Why a plain cookie, not `cookies.signed`/`cookies.encrypted`:** the value is non-sensitive UI state and it's written client-side (`document.cookie` in `tabs_controller.js`), which can't produce Rails' signed/encrypted cookie format. `cookies[tab_persist_key]` (Rails' plain jar) is the only option that both sides can read/write, and it's safe here because the lookup falls back to `0` for any value that isn't one of the five known slugs.

---

## 4. Modified: `app/views/courses/_groups_tab.html.erb`

Search input becomes the shortcut's fallback target, plus the kbd badge. `pr-4` → `pr-9` to leave room for the badge.

```diff
         <div class="relative flex items-center flex-1 md:w-[240px]">
           <span class="material-symbols-outlined absolute left-3 text-gray-400 text-[18px]">search</span>
           <input type="text" id="groups-search" name="search_query" value="<%= params[:search_query] %>"
                  placeholder="Search groups or students..."
-                 class="bg-gray-50 border border-gray-200 text-gray-700 text-sm rounded-md focus:bg-white focus:ring-2 focus:ring-[#1A73E8] focus:border-transparent block w-full pl-9 pr-4 py-2 transition-all outline-none"
+                 data-search-shortcut-target="input fallbackInput"
+                 class="peer bg-gray-50 border border-gray-200 text-gray-700 text-sm rounded-md focus:bg-white focus:ring-2 focus:ring-[#1A73E8] focus:border-transparent block w-full pl-9 pr-9 py-2 transition-all outline-none"
                  hx-get="<%= course_url(@course) %>"
                  hx-target="#groups-table-container"
                  hx-swap="outerHTML"
                  hx-trigger="input changed delay:300ms"
                  hx-include="#groups-search, #groups-status-filter, #lecturer-filter"
                  hx-vals='{"section": "groups"}'
                  hx-indicator="#groups-loading">
+          <kbd aria-hidden="true"
+               class="hidden md:flex peer-focus:hidden absolute right-3 top-1/2 -translate-y-1/2 items-center justify-center h-5 min-w-[1.25rem] px-1 rounded border border-[#E0E0E0] bg-gray-50 text-[11px] font-mono text-gray-400 pointer-events-none select-none">/</kbd>
         </div>
```

`fallbackInput` is on this input specifically (not People's) because Groups is the confirmed fallback destination.

---

## 5. Modified: `app/views/courses/_students_section.html.erb`

Same pattern, `input` target only (this one is never the `/`-with-no-tab-context fallback, only People's own in-tab target).

```diff
       <div class="relative flex items-center flex-1 md:w-[240px]">
         <span class="material-symbols-outlined absolute left-3 text-gray-400 text-[18px]">search</span>
         <input type="text" id="students-search" name="search_query" value="<%= params[:search_query] %>"
                placeholder="Search students..."
-               class="bg-gray-50 border border-gray-200 text-gray-700 text-sm rounded-md focus:bg-white focus:ring-2 focus:ring-[#1A73E8] focus:border-transparent block w-full pl-9 pr-4 py-2 transition-all outline-none"
+               data-search-shortcut-target="input"
+               class="peer bg-gray-50 border border-gray-200 text-gray-700 text-sm rounded-md focus:bg-white focus:ring-2 focus:ring-[#1A73E8] focus:border-transparent block w-full pl-9 pr-9 py-2 transition-all outline-none"
                hx-get="<%= course_url(course) %>"
                hx-target="#students-table-container"
                hx-swap="outerHTML"
                hx-trigger="input changed delay:300ms"
                hx-include="#students-search"
                hx-vals='{"section": "students"}'
                hx-indicator="#students-loading">
+        <kbd aria-hidden="true"
+             class="hidden md:flex peer-focus:hidden absolute right-3 top-1/2 -translate-y-1/2 items-center justify-center h-5 min-w-[1.25rem] px-1 rounded border border-[#E0E0E0] bg-gray-50 text-[11px] font-mono text-gray-400 pointer-events-none select-none">/</kbd>
       </div>
```

---

## Naming reference

| Thing | Name |
|---|---|
| New Stimulus controller file | `app/javascript/controllers/search_shortcut_controller.js` |
| Stimulus identifier (auto, from filename) | `search-shortcut` |
| Stimulus targets on that controller | `input`, `fallbackInput` |
| Data attribute on search boxes (People) | `data-search-shortcut-target="input"` |
| Data attribute on search box (Groups) | `data-search-shortcut-target="input fallbackInput"` |
| New Stimulus value on `tabs_controller.js` | `persistKey` (`data-tabs-persist-key-value`) |
| New param on tab buttons | `data-tabs-slug-param` |
| Tab slugs | `overview`, `to_review`, `topics`, `people`, `groups` |
| Cookie name | `last_tab_course_<course id>` (e.g. `last_tab_course_42`) |
| Cookie attributes | `path=/; max-age=31536000; samesite=lax` (+ `secure` when served over https) |
| Kbd badge element | `<kbd aria-hidden="true">/</kbd>`, classes `hidden md:flex peer-focus:hidden ...` |

---

## Manual test checklist

- [ ] On Groups tab, press `/` → focuses `#groups-search` (no page jump, cursor lands in the box).
- [ ] On People tab, press `/` → focuses `#students-search`.
- [ ] On Overview / To Review / Topics, press `/` → switches to Groups tab and focuses `#groups-search`.
- [ ] Type `/` inside any text input, textarea, or the lecturer/status `<select>` → shortcut does nothing, character types normally (where applicable).
- [ ] Open the "Add Students" modal (`<dialog>`), press `/` → nothing happens while the dialog is open.
- [ ] Click into Groups or People tab, click Groups tab from Overview via `/`, refresh the page (no `?tab=` in URL) → page loads with Groups already visible, no visible flash of Overview first.
- [ ] Switch tabs manually a few times, clear cookies, reload → falls back to Overview (index 0), doesn't error.
- [ ] Cookie is scoped per course: switch to Groups on Course A, visit Course B → Course B still opens on Overview (or whatever B's own cookie says).
- [ ] On a narrow/mobile viewport: kbd badge is not visible in either search box (it's `hidden` below `md`); focusing the input still works normally via tap.
- [ ] Focus a search input on desktop → kbd badge disappears; blur → badge reappears.