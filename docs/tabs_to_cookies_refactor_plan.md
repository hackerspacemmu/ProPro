# Implementation plan: Cookie-based tab persistence (replace `?tab=` URL params)

**Repo:** `hackerspacemmu/ProPro`, branch `refactor/design`
**Prerequisite:** `docs/shortcut_group_search_plan.md` (the `/` search shortcut + last-tab cookie plan). This plan refactors the tab persistence layer that plan depends on — implement this plan first, then the search shortcut plan stacks on top.

## Decision summary

| Decision | Choice | Rationale |
|---|---|---|
| Persistence mechanism | **Cookie only** | Standard for tab UI state. Removes URL pollution, simplifies `replaceState` removal, no more stale `?tab=` in shared links. |
| Cookie naming | `propro_tab_<context>_<id>` | Namespaced, unambiguous. E.g. `propro_tab_course_42`, `propro_tab_project_99`. |
| `mobile_tabs_controller` | **Out of scope** | Legacy controller used only by `topics/show.html.erb`. Separate refactor later. |
| `current_tab` helpers | **Remove** | Unused in current views. Dead code. |
| Server redirects (`tab: 'progress'`) | **Remove** | Progress update redirects drop `tab:` param. User lands on project root; cookie or default handles tab. |

---

## Scope

1. `tabs_controller.js`: Replace `?tab=` URL read/write with cookie read/write via a new `persistKey` value.
2. `courses/show.html.erb`: Read cookie server-side to compute initial active tab; wire `persistKey`.
3. `projects/show.html.erb` + `_project_header.html.erb`: Add `key-param` to tab buttons (currently missing); read cookie server-side; wire `persistKey`.
4. `progress_updates_controller.rb`: Remove `tab: 'progress'` from all redirects.
5. `progress_updates/show.html.erb` + `edit.html.erb`: Remove `tab: "progress"` from "Back to Project" links.
6. `projects_helper.rb` + `topics_helper.rb`: Remove unused `current_tab` methods.

**Explicitly out of scope:** `mobile_tabs_controller.js` (topics/show), `tab_fade_controller.js` (no changes needed), collapsible sections, Overview layout, search shortcut controller (separate plan).

---

## 1. Modified: `app/javascript/controllers/tabs_controller.js`

Full replacement. Key changes:
- Remove `activeIndexValue` — server renders the correct initial state; `connect()` trusts it.
- Remove all `?tab=` URL read/write (`searchParams`, `replaceState`).
- Add `persistKey` value (String, optional). When present, `show()` writes selected tab's slug to a cookie.
- `connect()` reads whichever panel the server already left un-hidden (no forced index 0).
- `setActive` renamed to `applyState` to match the search shortcut plan's convention.

```js
import { Controller } from "@hotwired/stimulus";

// Generic tab controller — deliberately NOT mobile_tabs_controller.js,
// which is hard-coded to 3 named targets for the topic show page
// and out of scope for this work.
//
// Usage:
//   <div data-controller="tabs"
//        data-tabs-persist-key-value="propro_tab_course_42"
//        data-tabs-active-class="..."
//        data-tabs-inactive-class="...">
//     <button data-tabs-target="tab" data-action="tabs#show"
//             data-tabs-index-param="0" data-tabs-slug-param="overview">...</button>
//     <button ... index-param="1" slug-param="topics">...</button>
//     <div data-tabs-target="panel">...</div>
//     <div data-tabs-target="panel">...</div>
//   </div>
//
// data-tabs-persist-key-value is optional. When present, the selected tab's
// slug is written to a plain cookie under that key on every user-initiated
// switch, so the *server* can render the right panel un-hidden on the next
// full page load. connect() trusts whatever the server already rendered
// rather than forcing tab 0, so it never fights that server-side choice
// (that's what would reintroduce the flash-of-wrong-tab problem).
//
// The "Settings" entry in the tab bar is a plain link_to (real navigation to
// a separate page), not a data-tabs-target="tab" — it doesn't participate in
// this controller at all.
export default class extends Controller {
  static targets = ["tab", "panel"];
  static classes = ["active", "inactive"];
  static values = { persistKey: String };

  connect() {
    const alreadyVisible = this.panelTargets.findIndex(
      (panel) => !panel.classList.contains("hidden"),
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

      tab.setAttribute("aria-selected", isActive);
      tab.setAttribute("tabindex", isActive ? "0" : "-1");
    });
  }

  persist(slug) {
    if (!slug || !this.hasPersistKeyValue) return;
    const secure = window.location.protocol === "https:" ? "; secure" : "";
    document.cookie =
      `${this.persistKeyValue}=${slug}; path=/; max-age=31536000; samesite=lax${secure}`;
  }
}
```

### What changed vs current

| Current | New |
|---|---|
| `static values = { activeIndex: { type: Number, default: 0 } }` | `static values = { persistKey: String }` |
| `connect()` reads `?tab=` from URL, falls back to `activeIndexValue` | `connect()` finds first un-hidden panel, falls back to 0 |
| `show()` calls `setActive()` + `replaceState` with `?tab=key` | `show()` calls `applyState()` + `persist(slug)` |
| `setActive(index)` method | `applyState(index)` method (logic identical) |
| No cookie code | `persist(slug)` writes plain cookie when `persistKey` is set |

---

## 2. Modified: `app/views/courses/show.html.erb`

Adds `slug` per tab (stable identifier decoupled from array position), computes `initial_tab_index` server-side from the cookie, wires `persistKey`. Removes all `?tab=` URL reading.

```erb
<% content_for :body_class, "bg-[#f8fafd]" %>

<% breadcrumb :course, @course %>

<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>

<%# Cookie is plain/unsigned on purpose: it only ever holds one of the four
    slugs below, and tabs.find_index ignores anything else, so there is
    nothing to forge that does more than land the user on Overview. %>
<%
  tabs = []
  tabs << { slug: "overview", name: "Overview", partial: "courses/overview_tab" }
  tabs << { slug: "topics",   name: "Topics",   partial: "courses/topic_directory_tab" }
  tabs << { slug: "people",   name: "People",   partial: "courses/people_tab" }
  tabs << { slug: "groups",   name: "Groups",   partial: "courses/groups_tab" }

  tab_persist_key = "propro_tab_course_#{@course.id}"
  initial_tab_index = tabs.find_index { |t| t[:slug] == cookies[tab_persist_key] } || 0
%>

<div class="text-[#3C4043] font-['Roboto',sans-serif]">

  <div class="flex">
    <%= render "shared/sidebar" %>
    <main class="flex-1 bg-white rounded-tl-[28px] overflow-hidden min-h-[calc(100vh-3.5rem)]"
          data-controller="tabs"
          data-tabs-persist-key-value="<%= tab_persist_key %>"
          data-tabs-active-class="text-[#0B57D0]"
          data-tabs-inactive-class="text-[#1F1F1F] hover:bg-[#F8F9FA]">

      <div class="border-b border-[#E0E0E0] px-4 sm:px-8 bg-white shrink-0">
        <div class="flex items-center justify-between">
          <div role="tablist" class="flex flex-nowrap gap-y-1">
            <% tabs.each_with_index do |tab, index| %>
              <% selected = index == initial_tab_index %>
              <button type="button"
                      id="tab-<%= tab[:slug] %>"
                      role="tab"
                      aria-selected="<%= selected %>"
                      aria-controls="panel-<%= tab[:slug] %>"
                      tabindex="<%= selected ? 0 : -1 %>"
                      data-tabs-target="tab"
                      data-action="tabs#show"
                      data-tabs-index-param="<%= index %>"
                      data-tabs-slug-param="<%= tab[:slug] %>"
                      style="font-family: 'Google Sans', Roboto, Arial, sans-serif; font-size: .875rem; font-weight: 500;"
                      class="group h-[3rem] pt-[0.125rem] px-3 sm:px-6 flex items-center justify-center relative box-border whitespace-nowrap <%= selected ? 'text-[#0B57D0]' : 'text-[#1F1F1F] hover:bg-[#F8F9FA]' %>"><%= tab[:name] %><div class="absolute bottom-0 left-0 w-full h-[3px] rounded-t-[3px] transition-colors bg-transparent group-aria-selected:bg-[#0B57D0]"></div></button>
            <% end %>
          </div>

          <% if @current_user_enrolment&.coordinator? %>
            <%= link_to settings_course_path(@course),
                  class: "hidden lg:flex h-[3rem] w-[3rem] items-center justify-center rounded-full text-[#5F6368] hover:bg-[#F1F3F4] transition-colors shrink-0",
                  title: "Settings" do %>
              <span class="material-symbols-outlined">settings</span>
            <% end %>
          <% end %>
        </div>
      </div>

      <% tabs.each_with_index do |tab, index| %>
        <div id="panel-<%= tab[:slug] %>"
             role="tabpanel"
             aria-labelledby="tab-<%= tab[:slug] %>"
             data-tabs-target="panel"
             class="max-w-5xl mx-auto px-6 py-8<%= index == initial_tab_index ? '' : ' hidden' %>">
          <%= render tab[:partial] %>
        </div>
      <% end %>

    </main>
  </div>
</div>
```

### What changed vs current

| Current | New |
|---|---|
| Tabs array has `key:` | Tabs array has `slug:` (renamed for consistency) |
| `active_key` reads `params[:tab]` | `initial_tab_index` reads `cookies[tab_persist_key]` |
| `data-tabs-active-index-value="<%= active_index %>"` | Removed — `connect()` reads from DOM |
| `data-tabs-key-param="<%= tab[:key] %>"` | `data-tabs-slug-param="<%= tab[:slug] %>"` |
| No `data-tabs-persist-key-value` | `data-tabs-persist-key-value="<%= tab_persist_key %>"` |
| `id="tab-<%= tab[:key] %>"` / `aria-controls="panel-<%= tab[:key] %>"` | `id="tab-<%= tab[:slug] %>"` / `aria-controls="panel-<%= tab[:slug] %>"` |

---

## 3. Modified: `app/views/projects/_project_header.html.erb`

Add `data-tabs-slug-param` to each tab button (currently missing — this is why projects never had URL persistence). Add `aria-selected` attributes for accessibility.

Only the tab buttons section changes (lines 49-59):

```erb
<%# Sticky Tabs %>
<div class="border-b border-[#E0E0E0] px-8 sticky top-0 bg-[#FFFFFF] z-10 pt-6">
  <div class="flex items-center gap-3">
    <div class="relative flex-1 min-w-0" data-controller="tab-fade">
      <div
        data-testid="content-tabs"
        data-tab-fade-target="scroller"
        class="flex gap-6 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden [-webkit-overflow-scrolling:touch]"
      >
        <button type="button" data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="0" data-tabs-slug-param="details" class="pb-3 text-[#1A73E8] border-b-[3px] border-[#1A73E8] text-[14px] font-medium whitespace-nowrap">
          Project Details
        </button>
        <button type="button" data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="1" data-tabs-slug-param="compare" class="pb-3 text-[#5F6368] hover:text-[#3C4043] border-b-[3px] border-transparent text-[14px] font-medium transition-colors whitespace-nowrap">
          Compare Versions
        </button>
        <% if course.use_progress_updates %>
          <button type="button" data-tabs-target="tab" data-action="tabs#show" data-tabs-index-param="2" data-tabs-slug-param="progress" class="pb-3 text-[#5F6368] hover:text-[#3C4043] border-b-[3px] border-transparent text-[14px] font-medium transition-colors whitespace-nowrap">
            Progress Updates
          </button>
        <% end %>
      </div>

      <%# Trailing-edge fade: only shown while the strip actually overflows %>
      <div
        data-tab-fade-target="rightMask"
        class="hidden pointer-events-none absolute inset-y-0 right-0 w-8 bg-gradient-to-l from-[#FFFFFF] to-transparent"
      ></div>
    </div>

    <%# Comments trigger — opens the comments drawer below the desktop breakpoint %>
    <button
      type="button"
      data-comments-drawer-target="trigger"
      data-action="comments-drawer#toggle"
      aria-expanded="false"
      aria-controls="comments-drawer"
      title="Comments"
      class="min-[1245px]:hidden shrink-0 relative w-9 h-9 flex items-center justify-center rounded-full text-[#5F6368] hover:text-[#3C4043] hover:bg-[#F1F3F4] transition-colors"
    >
      <span class="material-symbols-outlined text-[20px]">chat_bubble</span>
      <% if comments_count.positive? %>
        <span
          class="absolute -top-0.5 -right-0.5 min-w-4 h-4 px-1 rounded-full bg-[#1A73E8] text-white text-[10px] font-medium leading-4 flex items-center justify-center"
        ><%= comments_count %></span>
      <% end %>
    </button>
  </div>
</div>
```

### What changed vs current

| Current | New |
|---|---|
| `data-tabs-index-param="0"` (no slug) | `data-tabs-index-param="0" data-tabs-slug-param="details"` |
| `data-tabs-index-param="1"` (no slug) | `data-tabs-index-param="1" data-tabs-slug-param="compare"` |
| `data-tabs-index-param="2"` (no slug) | `data-tabs-index-param="2" data-tabs-slug-param="progress"` |

---

## 4. Modified: `app/views/projects/show.html.erb`

Add `data-tabs-persist-key-value` to the `<main>` element so the tabs controller knows which cookie to write. Compute `initial_tab_index` from cookie server-side to set correct initial `hidden` class on panels.

```erb
<% content_for :body_class, "bg-[#f8fafd]" %>
<% breadcrumb :project, @project %>

<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>

<% content_for :title do %>
  <%= @project.current_title.truncate(TITLE_NAME_LIMIT) %>
  - View
  <%= @project.current_instance.approved? ? "Project" : "Proposal" %>
  | ProPro
<% end %>

<%
  project_tab_slugs = ["details", "compare"]
  project_tab_slugs << "progress" if @course.use_progress_updates
  project_tab_persist_key = "propro_tab_project_#{@project.id}"
  project_initial_tab = project_tab_slugs.index(cookies[project_tab_persist_key]) || 0
%>

<div class="text-[#3C4043] font-['Roboto',sans-serif]">
  <div class="flex">
    <%= render "shared/sidebar" %>

    <main
      class="flex-1 bg-[#FFFFFF] rounded-tl-[16px] flex overflow-hidden min-h-[calc(100vh-3.5rem)]"
      data-controller="tabs comments-drawer"
      data-tabs-persist-key-value="<%= project_tab_persist_key %>"
      data-action="keydown.esc@window->comments-drawer#closeOnEscape"
    >

      <%# ===== LEFT PANE ===== %>
      <div class="flex-1 flex flex-col overflow-y-auto overflow-x-hidden relative border-r border-[#E0E0E0]">

        <%= render "project_header",
        current_instance: @current_instance,
        project: @project,
        course: @course,
        current_version: @current_version,
        latest_version: @latest_version,
        instances: @instances,
        current_user: current_user,
        members: @members,
        comments_count: @comments.size %>

        <%# Content Panels %>
        <div class="p-8 max-w-5xl space-y-6 pb-28 min-[1245px]:pb-8">

          <%# Panel 1: Project Details %>
          <div data-tabs-target="panel" class="space-y-6<%= project_initial_tab != 0 ? ' hidden' : '' %>">
            <%= render "project_overview",
            project: @project,
            course: @course,
            current_instance: @current_instance %>

            <%= render "project_details",
            fields: @current_fields,
            next_fields: @next_fields,
            based_on_topic_name:
              @current_instance&.source_topic&.topic_instances&.last&.title || nil,
            index: @index,
            instances: @instances %>

          </div>

          <%# Panel 2: Compare Versions %>
          <div data-tabs-target="panel" class="space-y-6<%= project_initial_tab != 1 ? ' hidden' : '' %>">
            <%= render "compare_versions_tab",
            fields: @current_fields,
            next_fields: @next_fields,
            index: @index,
            instances: @instances %>
          </div>

          <%# Panel 3: Progress Updates (conditional) %>
          <% if @course.use_progress_updates %>
            <div
              data-tabs-target="panel"
              class="<%= project_initial_tab != 2 ? 'hidden' : '' %>"
              data-controller="record-update-modal"
            >
              <%= render "progress_updates",
              progress: @progress,
              project: @project,
              current_version: @current_version,
              latest_version: @latest_version,
              course: @course,
              weeks: @weeks,
              can_record_progress_update: policy(@project).can_record_progress_update? %>

              <%= render "record_update_modal", course: @course, project: @project %>
            </div>
          <% end %>

        </div>

      </div>

      <%# ===== RIGHT PANE: review desktop-only, comments drawer ===== %>
      <div
        id="comments-drawer"
        data-comments-drawer-target="panel"
        role="region"
        aria-label="Comments"
        class="
          fixed top-0 right-0 bottom-0 z-50 w-[360px] max-w-[90vw] bg-[#FFFFFF] p-6
          flex flex-col gap-6 overflow-y-auto shrink-0
          translate-x-full transition-transform duration-300 ease-out
          min-[1245px]:static min-[1245px]:translate-x-0 min-[1245px]:shadow-none
          min-[1245px]:transition-none min-[1245px]:border-l-0
        "
      >
        <%= render "project_review_card",
        project: @project,
        course: @course,
        current_version: @current_version,
        latest_version: @latest_version,
        instances: @instances,
        members: @members %>

        <div
          class="
            w-full self-start
            h-[600px] min-[1245px]:h-[700px]
            min-[1245px]:sticky min-[1245px]:top-6
            min-[1245px]:max-h-[calc(100vh-3rem)]
          "
        >
          <%= render "project_comments",
          comments: @comments,
          new_comment: @new_comment,
          course: @course,
          project: @project,
          current_instance_id: @current_instance.id,
          current_version: @current_version,
          latest_version: @latest_version %>
        </div>
      </div>

      <div
        data-comments-drawer-target="backdrop"
        data-action="click->comments-drawer#close"
        class="hidden fixed inset-0 bg-black/40 z-40 min-[1245px]:hidden"
      ></div>

    </main>
  </div>

  <%= render "review_action_bar",
  project: @project,
  course: @course,
  current_version: @current_version,
  latest_version: @latest_version,
  instances: @instances,
  members: @members %>
</div>
```

### What changed vs current

| Current | New |
|---|---|
| No `data-tabs-persist-key-value` on `<main>` | `data-tabs-persist-key-value="<%= project_tab_persist_key %>"` |
| Panel 1 always visible, others always `hidden` | Initial `hidden` class driven by `project_initial_tab` |
| No cookie computation in template | `project_tab_slugs`, `project_tab_persist_key`, `project_initial_tab` computed at top |

---

## 5. Modified: `app/controllers/progress_updates_controller.rb`

Remove `tab: 'progress'` from all redirects (lines 33, 39, 48). The cookie handles persistence; user lands on the project page and the correct tab renders from cookie.

```ruby
class ProgressUpdatesController < ApplicationController
  before_action :access
  before_action :supervisor_access, except: [:show]

  def show
    @progress_update = ProgressUpdate.find(params[:id])
  end

  def new
    @progress_update = ProgressUpdate.new
    @weeks = @course.number_of_updates
  end

  def edit
    @progress_update = ProgressUpdate.find(params[:id])
  end

  def create
    begin
      ActiveRecord::Base.transaction do
        @progress_update = ProgressUpdate.create!(
          project: @project,
          rating: params[:progress_update][:rating],
          feedback: params[:progress_update][:feedback],
          date: params[:progress_update][:date]
        )
      end
    rescue StandardError
      render :new, status: :unprocessable_entity
      return
    end

    redirect_to course_project_path(@course, @project)
  end

  def update
    @progress_update = ProgressUpdate.find(params[:id])
    if @progress_update.update(params.require(:progress_update).permit(:rating, :feedback, :date))
      redirect_to course_project_path(@course, @project)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @progress_update = ProgressUpdate.find(params[:id])
    @progress_update.destroy
    redirect_to course_project_path(@course, @project), notice: 'Progress update deleted successfully.'
  end

  private

  def access
    @course = Course.find(params[:course_id])
    @project = @course.projects.find(params[:project_id])
    @instances = @project.project_instances.order(version: :asc)
    @index = @instances.size
    @current_instance = @instances[@index - 1]
  end

  def supervisor_access
    return unless @current_instance.supervisor != current_user

    redirect_to(course_project_path(@course, @project), alert: 'You are not authorized')
  end
end
```

### What changed vs current

| Lines | Current | New |
|---|---|---|
| 33 | `redirect_to course_project_path(@course, @project, tab: 'progress')` | `redirect_to course_project_path(@course, @project)` |
| 39 | `redirect_to course_project_path(@course, @project, tab: 'progress')` | `redirect_to course_project_path(@course, @project)` |
| 48 | `redirect_to course_project_path(@course, @project, tab: 'progress'), ...` | `redirect_to course_project_path(@course, @project), ...` |

---

## 6. Modified: `app/views/progress_updates/show.html.erb`

Remove `tab: "progress"` from the "Back to Project" link (line 13).

```diff
-      <%= link_to course_project_path(@course, @project, tab: "progress", anchor: "project-progress"), class: "group inline-flex items-center text-sm font-medium text-gray-500 hover:text-blue-600 transition-colors mb-6" do %>
+      <%= link_to course_project_path(@course, @project), class: "group inline-flex items-center text-sm font-medium text-gray-500 hover:text-blue-600 transition-colors mb-6" do %>
```

---

## 7. Modified: `app/views/progress_updates/edit.html.erb`

Remove `tab: "progress"` from both the "Back to Progress List" link (line 14) and the "Cancel" link (lines 117-122).

```diff
-      <%= link_to course_project_path(@course, @project, tab: "progress", anchor: "project-progress"), class: "group inline-flex items-center text-sm font-medium text-gray-500 hover:text-green-600 transition-colors mb-4" do %>
+      <%= link_to course_project_path(@course, @project), class: "group inline-flex items-center text-sm font-medium text-gray-500 hover:text-green-600 transition-colors mb-4" do %>
```

```diff
            <%= link_to "Cancel",
-            course_project_path(
-              @course,
-              @project,
-              tab: "progress",
-              anchor: "project-progress",
-            ),
+            course_project_path(@course, @project),
            class:
              "w-full sm:w-auto text-center text-sm font-bold text-gray-500 hover:text-gray-800 px-6 py-3 rounded-xl hover:bg-gray-100 transition-colors" %>
```

---

## 8. Modified: `app/helpers/projects_helper.rb`

Remove the unused `current_tab` method.

```ruby
module ProjectsHelper
  def show_progress_tab?
    @course.use_progress_updates && @current_instance.status == 'approved'
  end

  def name(user_id)
    return nil unless user_id.present?

    User.find_by(id: user_id)&.name
  end
end
```

### What changed vs current

| Current | New |
|---|---|
| `def current_tab` method (lines 2-4) | Removed |

---

## 9. Modified: `app/helpers/topics_helper.rb`

Remove the unused `current_tab` method.

```ruby
module TopicsHelper
  def show_progress_tab?
    @course.use_progress_updates && @current_instance.status == 'approved'
  end
end
```

### What changed vs current

| Current | New |
|---|---|
| `def current_tab` method (lines 2-4) | Removed |

---

## Naming reference

| Thing | Name |
|---|---|
| Stimulus controller file | `app/javascript/controllers/tabs_controller.js` |
| Stimulus identifier (auto) | `tabs` |
| New Stimulus value | `persistKey` (`data-tabs-persist-key-value`) |
| Tab slug param (data attr) | `data-tabs-slug-param` |
| Course tab slugs | `overview`, `topics`, `people`, `groups` |
| Project tab slugs | `details`, `compare`, `progress` |
| Course cookie name | `propro_tab_course_<id>` (e.g. `propro_tab_course_42`) |
| Project cookie name | `propro_tab_project_<id>` (e.g. `propro_tab_project_99`) |
| Cookie attributes | `path=/; max-age=31536000; samesite=lax` (+ `secure` when https) |
| Server-side cookie read | `cookies[tab_persist_key]` (Rails plain jar — unsigned, intentionally) |

---

## Why a plain cookie, not `cookies.signed`/`cookies.encrypted`

The value is non-sensitive UI state (one of 3-4 known tab slugs) and it's written client-side (`document.cookie` in `tabs_controller.js`), which can't produce Rails' signed/encrypted cookie format. `cookies[key]` (Rails' plain jar) is the only option that both sides can read/write, and it's safe here because the lookup falls back to index 0 for any value that isn't one of the known slugs.

---

## File change summary

| File | Action | Scope |
|---|---|---|
| `app/javascript/controllers/tabs_controller.js` | Rewrite | Core refactor |
| `app/views/courses/show.html.erb` | Modify | Cookie read + slug wiring |
| `app/views/projects/_project_header.html.erb` | Modify | Add slug params to buttons |
| `app/views/projects/show.html.erb` | Modify | Cookie read + persistKey |
| `app/controllers/progress_updates_controller.rb` | Modify | Remove `tab:` from 3 redirects |
| `app/views/progress_updates/show.html.erb` | Modify | Remove `tab:` from 1 link |
| `app/views/progress_updates/edit.html.erb` | Modify | Remove `tab:` from 2 links |
| `app/helpers/projects_helper.rb` | Modify | Remove `current_tab` |
| `app/helpers/topics_helper.rb` | Modify | Remove `current_tab` |

**Total: 9 files** (1 rewrite, 8 edits)

---

## Manual test checklist

### courses/show

- [ ] Visit a course → defaults to Overview tab (no cookie set yet).
- [ ] Click "People" tab → cookie `propro_tab_course_<id>` set to `people`. Refresh → page loads with People tab active, no flash of Overview.
- [ ] Click "Groups" tab → cookie updates to `groups`. Navigate to another course → that course still opens on its own default/cookie.
- [ ] Clear cookies → course defaults back to Overview (index 0).
- [ ] No `?tab=` in the URL at any point.

### projects/show

- [ ] Visit a project → defaults to "Project Details" tab.
- [ ] Click "Compare Versions" → cookie `propro_tab_project_<id>` set to `compare`. Refresh → loads on Compare Versions.
- [ ] Project with progress updates enabled: click "Progress Updates" → cookie set to `progress`. Refresh → loads on Progress Updates.
- [ ] Clear cookies → defaults back to "Project Details" (index 0).
- [ ] No `?tab=` in the URL at any point.

### progress_updates flow

- [ ] Create a progress update → redirects to project page (no `?tab=` in URL). Cookie still on `progress` → tab renders correctly.
- [ ] Edit a progress update → "Cancel" and "Back" links go to project page (no `?tab=`).
- [ ] Delete a progress update → redirects to project page (no `?tab=`).

### Edge cases

- [ ] Cookie value is garbage/unknown → falls back to tab 0 (Overview / Project Details).
- [ ] Multiple browser tabs open → each tab switch updates cookie; other tabs unaffected until refresh.
- [ ] Cookie scoped per resource: course cookie doesn't affect project cookie and vice versa.
