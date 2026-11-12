# Group formation code dump (single file) — FIXED

Generated 2026-10-31 on branch `feat/student-grouping-crud` from the "Group formation: styling fix spec" (31 Oct 2026), the hardcoded mockup (`COMP6000 - Group formation | ProPro`) and the migration plan. Where the spec and the plan disagree, the spec wins (spec §2).

Purpose: the post-fix state of the UI-facing grouping implementation, in the same shape as the previous dump, so a gap-review agent can diff it against the mockup.

How to read this file:

- **Section 1** is the formation page with every formation partial, dialog and shared component inlined between `BEGIN` / `END` banners. A partial's full body is printed at its **first** use. Later uses show a one-line banner (`INLINED AGAIN`) with that call's locals. The body is identical to the first one.
- **Section 2** is the lazy Manage frame (`groups/edit.html.erb`).
- **Section 3** is the JavaScript that changed. **Section 4** is the Ruby that changed, plus the one-line layout edit.
- **Section 5** is a file index (path, strict locals, call sites, status) in place of reprinting every raw partial. Each partial's raw source is the text between its banners in sections 1 and 2.
- **Section 6** lists deviations from the spec, open items, files to delete and verification commands.
- Files not listed as changed are **byte-identical to the previous dump** (§3 and §4 list them).

Rules held throughout (spec §0): no `gray-*`, `blue-*`, `amber-*`, `red-*`, `green-*`, no hex, no `<style>`, no inline JS, no new routes or services. User-facing copy says "coordinator" or "lecturer", never "staff". Every dialog is a native `<dialog>` with `p-0` and an inner flex column.

---

## 1. Fully inlined formation page (`group_formations/show.html.erb`)

`render "courses/tab_shell"` and `render "courses/flash"` stay as renders. They are app chrome and are **not edited** (spec §1: the page follows the shell's padding, so only vertical margins are used inside the page).

```erb
<% content_for :no_footer, true %>

<%= render "courses/tab_shell",
           course: @course,
           active: "group-formation",
           current_user_enrolment: @current_user_enrolment,
           breadcrumb: :group_formation,
           tabs: [{ slug: "group-formation", name: "Group formation", path: course_group_formation_path(@course) }] do %>

  <div id="flash">
    <%= render "courses/flash" %>
  </div>

  <%
    is_student = @current_user_enrolment&.student?
    formation_open = @course.group_formation_open?
    manage = policy(@course).manage_groups?
    my_group = @my_group
    leads_my_group = my_group.present? && my_group.leader_id == current_user.id
    join_requests = leads_my_group ? @incoming_join_requests.to_a : []
    direct_invites = my_group.nil? ? @incoming_direct_invites.to_a : []
    notification_count = join_requests.size + direct_invites.size
    all_groups = @groups.to_a
    confirmed_count = all_groups.count(&:confirmed?)
    invalid_count = all_groups.count { |group| group_size_state(group, @course) != :ok }
    can_create = is_student && my_group.nil? && policy(ProjectGroup.new(course: @course)).create?
  %>

  <%# ===== Bell (rendered into shared/_header via the :header_actions slot) ===== %>
  <% if is_student && formation_open %>
    <% content_for :header_actions do %>
      <div class="relative" data-controller="dropdown" data-action="keydown.esc@window->dropdown#close">
        <button type="button"
                data-action="click->dropdown#toggle"
                aria-label="Notifications"
                class="relative flex h-11 w-11 items-center justify-center rounded-full text-on-surface-variant transition-colors hover:bg-surface-variant sm:h-10 sm:w-10">
          <span class="material-symbols-outlined">notifications</span>
          <% if notification_count.positive? %>
            <span class="absolute right-1 top-1 inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-error px-1 text-[11px] font-medium text-white"><%= notification_count %></span>
          <% end %>
        </button>

        <div data-dropdown-target="menu"
             class="fixed inset-x-2 top-[calc(var(--spacing-header)+4px)] z-50 hidden max-h-[70vh] overflow-y-auto rounded-lg border border-outline-variant bg-surface shadow-lg sm:absolute sm:inset-x-auto sm:right-0 sm:top-12 sm:max-h-[80vh] sm:w-[340px]">
          <div class="border-b border-outline-variant px-4 py-3 font-['DM_Sans'] text-[15px] font-medium text-on-surface-strong">Notifications</div>

          <% join_requests.each do |invite| %>
            <%# ===== BEGIN inlined group_formations/notification | locals: avatar_name: invite.sender.name,
                       name: invite.sender.name,
                       action: "asked to join your group",
                       accept_url: course_group_join_request_path(@course, invite.project_group, invite),
                       decline_url: course_group_join_request_path(@course, invite.project_group, invite) ===== %>
<%# locals: (avatar_name:, name:, action:, subtitle: nil, accept_url:, decline_url:) %>
<div class="border-b border-outline-variant px-4 py-3 last:border-0">
  <div class="flex items-start gap-3">
    <span class="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-surface-variant-deep text-[11px] font-medium text-on-surface" aria-hidden="true"><%= avatar_name.to_s.first.to_s.upcase %></span>
    <div class="min-w-0">
      <p class="text-sm text-on-surface-strong"><span class="font-medium"><%= name %></span> <%= action %></p>
      <% if subtitle.present? %>
        <p class="text-[13px] text-on-surface-muted"><%= subtitle %></p>
      <% end %>
    </div>
  </div>
  <div class="mt-2 flex gap-2 pl-10">
    <%= button_to "Accept", accept_url, method: :patch, params: { status: "accepted" }, form: { class: "inline-flex" }, class: GroupFormationsHelper::GROUP_SMALL_BUTTON %>
    <%= button_to "Decline", decline_url, method: :patch, params: { status: "declined" }, form: { class: "inline-flex" }, class: GroupFormationsHelper::GROUP_TEXT_SMALL_BUTTON %>
  </div>
</div>
<%# ===== END inlined group_formations/notification ===== %>
          <% end %>

          <% direct_invites.each do |invite| %>
            <%# ===== INLINED AGAIN group_formations/notification (body identical to above) | locals: avatar_name: invite.sender.name,
                       name: invite.project_group.group_name.presence || "A group",
                       action: "invited you to join",
                       subtitle: "Invited by #{invite.sender.name}",
                       accept_url: course_group_invitation_path(@course, invite.project_group, invite),
                       decline_url: course_group_invitation_path(@course, invite.project_group, invite) ===== %>
          <% end %>

          <% if notification_count.zero? %>
            <p class="px-4 py-6 text-sm text-on-surface-muted">No new notifications.</p>
          <% end %>
        </div>
      </div>
    <% end %>
  <% end %>

  <%# ===== Page header ===== %>
  <div class="mb-5 flex flex-wrap items-start justify-between gap-4 sm:mb-6">
    <div class="min-w-0">
      <h1 class="font-['DM_Sans'] text-2xl font-normal tracking-tight text-on-surface-strong sm:text-3xl">Group formation</h1>
      <div class="mt-1.5 flex flex-wrap items-center gap-x-5 gap-y-1 text-sm text-on-surface-muted">
        <span class="inline-flex items-center gap-1.5">
          <span class="material-symbols-outlined text-[18px]" aria-hidden="true">group</span>
          <%= @course.group_min %>&ndash;<%= @course.group_max %> members per group
        </span>
        <% if @course.group_formation_closes_at.present? %>
          <span class="inline-flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[18px]" aria-hidden="true">event</span>
            <span>Closes <span class="font-medium text-on-surface-strong"><%= @course.group_formation_closes_at.strftime("%a, %-d %b %Y, %-I:%M %p") %></span></span>
          </span>
        <% end %>
      </div>
    </div>

    <% if formation_open %>
      <%# ===== BEGIN inlined group_formations/ungrouped_dialog | locals: students: @ungrouped_students,
                 invited_ids: @my_invited_student_ids,
                 manage: manage ===== %>
<%# locals: (students:, invited_ids:, manage: false) %>
<div data-controller="modal" class="w-full sm:w-auto">
  <button type="button" data-action="modal#open" class="<%= GroupFormationsHelper::GROUP_TONAL_BUTTON %> w-full gap-2 sm:w-auto">
    <span class="material-symbols-outlined text-[18px]" aria-hidden="true">person_search</span>
    <%= pluralize(students.size, "student") %> without a group
  </button>

  <dialog data-modal-target="dialog"
          data-action="click->modal#backdropClose"
          aria-labelledby="ungrouped-dialog-title"
          class="<%= GroupFormationsHelper::GROUP_DIALOG %>">
    <div class="<%= GroupFormationsHelper::GROUP_DIALOG_PANEL %>">
      <div class="<%= GroupFormationsHelper::GROUP_DIALOG_HEADER %>">
        <h2 id="ungrouped-dialog-title" class="<%= GroupFormationsHelper::GROUP_DIALOG_TITLE %>">Students without a group (<%= students.size %>)</h2>
        <button type="button" data-action="click->modal#close" class="<%= GroupFormationsHelper::GROUP_DIALOG_CLOSE %>" aria-label="Close">
          <span class="material-symbols-outlined">close</span>
        </button>
      </div>

      <div class="<%= GroupFormationsHelper::GROUP_DIALOG_BODY %>" data-controller="list-filter">
        <div class="pb-4">
          <% if manage %>
            <p class="mb-2 text-[13px] text-on-surface-muted">To place someone, open a group with Manage and add them there.</p>
          <% end %>

          <div class="sticky top-0 z-10 bg-surface pb-2">
            <input type="search"
                   placeholder="Search students"
                   autocomplete="off"
                   data-list-filter-target="input"
                   data-action="input->list-filter#filter"
                   class="<%= GroupFormationsHelper::GROUP_INPUT %>">
          </div>

          <%# DOM contract (plan 4.5): group_members#destroy turbo_stream.appends into this id. %>
          <div id="ungrouped-students-list">
            <% students.each do |student| %>
              <%# ===== BEGIN inlined group_formations/ungrouped_student | locals: student: student, invited: invited_ids.include?(student.id) ===== %>
<%# locals: (student:, invited: false) %>
<div id="<%= dom_id(student, :ungrouped) %>"
     data-list-filter-target="item"
     data-list-filter-text="<%= student.name.to_s.downcase %>"
     class="flex items-center justify-between gap-3 border-b border-outline-variant py-2 last:border-0">
  <div class="min-w-0 flex-1">
    <%# ===== BEGIN inlined shared/person | locals: name: student.name.presence || student.email_address ===== %>
<%# locals: (name:, tag: nil) %>
<% display_name = name.presence || "Unknown student" %>
<div class="flex min-w-0 items-start gap-3">
  <span class="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-surface-variant-deep text-[11px] font-medium text-on-surface" aria-hidden="true"><%= display_name.first.upcase %></span>
  <span class="min-w-0 break-words pt-1 text-sm leading-5 text-on-surface">
    <%= display_name %>
    <% if tag.present? %>
      <span class="ml-1.5 text-xs text-on-surface-muted"><%= tag %></span>
    <% end %>
  </span>
</div>
<%# ===== END inlined shared/person ===== %>
  </div>
  <% if invited %>
    <span class="shrink-0 text-[13px] text-success">Invite sent</span>
  <% end %>
</div>
<%# ===== END inlined group_formations/ungrouped_student ===== %>
            <% end %>
          </div>

          <p data-list-filter-target="noMatch" class="hidden py-6 text-center text-sm text-on-surface-muted">No matching students.</p>
          <p data-list-filter-target="empty" class="<%= "hidden" if students.any? %> py-6 text-center text-sm text-on-surface-muted">All students are in a group.</p>
        </div>
      </div>

      <div class="<%= GroupFormationsHelper::GROUP_DIALOG_FOOTER %>">
        <button type="button" data-action="click->modal#close" class="<%= GroupFormationsHelper::GROUP_OUTLINE_BUTTON %> w-full sm:ml-auto sm:w-auto">Close</button>
      </div>
    </div>
  </dialog>
</div>
<%# ===== END inlined group_formations/ungrouped_dialog ===== %>
    <% end %>
  </div>

  <% unless formation_open %>
    <%# ===== BEGIN inlined shared/empty_state | locals: heading: "Grouping is closed by your coordinator",
               description: "Your existing groups are still visible on the Groups tab." ===== %>
<%# locals: (heading:, description:, cta_label: nil, cta_path: nil, illustration: "illustrations/submission_empty_banner.svg") %>
<%# (unchanged shared component) %>
<div class="flex flex-col items-center text-center gap-3 py-14 px-6">
  <%= image_tag illustration,
        class: "h-[180px] w-auto pointer-events-none select-none",
        alt: "" %>
  <h3 class="text-[16px] font-medium text-on-surface-strong"><%= heading %></h3>
  <p class="text-[14px] text-on-surface-variant max-w-[360px]"><%= description %></p>
  <% if cta_label.present? && cta_path.present? %>
    <%= link_to cta_path, class: "mt-2 inline-flex items-center justify-center px-5 py-2 text-[14px] font-medium text-white bg-primary-strong rounded-full hover:bg-primary-hover transition-colors" do %>
      <%= cta_label %>
    <% end %>
  <% end %>
</div>
<%# ===== END inlined shared/empty_state ===== %>
  <% else %>

    <%# ===== My group card (students in a group; no card when ungrouped) ===== %>
    <% if is_student && my_group %>
      <% group = my_group %>
      <% members = leader_first(group.project_group_members.to_a, group) %>
      <% count = members.size %>
      <% membership = members.find { |member| member.user_id == current_user.id } %>
      <% invalid = group_size_state(group, @course) != :ok %>
      <% hint = group_status_hint(group, @course, leader: leads_my_group) %>
      <% group_name = group.group_name.presence || "Unnamed group" %>
      <% last = count == 1 %>
      <section data-testid="my-group-panel-grouped" class="mb-5 rounded-card border border-outline-variant bg-primary-container/40 p-4 sm:p-6">
        <div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
          <div class="min-w-0 md:flex-1">
            <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
              <h2 class="font-['DM_Sans'] text-xl font-medium text-on-surface-strong"><%= group_name %></h2>
              <%# ===== BEGIN inlined group_formations/status_pill | locals: confirmed: group.confirmed? ===== %>
<%# locals: (confirmed:) %>
<% if confirmed %>
  <span class="inline-flex items-center whitespace-nowrap rounded bg-success-container px-2.5 py-0.5 text-[12px] font-medium tracking-wide text-success">Confirmed</span>
<% else %>
  <span class="inline-flex items-center whitespace-nowrap rounded bg-surface-variant px-2.5 py-0.5 text-[12px] font-medium tracking-wide text-on-surface-variant">Not confirmed</span>
<% end %>
<%# ===== END inlined group_formations/status_pill ===== %>
            </div>

            <% if hint.present? %>
              <p class="mt-1.5 flex items-start gap-1.5 text-sm leading-5 text-on-surface-variant">
                <% if invalid %>
                  <span class="material-symbols-outlined mt-0.5 size-4 shrink-0 overflow-hidden text-[16px] leading-none text-warning" aria-hidden="true">warning</span>
                <% end %>
                <span class="min-w-0"><%= hint %></span>
              </p>
            <% end %>

            <div class="mt-4 sm:mt-5">
              <div class="mb-2 flex items-baseline gap-2">
                <span class="text-[11px] font-medium uppercase tracking-wider text-on-surface-variant">Members</span>
                <span class="text-[13px] text-on-surface-muted"><%= @course.group_max.present? ? "#{count} of #{@course.group_max}" : count %></span>
              </div>
              <div class="flex flex-wrap gap-2">
                <% members.each do |member| %>
                  <% name = member.user.name.presence || member.user.email_address %>
                  <div class="inline-flex max-w-full items-center gap-2 rounded-[20px] border border-outline-variant bg-surface py-1 pl-1 pr-3">
                    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-surface-variant-deep text-[11px] font-medium text-on-surface"><%= name.first.upcase %></span>
                    <span class="min-w-0 break-words py-0.5 text-[13px] leading-4 text-on-surface"><%= name %></span>
                    <% if member.user_id == group.leader_id %>
                      <span class="shrink-0 text-[11px] text-on-surface-muted">Leader</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="flex flex-col items-stretch gap-2 sm:flex-row sm:flex-wrap sm:items-center md:shrink-0 md:flex-nowrap">
            <% if leads_my_group && !group.confirmed? %>
              <%= button_to "Confirm group",
                    course_group_confirmation_path(@course, group),
                    method: :post,
                    form: { class: "max-sm:w-full" },
                    class: "#{GroupFormationsHelper::GROUP_FILL_BUTTON} max-sm:w-full" %>
              <% if policy(group).edit? %>
                <%# ===== BEGIN inlined group_formations/manage_dialog | locals: group: group, course: @course, leader: true ===== %>
<%# locals: (group:, course:, leader: false, label: nil) %>
<% group_name = group.group_name.presence || "Unnamed group" %>
<div data-controller="modal" class="max-sm:w-full">
  <%= link_to edit_course_group_path(course, group),
        data: { turbo_frame: dom_id(group, :manage), action: "modal#open" },
        class: "#{leader ? GroupFormationsHelper::GROUP_TEXT_BUTTON : GroupFormationsHelper::GROUP_SMALL_BUTTON} max-sm:w-full" do %>
    <%= label || (leader ? "Manage group" : "Manage") %>
  <% end %>

  <dialog data-modal-target="dialog"
          data-action="click->modal#backdropClose close->modal#reset"
          aria-label="Manage <%= group_name %>"
          class="<%= GroupFormationsHelper::GROUP_DIALOG %>">
    <div class="<%= GroupFormationsHelper::GROUP_DIALOG_PANEL %>">
      <%# target: "_top" is also set here on the live placeholder frame (see section 6, deviation 1). %>
      <%= turbo_frame_tag dom_id(group, :manage), target: "_top", data: { modal_target: "frame" }, class: "flex min-h-0 flex-1 flex-col" do %>
        <div class="<%= GroupFormationsHelper::GROUP_DIALOG_HEADER %>">
          <h2 class="<%= GroupFormationsHelper::GROUP_DIALOG_TITLE %>"><%= group_name %></h2>
          <button type="button" data-action="click->modal#close" class="<%= GroupFormationsHelper::GROUP_DIALOG_CLOSE %>" aria-label="Close">
            <span class="material-symbols-outlined">close</span>
          </button>
        </div>
        <p class="px-4 py-10 text-center text-sm text-on-surface-muted sm:px-6">Loading…</p>
      <% end %>
    </div>
  </dialog>
</div>
<%# ===== END inlined group_formations/manage_dialog ===== %>
              <% end %>
            <% elsif leads_my_group && group.confirmed? && policy(group).revert? %>
              <%= button_to "Reopen group",
                    course_group_confirmation_path(@course, group),
                    method: :delete,
                    form: { class: "max-sm:w-full", data: { confirm_submit: true, confirm_title: "Reopen #{group_name}?", confirm_body: "The group returns to draft. You will lose confirmed status.", confirm_ok: "Reopen group", confirm_danger: false } },
                    class: "#{GroupFormationsHelper::GROUP_OUTLINE_BUTTON} max-sm:w-full" %>
            <% elsif !leads_my_group && membership && policy(membership).destroy? %>
              <%= button_to "Leave group",
                    course_group_member_path(@course, group, membership),
                    method: :delete,
                    form: { class: "max-sm:w-full", data: (last && group.project.present?) ? { turbo_stream: true } : { confirm_submit: true, confirm_title: "Leave #{group_name}?", confirm_body: leave_confirm_body(group, leader: false, last: last), confirm_ok: "Leave group", confirm_danger: last } },
                    class: "#{GroupFormationsHelper::GROUP_TEXT_BUTTON} max-sm:w-full" %>
            <% end %>
          </div>
        </div>
      </section>
    <% end %>

    <%# ===== Browse groups ===== %>
    <section id="formation-browse">
      <div class="mb-4 flex flex-col gap-4 border-b border-outline pb-4">
        <div>
          <div class="flex flex-wrap items-baseline gap-x-4 gap-y-1">
            <h2 class="font-['DM_Sans'] text-xl font-normal tracking-tight text-on-surface-strong">All groups</h2>
            <span class="text-sm font-medium text-on-surface-muted"><%= confirmed_count %> of <%= all_groups.size %> confirmed</span>
          </div>
          <% if is_student && my_group.nil? %>
            <p class="mt-1 text-sm text-on-surface-muted">Join a group or create a new group.</p>
          <% end %>
        </div>

        <div class="flex flex-col justify-between gap-4 md:flex-row md:items-center">
          <div class="flex w-full flex-col items-center gap-3 sm:flex-row md:w-auto">
            <div class="relative flex w-full items-center sm:w-[240px]">
              <span class="material-symbols-outlined pointer-events-none absolute left-3 text-[18px] text-on-surface-muted">search</span>
              <input type="search"
                     id="formation-search"
                     name="search_query"
                     value="<%= params[:search_query] %>"
                     autocomplete="off"
                     placeholder="Search groups or students..."
                     data-search-shortcut-target="input"
                     hx-get="<%= course_group_formation_url(@course) %>"
                     hx-target="#formation-groups"
                     hx-swap="outerHTML"
                     hx-trigger="input changed delay:300ms"
                     hx-include="#formation-search, #formation-status-filter"
                     hx-indicator="#formation-loading"
                     class="peer block w-full rounded-md border border-outline-variant bg-surface-tint py-2 pl-9 pr-9 text-sm text-on-surface outline-none transition-all focus:border-transparent focus:bg-surface focus:ring-2 focus:ring-primary max-sm:min-h-11 max-sm:text-base">
              <kbd aria-hidden="true" class="pointer-events-none absolute right-3 top-1/2 hidden h-5 min-w-5 -translate-y-1/2 select-none items-center justify-center rounded border border-outline-variant bg-surface-tint px-1 font-mono text-[11px] text-on-surface-muted peer-focus:hidden md:flex">/</kbd>
            </div>

            <select id="formation-status-filter"
                    name="status_filter"
                    hx-get="<%= course_group_formation_url(@course) %>"
                    hx-target="#formation-groups"
                    hx-swap="outerHTML"
                    hx-trigger="change"
                    hx-include="#formation-search, #formation-status-filter"
                    hx-indicator="#formation-loading"
                    class="block w-full cursor-pointer rounded-md border border-outline-variant bg-surface-tint px-4 py-2 text-sm text-on-surface outline-none transition-all focus:border-transparent focus:bg-surface focus:ring-2 focus:ring-primary sm:w-[190px] max-sm:min-h-11 max-sm:text-base">
              <option value="all" <%= "selected" if params[:status_filter].blank? || params[:status_filter] == "all" %>>All statuses</option>
              <option value="confirmed" <%= "selected" if params[:status_filter] == "confirmed" %>>Confirmed (<%= confirmed_count %>)</option>
              <option value="draft" <%= "selected" if params[:status_filter] == "draft" %>>Not confirmed (<%= all_groups.size - confirmed_count %>)</option>
              <option value="invalid" <%= "selected" if params[:status_filter] == "invalid" %>>Invalid size (<%= invalid_count %>)</option>
            </select>

            <span id="formation-loading" class="htmx-indicator shrink-0 text-sm font-medium text-primary-strong">
              <span class="material-symbols-outlined animate-spin text-[18px]">progress_activity</span>
            </span>
          </div>

          <div class="flex w-full items-center gap-3 md:w-auto md:justify-end">
            <% if manage %>
              <%# ===== BEGIN inlined group_formations/create_group_dialog | locals: students: @ungrouped_students,
                         url: course_groups_path(@course) ===== %>
<%# locals: (students:, url:) %>
<div data-controller="modal" class="w-full md:w-auto">
  <button type="button" data-action="modal#open" class="<%= GroupFormationsHelper::GROUP_TONAL_BUTTON %> w-full md:w-auto">Create group</button>

  <dialog data-modal-target="dialog"
          data-action="click->modal#backdropClose"
          aria-labelledby="create-group-dialog-title"
          class="<%= GroupFormationsHelper::GROUP_DIALOG %>">
    <div class="<%= GroupFormationsHelper::GROUP_DIALOG_PANEL %>">
      <div class="<%= GroupFormationsHelper::GROUP_DIALOG_HEADER %>">
        <h2 id="create-group-dialog-title" class="<%= GroupFormationsHelper::GROUP_DIALOG_TITLE %>">Create group</h2>
        <button type="button" data-action="click->modal#close" class="<%= GroupFormationsHelper::GROUP_DIALOG_CLOSE %>" aria-label="Close">
          <span class="material-symbols-outlined">close</span>
        </button>
      </div>

      <div class="<%= GroupFormationsHelper::GROUP_DIALOG_BODY %>">
        <div class="pb-4">
          <p class="mb-2 text-[13px] text-on-surface-muted">Pick the first student. They become the leader.</p>
          <%# ===== BEGIN inlined group_formations/student_picker | locals: students: students,
                     verb: "Create",
                     url: url,
                     show_instid: true ===== %>
<%# locals: (students:, verb:, url:, disabled_ids: [], limit: 6, show_instid: false) %>
<div data-controller="list-filter" data-list-filter-limit-value="<%= limit %>">
  <input type="search"
         placeholder="Search by name"
         autocomplete="off"
         data-list-filter-target="input"
         data-action="input->list-filter#filter"
         class="mb-2 <%= GroupFormationsHelper::GROUP_INPUT %>">

  <% students.each do |student| %>
    <div data-list-filter-target="item"
         data-list-filter-text="<%= [student.name, (student.instid if show_instid)].compact.join(' ').downcase %>"
         class="flex items-center justify-between gap-3 py-1.5">
      <div class="flex min-w-0 flex-1 items-center gap-2">
        <%# ===== INLINED AGAIN shared/person (body identical to first inlining) | locals: name: student.name.presence || student.email_address ===== %>
        <% if show_instid && student.instid.present? %>
          <span class="ml-auto shrink-0 font-mono text-[10.5px] text-on-surface-muted"><%= student.instid %></span>
        <% end %>
      </div>
      <% if disabled_ids.include?(student.id) %>
        <span class="shrink-0 text-[13px] text-success">Invite sent</span>
      <% else %>
        <%= button_to verb, url, method: :post, params: { user_id: student.id }, form: { class: "shrink-0" }, class: GroupFormationsHelper::GROUP_SMALL_BUTTON %>
      <% end %>
    </div>
  <% end %>

  <p data-list-filter-target="noMatch" class="hidden text-[13px] text-on-surface-muted">No students match.</p>
  <p data-list-filter-target="empty" class="<%= "hidden" if students.any? %> text-[13px] text-on-surface-muted">No ungrouped students available.</p>
  <p class="pt-2 text-[13px] text-on-surface-muted">Showing <span data-list-filter-target="shown"><%= [students.size, limit].min %></span> of <span data-list-filter-target="total"><%= students.size %></span></p>
</div>
<%# ===== END inlined group_formations/student_picker ===== %>
        </div>
      </div>

      <div class="<%= GroupFormationsHelper::GROUP_DIALOG_FOOTER %>">
        <button type="button" data-action="click->modal#close" class="<%= GroupFormationsHelper::GROUP_OUTLINE_BUTTON %> w-full sm:ml-auto sm:w-auto">Close</button>
      </div>
    </div>
  </dialog>
</div>
<%# ===== END inlined group_formations/create_group_dialog ===== %>
            <% elsif can_create %>
              <%= button_to "Create group",
                    course_groups_path(@course),
                    method: :post,
                    form: { class: "w-full md:w-auto" },
                    class: "#{GroupFormationsHelper::GROUP_TONAL_BUTTON} w-full md:w-auto" %>
            <% end %>
          </div>
        </div>
      </div>

      <%# ===== BEGIN inlined group_formations/groups_table | locals: course: @course,
                 groups: @filtered_groups,
                 my_group: @my_group,
                 requested_group_ids: @my_requested_group_ids,
                 filters_active: @filters_active,
                 list_state: @group_list_state,
                 total_count: @total_group_count,
                 displayed_count: @filtered_groups.count,
                 show_all: @show_all ===== %>
<%# locals: (course:, groups:, my_group:, requested_group_ids:, filters_active:, list_state:, total_count:, displayed_count:, show_all:) %>
<% manage = policy(course).manage_groups? %>
<% th = "border-b border-outline-variant px-3 py-3 text-left text-xs font-medium uppercase tracking-wider text-on-surface-variant select-none lg:px-4" %>
<% td = "border-t border-outline-variant px-3 py-4 align-middle lg:px-4 max-sm:block max-sm:border-0 max-sm:p-0" %>

<% if groups.blank? %>
  <div id="formation-groups" class="rounded-lg py-14 text-center <%= "border border-outline-variant" if list_state != :no_matches %>">
    <% if list_state == :no_matches %>
      <p class="text-base font-medium text-on-surface-strong">No groups match your current filters.</p>
      <p class="mt-1 text-sm text-on-surface-variant">Try adjusting your search or filters.</p>
    <% else %>
      <p class="text-base font-medium text-on-surface-strong">No groups yet</p>
      <p class="mt-1 text-sm text-on-surface-variant">Groups will appear here once they are created.</p>
    <% end %>
  </div>
<% else %>
  <div id="formation-groups"
       class="sm:overflow-x-auto sm:rounded-lg sm:border sm:border-outline-variant"
       data-controller="expandable-rows">
    <table class="w-full table-fixed max-sm:block">
      <thead class="bg-surface max-sm:hidden">
        <tr>
          <th class="w-[14%] <%= th %>">Group</th>
          <th class="w-[34%] <%= th %>">
            <button type="button" data-expandable-toggle-all class="inline-flex cursor-pointer items-center gap-1">
              Members
              <span data-expandable-all-icon class="material-symbols-outlined text-[16px] text-on-surface-variant transition-all">unfold_more</span>
              <span data-expandable-all-label class="sr-only">Expand all</span>
            </button>
          </th>
          <th class="w-[24%] <%= th %>">Status</th>
          <th class="w-[28%] <%= th %>"><span class="sr-only">Action</span></th>
        </tr>
      </thead>

      <% groups.each do |group| %>
        <% members = leader_first(group.project_group_members.to_a, group) %>
        <% count = members.size %>
        <% invalid = group_size_state(group, course) != :ok %>
        <% expanded = filters_active %>
        <% own = my_group&.id == group.id %>

        <% action = capture do %>
          <% if my_group.nil? && policy(group).join? %>
            <% label = group.locked? ? "Request to join" : "Join" %>
            <% if group.confirmed? %>
              <button type="button" disabled aria-disabled="true" class="<%= GroupFormationsHelper::GROUP_ROW_DISABLED_BUTTON %>"><%= label %></button>
            <% elsif group_full?(group, course) %>
              <span class="text-[13px] text-on-surface-muted">Full</span>
            <% elsif requested_group_ids.include?(group.id) %>
              <span class="text-[13px] text-on-surface-muted">Request sent</span>
            <% elsif group.locked? %>
              <%= button_to label, course_group_join_requests_path(course, group), method: :post,
                    form: { class: "max-sm:w-full" }, class: GroupFormationsHelper::GROUP_ROW_BUTTON %>
            <% else %>
              <%= button_to label, course_group_members_path(course, group), method: :post,
                    form: { class: "max-sm:w-full" }, class: GroupFormationsHelper::GROUP_ROW_BUTTON %>
            <% end %>
          <% end %>
          <% if manage %>
            <%# ===== INLINED AGAIN group_formations/manage_dialog (body identical to the card's) | locals: group: group, course: course, leader: false ===== %>
          <% end %>
        <% end %>

        <tbody id="<%= dom_id(group) %>"
               class="max-sm:mb-3 max-sm:grid max-sm:grid-cols-[minmax(0,1fr)_auto] max-sm:items-center max-sm:gap-x-3 max-sm:gap-y-2 max-sm:rounded-card max-sm:border max-sm:p-4 <%= invalid ? "bg-warning-container-alt max-sm:border-warning-border" : "max-sm:border-outline-variant max-sm:bg-surface" %>">
          <tr data-row-id="<%= group.id %>" class="cursor-pointer transition-colors max-sm:contents <%= "hover:bg-surface-hover" unless invalid %>">
            <td class="<%= td %> text-sm max-sm:order-1">
              <div class="break-words font-medium text-on-surface-strong"><%= group.group_name.presence || "Unnamed group" %></div>
              <% if own %><div class="text-xs text-on-surface-muted">Your group</div><% end %>
            </td>

            <td class="<%= td %> max-sm:order-3 max-sm:col-span-full">
              <button type="button"
                      data-row-toggle
                      aria-expanded="<%= expanded %>"
                      aria-controls="<%= dom_id(group, :detail) %>"
                      class="flex w-full min-w-0 cursor-pointer items-center gap-3 rounded-md text-left max-sm:min-h-11">
                <span class="flex shrink-0 -space-x-1.5 sm:hidden xl:flex">
                  <% members.first(3).each do |member| %>
                    <span class="relative z-10 inline-flex h-7 w-7 items-center justify-center rounded-full border-2 border-surface bg-surface-variant-deep text-[11px] font-medium text-on-surface" title="<%= member.user.name %>"><%= member.user.name.presence&.first&.upcase || "?" %></span>
                  <% end %>
                  <% if count > 3 %>
                    <span class="relative z-10 inline-flex h-7 w-7 items-center justify-center rounded-full border-2 border-surface bg-surface-variant-deep text-[10px] font-medium text-on-surface">+<%= count - 3 %></span>
                  <% end %>
                </span>
                <span class="flex min-w-0 flex-1 flex-wrap items-center gap-x-1.5">
                  <span class="text-sm text-on-surface-muted"><%= course.group_max.present? ? "#{count} of #{course.group_max} members" : pluralize(count, "member") %></span>
                  <% if invalid %>
                    <span class="material-symbols-outlined size-4 shrink-0 overflow-hidden text-[16px] leading-none text-warning" role="img" aria-label="Invalid size">warning</span>
                  <% end %>
                </span>
                <span data-row-chevron class="material-symbols-outlined shrink-0 text-[20px] text-on-surface-muted transition-transform duration-200 <%= "rotate-180" if expanded %>">expand_more</span>
              </button>
            </td>

            <td class="<%= td %> text-right sm:text-left max-sm:order-2 max-sm:justify-self-end">
              <%# ===== INLINED AGAIN group_formations/status_pill (body identical to first inlining) | locals: confirmed: group.confirmed? ===== %>
            </td>

            <td class="<%= td %> text-sm max-sm:order-5 max-sm:col-span-full <%= "max-sm:hidden" if action.blank? %>" data-expandable-ignore>
              <div class="flex items-center gap-2 max-sm:flex-col max-sm:items-stretch"><%= action %></div>
            </td>
          </tr>

          <%# Do NOT add max-sm:block / any display utility here: it overrides `hidden` (bug 1). %>
          <tr id="<%= dom_id(group, :detail) %>"
              data-detail-row-id="<%= group.id %>"
              class="<%= expanded ? "" : "hidden" %> <%= "bg-surface-hover/50" unless invalid %> max-sm:order-4 max-sm:col-span-full max-sm:border-t max-sm:border-outline-variant max-sm:bg-transparent max-sm:pt-3">
            <td colspan="4" class="border-t border-surface-variant px-3 py-4 lg:px-4 max-sm:block max-sm:border-0 max-sm:p-0">
              <div class="grid grid-cols-1 gap-x-6 gap-y-3 sm:grid-cols-2 sm:pl-[10%]">
                <% members.each do |member| %>
                  <div id="<%= dom_id(member) %>" class="min-w-0">
                    <%# ===== INLINED AGAIN shared/person (body identical to first inlining) | locals: name: member.user.name.presence || member.user.email_address, tag: (member.user_id == group.leader_id ? "Leader" : nil) ===== %>
                  </div>
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      <% end %>
    </table>

    <% if total_count.positive? %>
      <div class="flex items-center justify-between gap-2 py-2 text-sm text-on-surface-muted sm:border-t sm:border-outline-variant sm:bg-surface sm:px-4 sm:py-3">
        <span>
          Showing <span class="font-semibold text-on-surface"><%= displayed_count %></span>
          of <span class="font-semibold text-on-surface"><%= total_count %></span> groups
        </span>

        <% if !show_all && total_count > displayed_count %>
          <button type="button"
                  class="<%= GroupFormationsHelper::GROUP_TEXT_BUTTON %>"
                  hx-get="<%= course_group_formation_url(course) %>"
                  hx-target="#formation-groups"
                  hx-swap="outerHTML"
                  hx-include="#formation-search, #formation-status-filter"
                  hx-vals='{"show_all": "true"}'
                  hx-indicator="#formation-loading">
            Show all <%= total_count %>
          </button>
        <% end %>
      </div>
    <% end %>
  </div>
<% end %>
<%# ===== END inlined group_formations/groups_table ===== %>
    </section>
  <% end %>

  <div id="modals"></div>

  <%# ===== BEGIN inlined shared/confirm_dialog | locals: (none) ===== %>
<%# Shared destructive-action confirmation. Forms opt in with data-confirm-submit
    plus data-confirm-title/body/ok/danger; confirm_dialog_controller listens for
    those submissions and fills this one dialog. Body may hold several paragraphs:
    the controller splits data-confirm-body on a blank line and builds <p> children. %>
<dialog id="confirm-dialog"
        data-controller="confirm-dialog"
        aria-labelledby="confirm-dialog-title"
        class="m-auto w-[calc(100vw-2rem)] max-w-md overflow-hidden rounded-lg border-0 bg-surface p-0 shadow-xl backdrop:bg-black/40">
  <div class="flex max-h-[90dvh] min-h-0 flex-col">
    <h2 id="confirm-dialog-title" data-confirm-dialog-target="title" class="shrink-0 px-5 pb-3 pt-5 font-['DM_Sans'] text-xl font-medium text-on-surface-strong sm:px-6 sm:pt-6">Are you sure?</h2>
    <div data-confirm-dialog-target="body" class="min-h-0 flex-1 space-y-2 overflow-y-auto px-5 text-sm text-on-surface-variant sm:px-6"></div>
    <div class="flex shrink-0 justify-end gap-2 px-5 py-4 sm:px-6">
      <button type="button" data-action="click->confirm-dialog#cancel" class="<%= GroupFormationsHelper::GROUP_TEXT_BUTTON %> max-sm:flex-1">Cancel</button>
      <button type="button" data-confirm-dialog-target="ok" data-action="click->confirm-dialog#confirm" class="<%= GroupFormationsHelper::GROUP_FILL_BUTTON %> max-sm:flex-1">Confirm</button>
    </div>
  </div>
</dialog>
<%# ===== END inlined shared/confirm_dialog ===== %>
<% end %>
```

---

## 2. Fully inlined Manage frame (`groups/edit.html.erb`)

Spec §2 item 4: the frame renders the **whole dialog interior** (header, scroll body, footer). `_manage_dialog` renders only the trigger, the `<dialog>` and the loading placeholder. Leader mode has no "Confirm group" (the card has it). "Delete group" and "Leave group" live in the footer. Pickers use one `button_to` per row. `instid` shows only in the staff Add picker (`show_instid: true`). Pickers, status pill and person bodies are identical to the ones printed in section 1.

```erb
<%= turbo_frame_tag dom_id(@group, :manage), target: "_top", class: "flex min-h-0 flex-1 flex-col" do %>
  <% staff = policy(@course).manage_groups? %>
  <% leader_edit = !staff && !@group.confirmed? %>
  <% members = leader_first(@group.project_group_members.to_a, @group) %>
  <% count = members.size %>
  <% group_name = @group.group_name.presence || "Unnamed group" %>
  <% membership = members.find { |member| member.user_id == current_user.id } %>
  <% last = count == 1 %>
  <% last_with_project = last && @group.project.present? %>
  <% requests = @incoming_join_requests.to_a %>

  <div class="<%= GroupFormationsHelper::GROUP_DIALOG_HEADER %>">
    <h2 class="<%= GroupFormationsHelper::GROUP_DIALOG_TITLE %>"><%= group_name %></h2>
    <button type="button" data-action="click->modal#close" class="<%= GroupFormationsHelper::GROUP_DIALOG_CLOSE %>" aria-label="Close">
      <span class="material-symbols-outlined">close</span>
    </button>
  </div>

  <div class="<%= GroupFormationsHelper::GROUP_DIALOG_BODY %>">
    <% if staff %>
      <div class="pb-2">
        <%# ===== INLINED group_formations/status_pill | locals: confirmed: @group.confirmed? ===== %>
        <%= render "group_formations/status_pill", confirmed: @group.confirmed? %>
      </div>
    <% end %>

    <%# ----- Join requests (leader mode) ----- %>
    <% if leader_edit %>
      <section class="<%= GroupFormationsHelper::GROUP_SECTION %>">
        <h3 class="<%= GroupFormationsHelper::GROUP_SECTION_TITLE %>">Join requests</h3>
        <% if requests.any? %>
          <% requests.each do |invite| %>
            <div class="flex items-start justify-between gap-3 py-1.5">
              <div class="min-w-0 flex-1"><%= render "shared/person", name: invite.sender.name %></div>
              <div class="flex shrink-0 gap-1">
                <%= button_to "Accept",
                      course_group_join_request_path(@course, @group, invite),
                      method: :patch,
                      params: { status: "accepted" },
                      form: { class: "inline-flex" },
                      class: GroupFormationsHelper::GROUP_SMALL_BUTTON %>
                <%= button_to "Decline",
                      course_group_join_request_path(@course, @group, invite),
                      method: :patch,
                      params: { status: "declined" },
                      form: { class: "inline-flex" },
                      class: GroupFormationsHelper::GROUP_TEXT_SMALL_BUTTON %>
              </div>
            </div>
          <% end %>
        <% else %>
          <p class="text-sm text-on-surface-muted">No pending requests.</p>
        <% end %>
      </section>
    <% end %>

    <%# ----- Members (both modes) ----- %>
    <section class="<%= GroupFormationsHelper::GROUP_SECTION %>">
      <h3 class="<%= GroupFormationsHelper::GROUP_SECTION_TITLE %>">Members (<%= @course.group_max.present? ? "#{count} of #{@course.group_max}" : count %>)</h3>
      <% members.each do |member| %>
        <% name = member.user.name.presence || member.user.email_address %>
        <% is_leader = member.user_id == @group.leader_id %>
        <% removable = staff || (leader_edit && !is_leader) %>
        <div id="<%= dom_id(member, :manage) %>" class="flex items-start justify-between gap-3 py-1.5">
          <div class="min-w-0 flex-1"><%= render "shared/person", name: name, tag: (is_leader ? "Leader" : nil) %></div>
          <% if removable %>
            <%
              remove_data =
                if last_with_project
                  { turbo_stream: true }
                else
                  body = last ? "#{name} is the last member, so #{group_name} will be deleted.\n\nThis can't be undone." : remove_confirm_body(@group, name, manager: staff)
                  { confirm_submit: true, confirm_title: "Remove #{name}?", confirm_body: body, confirm_ok: "Remove from group", confirm_danger: true }
                end
            %>
            <%= button_to (staff ? "Remove" : "Remove from group"),
                  course_group_member_path(@course, @group, member),
                  method: :delete,
                  form: { class: "shrink-0", data: remove_data },
                  class: GroupFormationsHelper::GROUP_DANGER_TEXT_SMALL_BUTTON %>
          <% end %>
        </div>
      <% end %>
    </section>

    <% if leader_edit %>
      <%# ----- Invite link ----- %>
      <% if policy(@group).generate_invite_link? %>
        <section class="<%= GroupFormationsHelper::GROUP_SECTION %>">
          <h3 class="<%= GroupFormationsHelper::GROUP_SECTION_TITLE %>">Invite link</h3>
          <% if @my_group_invite_token.present? %>
            <div class="flex gap-2" data-controller="invite-link">
              <input type="text"
                     readonly
                     value="<%= join_url(@my_group_invite_token) %>"
                     aria-label="Invite link"
                     data-invite-link-target="linkField"
                     class="min-w-0 flex-1 rounded-md border border-outline-variant bg-surface-tint px-3 py-2 text-sm text-on-surface-variant max-sm:min-h-11 max-sm:text-base">
              <button type="button" data-invite-link-target="button" data-action="click->invite-link#copy" class="<%= GroupFormationsHelper::GROUP_SMALL_BUTTON %> shrink-0">Copy</button>
            </div>
            <p class="mt-1.5 text-[13px] text-on-surface-muted">Link expires 24 hours after it's generated.</p>
          <% end %>
          <%= button_to (@my_group_invite_token.present? ? "Generate new link" : "Generate invite link"),
                course_group_invite_link_path(@course, @group),
                method: :post,
                form: { class: "mt-2 inline-flex" },
                class: GroupFormationsHelper::GROUP_TEXT_BUTTON %>
        </section>
      <% end %>

      <%# ----- Settings: approval switch (auto_submit) ----- %>
      <% if policy(@group).update? %>
        <section class="<%= GroupFormationsHelper::GROUP_SECTION %>">
          <h3 class="<%= GroupFormationsHelper::GROUP_SECTION_TITLE %>">Settings</h3>
          <%= form_with url: course_group_path(@course, @group), method: :patch, scope: :project_group, data: { controller: "auto-submit" } do |form| %>
            <label class="flex cursor-pointer items-center justify-between gap-4 max-sm:min-h-11">
              <span class="text-sm text-on-surface-strong">
                Require approval to join
                <span class="block text-[13px] text-on-surface-muted">Students send a request and you accept or decline.</span>
              </span>
              <span class="relative inline-flex shrink-0">
                <%= form.check_box :locked,
                      { checked: @group.locked?, class: "peer sr-only", data: { action: "change->auto-submit#submit" } },
                      "true", "false" %>
                <span class="block h-6 w-10 rounded-full bg-outline transition-colors after:absolute after:left-0.5 after:top-0.5 after:h-5 after:w-5 after:rounded-full after:bg-surface after:transition-all after:content-[''] peer-checked:bg-primary-strong peer-checked:after:translate-x-4 peer-focus-visible:ring-2 peer-focus-visible:ring-primary"></span>
              </span>
            </label>
          <% end %>
        </section>
      <% end %>

      <%# ----- Invite student (leader picker) ----- %>
      <% if policy(@group).direct_invite? %>
        <section class="<%= GroupFormationsHelper::GROUP_SECTION %>">
          <h3 class="<%= GroupFormationsHelper::GROUP_SECTION_TITLE %>">Invite student</h3>
          <%= render "group_formations/student_picker",
                     students: @ungrouped_students,
                     verb: "Invite",
                     url: course_group_invitations_path(@course, @group),
                     disabled_ids: @my_invited_student_ids,
                     limit: 6 %>
        </section>
      <% end %>
    <% end %>

    <%# ----- Add student (coordinator / lecturer picker, instid shown) ----- %>
    <% if staff %>
      <section class="<%= GroupFormationsHelper::GROUP_SECTION %>">
        <h3 class="<%= GroupFormationsHelper::GROUP_SECTION_TITLE %>">Add student</h3>
        <% if group_full?(@group, @course) %>
          <p class="text-sm text-on-surface-muted">This group is full.</p>
        <% else %>
          <%= render "group_formations/student_picker",
                     students: @ungrouped_students,
                     verb: "Add",
                     url: course_group_members_path(@course, @group),
                     limit: 6,
                     show_instid: true %>
        <% end %>
      </section>
    <% end %>
  </div>

  <div class="<%= GroupFormationsHelper::GROUP_DIALOG_FOOTER %>">
    <div class="flex flex-wrap gap-1">
      <% if leader_edit %>
        <% if policy(@group).destroy? %>
          <%= button_to "Delete group",
                course_group_path(@course, @group),
                method: :delete,
                form: { class: "max-sm:flex-1", data: { confirm_submit: true, confirm_title: "Delete #{group_name}?", confirm_body: delete_confirm_body(@group), confirm_ok: "Delete group", confirm_danger: true } },
                class: "#{GroupFormationsHelper::GROUP_DANGER_TEXT_BUTTON} max-sm:w-full" %>
        <% end %>
        <% if membership && policy(membership).destroy? %>
          <%= button_to "Leave group",
                course_group_member_path(@course, @group, membership),
                method: :delete,
                form: { class: "max-sm:flex-1", data: last_with_project ? { turbo_stream: true } : { confirm_submit: true, confirm_title: "Leave #{group_name}?", confirm_body: leave_confirm_body(@group, leader: true, last: last), confirm_ok: "Leave group", confirm_danger: last } },
                class: "#{GroupFormationsHelper::GROUP_TEXT_BUTTON} max-sm:w-full" %>
        <% end %>
      <% elsif staff %>
        <% if policy(@group).destroy? %>
          <%= button_to "Delete group",
                course_group_path(@course, @group),
                method: :delete,
                form: { class: "max-sm:flex-1", data: { confirm_submit: true, confirm_title: "Delete #{group_name}?", confirm_body: delete_confirm_body(@group), confirm_ok: "Delete group", confirm_danger: true } },
                class: "#{GroupFormationsHelper::GROUP_DANGER_TEXT_BUTTON} max-sm:w-full" %>
        <% end %>
        <% if policy(@group).confirm? && !@group.confirmed? %>
          <%= button_to "Confirm for leader…",
                course_group_confirmation_path(@course, @group),
                method: :post,
                form: { class: "max-sm:flex-1", data: { confirm_submit: true, confirm_title: "Confirm #{group_name} for its leader?", confirm_body: confirm_for_leader_body(@group), confirm_ok: "Confirm for leader", confirm_danger: false } },
                class: "#{GroupFormationsHelper::GROUP_TEXT_BUTTON} max-sm:w-full" %>
        <% end %>
      <% end %>
    </div>

    <button type="button" data-action="click->modal#close" class="<%= GroupFormationsHelper::GROUP_FILL_BUTTON %> w-full sm:ml-auto sm:w-auto">Done</button>
  </div>
<% end %>
```

Frame ivars (`GroupsController#edit`, unchanged from the previous dump): `@group`, `@incoming_join_requests`, `@my_group_invite_token`, `@my_invited_student_ids`, `@ungrouped_students`.

---

## 3. JavaScript that changed

Unchanged and not reprinted (identical to the previous dump): `modal_controller.js` (already has `reset()`), `expandable_rows_controller.js` (already has the `[data-expandable-ignore]` early return and `aria-expanded` sync), `invite_link_controller.js` (already has the "Copied" state), `dropdown_controller.js` (`close()` is bound to Esc through `data-action` on the bell wrapper), `auto_submit_controller.js`, `search_shortcut_controller.js`, `dissolve_warning_modal_controller.js`.

### `app/javascript/controllers/confirm_dialog_controller.js` (spec §9.3: only the `body` line in `onSubmit` changed)

```javascript
import { Controller } from "@hotwired/stimulus";

// One shared confirmation dialog for every destructive form on the page.
// Forms opt in with data-confirm-submit (plus data-confirm-title/body/ok/danger);
// this controller intercepts their submit in the capture phase, fills the dialog,
// and only re-submits after the user confirms.
//
// data-confirm-body may hold several paragraphs separated by a blank line
// ("A.\n\nB."). They are rendered as <p> children via textContent, so it stays XSS-safe.
export default class extends Controller {
  static targets = ["title", "body", "ok"];

  connect() {
    this.onSubmit = this.onSubmit.bind(this);
    this.pendingForm = null;
    this.submitting = false;
    document.addEventListener("submit", this.onSubmit, true);
  }

  disconnect() {
    document.removeEventListener("submit", this.onSubmit, true);
  }

  onSubmit(event) {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;
    if (!form.hasAttribute("data-confirm-submit")) return;

    if (form.dataset.confirmConfirmed === "true") {
      delete form.dataset.confirmConfirmed;
      return;
    }

    event.preventDefault();
    this.pendingForm = form;

    const title = form.dataset.confirmTitle || "Are you sure?";
    const body = form.dataset.confirmBody || "";
    const okLabel = form.dataset.confirmOk || "Confirm";
    const danger = form.dataset.confirmDanger === "true";

    this.titleTarget.textContent = title;
    this.bodyTarget.replaceChildren(
      ...body.split("\n\n").filter(Boolean).map((text) => {
        const p = document.createElement("p");
        p.textContent = text;
        return p;
      }),
    );
    this.bodyTarget.classList.toggle("hidden", body.length === 0);
    this.okTarget.textContent = okLabel;
    this.okTarget.classList.toggle("bg-error", danger);
    this.okTarget.classList.toggle("hover:bg-error-hover", danger);
    this.okTarget.classList.toggle("bg-primary-strong", !danger);
    this.okTarget.classList.toggle("hover:bg-primary-hover", !danger);

    this.element.showModal();
  }

  confirm() {
    const form = this.pendingForm;
    if (!form) return;

    this.pendingForm = null;
    this.submitting = true;
    form.dataset.confirmConfirmed = "true";
    this.element.close();
    form.requestSubmit();
    this.submitting = false;
  }

  cancel() {
    this.pendingForm = null;
    this.element.close();
  }
}
```

### `app/javascript/controllers/list_filter_controller.js` (spec §8: only `apply()` changed)

`total` now means matches (before the cap), so a picker reads "Showing 6 of 23" while searching. `noMatch` and `empty` are mutually exclusive.

```javascript
import { Controller } from "@hotwired/stimulus";

// Lightweight client-side filtering for dialog/picker lists: search text,
// optional select tags, an optional "show first N" cap, and live counts.
// The server-filtered group table uses htmx instead.
export default class extends Controller {
  static targets = [
    "input",
    "select",
    "item",
    "shown",
    "total",
    "noMatch",
    "empty",
    "container",
  ];
  static values = { limit: { type: Number, default: 0 } };

  connect() {
    this.apply();
  }

  filter() {
    this.apply();
  }

  apply() {
    const query = this.hasInputTarget
      ? this.inputTarget.value.trim().toLowerCase()
      : "";
    const selected = this.hasSelectTarget ? this.selectTarget.value : "all";

    let matched = 0;
    let visible = 0;
    this.itemTargets.forEach((item) => {
      const text = item.dataset.listFilterText || "";
      const tags = (item.dataset.listFilterTags || "").split(" ");
      const textMatch = query.length === 0 || text.includes(query);
      const tagMatch = selected === "all" || tags.includes(selected);
      const match = textMatch && tagMatch;
      const show = match && (this.limitValue === 0 || visible < this.limitValue);

      item.classList.toggle("hidden", !show);
      if (match) matched += 1;
      if (show) visible += 1;
    });

    const hasItems = this.itemTargets.length > 0;

    if (this.hasShownTarget) this.shownTarget.textContent = visible;
    if (this.hasTotalTarget) this.totalTarget.textContent = matched;
    if (this.hasNoMatchTarget) this.noMatchTarget.classList.toggle("hidden", !hasItems || matched > 0);
    if (this.hasEmptyTarget) this.emptyTarget.classList.toggle("hidden", hasItems);
    if (this.hasContainerTarget) this.containerTarget.classList.toggle("hidden", visible === 0);

    this.element.dispatchEvent(
      new CustomEvent("list-filter:change", {
        bubbles: true,
        detail: { active: query.length > 0 || selected !== "all", visible, total: matched },
      }),
    );
  }
}
```

---

## 4. Ruby that changed

Unchanged and not reprinted (identical to the previous dump): `GroupsController` (already authorizes `:edit?` and sets the four frame ivars), `ProjectGroupPolicy`, `ProjectGroupMemberPolicy`, `CoursePolicy`, the formation routes.

### `app/helpers/group_formations_helper.rb` (spec §5, whole file)

```ruby
module GroupFormationsHelper
  BTN = "inline-flex items-center justify-center rounded-full font-medium transition-colors cursor-pointer disabled:cursor-not-allowed max-sm:min-h-11".freeze

  GROUP_FILL_BUTTON = "#{BTN} bg-primary-strong px-5 py-2 text-sm text-white hover:bg-primary-hover".freeze
  GROUP_OUTLINE_BUTTON = "#{BTN} border border-outline px-5 py-2 text-sm text-primary-strong hover:bg-primary-container".freeze
  GROUP_TONAL_BUTTON = "#{BTN} bg-primary-container-alt px-5 py-2 text-sm text-primary-strong hover:bg-primary-container-ring".freeze
  GROUP_ROW_BUTTON = "#{BTN} bg-primary-container-alt px-3 py-1.5 text-[13px] whitespace-nowrap text-primary-strong hover:bg-primary-container-ring max-sm:w-full".freeze
  GROUP_ROW_DISABLED_BUTTON = "#{BTN} bg-surface-variant px-3 py-1.5 text-[13px] whitespace-nowrap text-on-surface-disabled max-sm:w-full".freeze
  GROUP_SMALL_BUTTON = "#{BTN} border border-outline px-4 py-1.5 text-[13px] text-primary-strong hover:bg-primary-container".freeze
  GROUP_TEXT_BUTTON = "#{BTN} px-3 py-2 text-sm text-primary-strong hover:bg-primary-container".freeze
  GROUP_TEXT_SMALL_BUTTON = "#{BTN} px-3 py-1.5 text-[13px] text-primary-strong hover:bg-primary-container".freeze
  GROUP_DANGER_TEXT_BUTTON = "#{BTN} px-3 py-2 text-sm text-error hover:bg-error-container".freeze
  GROUP_DANGER_TEXT_SMALL_BUTTON = "#{BTN} px-3 py-1 text-[13px] text-error hover:bg-error-container".freeze
  # Filled red: confirm / dissolve dialog OK only
  GROUP_DANGER_BUTTON = "#{BTN} bg-error px-5 py-2 text-sm text-white hover:bg-error-hover".freeze

  GROUP_DIALOG = "m-auto w-[calc(100vw-2rem)] max-w-lg overflow-hidden rounded-lg border-0 bg-surface p-0 shadow-xl backdrop:bg-black/30 max-sm:m-0 max-sm:h-dvh max-sm:max-h-none max-sm:w-screen max-sm:max-w-none max-sm:rounded-none".freeze
  GROUP_DIALOG_PANEL = "flex max-h-[85vh] min-h-0 flex-col max-sm:h-dvh max-sm:max-h-none".freeze
  GROUP_DIALOG_HEADER = "flex shrink-0 items-center justify-between gap-3 px-4 pb-2 pt-3 sm:px-6 sm:pb-3 sm:pt-5".freeze
  GROUP_DIALOG_TITLE = "min-w-0 break-words font-['DM_Sans'] text-xl font-medium text-on-surface-strong".freeze
  GROUP_DIALOG_CLOSE = "flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-on-surface-variant hover:bg-surface-variant sm:h-9 sm:w-9".freeze
  GROUP_DIALOG_BODY = "min-h-0 flex-1 overflow-y-auto px-4 sm:px-6".freeze
  GROUP_DIALOG_FOOTER = "flex shrink-0 flex-col-reverse gap-3 border-t border-outline-variant px-4 pb-[max(0.75rem,env(safe-area-inset-bottom))] pt-3 sm:flex-row sm:items-center sm:justify-between sm:px-6 sm:py-4".freeze
  GROUP_SECTION = "border-b border-outline-variant py-4 last:border-0".freeze
  GROUP_SECTION_TITLE = "mb-2 font-['DM_Sans'] text-[15px] font-medium text-on-surface-strong".freeze
  GROUP_INPUT = "block w-full rounded-md border border-outline-variant bg-surface-tint px-3 py-2 text-sm text-on-surface outline-none transition-all focus:border-transparent focus:bg-surface focus:ring-2 focus:ring-primary max-sm:min-h-11 max-sm:text-base".freeze

  def group_size_state(group, course)
    count = group.project_group_members.size
    return :under if course.group_min.present? && count < course.group_min.to_i
    return :over if course.group_max.present? && count > course.group_max.to_i

    :ok
  end

  def group_full?(group, course)
    course.group_max.present? && group.project_group_members.size >= course.group_max.to_i
  end

  def leader_first(members, group)
    members.sort_by { |member| member.user_id == group.leader_id ? 0 : 1 }
  end

  def group_member_names(group)
    group.project_group_members.map { |member| member.user.name }.compact.join(", ")
  end

  def group_leader_name(group)
    group.project_group_members.find { |member| member.user_id == group.leader_id }&.user&.name.presence || "the leader"
  end

  # Hint under the my-group card title. Size hints are skipped in
  # Auto-Confirmability mode (D6): the service message explains it there.
  def group_status_hint(group, course, leader:)
    unless course.student_list_finalised?
      count = group.project_group_members.size
      state = group_size_state(group, course)
      return "Outside the size limits. Contact your coordinator." if group.confirmed? && state != :ok
      return "Needs #{pluralize(course.group_min.to_i - count, 'more member')}" if state == :under
      return "Over the maximum of #{course.group_max}" if state == :over
    end

    "Waiting for your leader to confirm." if !leader && !group.confirmed?
  end

  # Confirm-dialog bodies. Paragraphs are separated by a blank line;
  # confirm_dialog_controller splits on it (§9.3).
  def delete_confirm_body(group)
    names = group.project_group_members.map { |member| member.user.name.presence || member.user.email_address }.to_sentence
    paras = []
    paras << "These students will have no group: #{names}." if names.present?
    paras << "Its project will be lost." if group.project.present?
    paras << "This can't be undone."
    paras.join("\n\n")
  end

  def leave_confirm_body(group, leader:, last:)
    return "You're the last member, so the group will be deleted.\n\nThis can't be undone." if last

    paras = []
    paras << "Another member becomes the leader." if leader
    paras << "The group will become Not confirmed." if group.confirmed?
    paras << "You can join another group while formation is open."
    paras.join("\n\n")
  end

  def remove_confirm_body(group, member_name, manager:)
    return "#{member_name} will have no group." unless manager

    size = group.project_group_members.size
    paras = ["#{group.group_name.presence || 'This group'} goes from #{size} to #{size - 1} members."]
    paras << "It may become Not confirmed." if group.confirmed?
    paras.join("\n\n")
  end

  def confirm_for_leader_body(group)
    leader = group_leader_name(group)
    "#{group.group_name.presence || 'This group'} will show as Confirmed, as if #{leader} had confirmed it. Members can't be removed afterwards.\n\n#{leader} can still reopen the group."
  end
end
```

### `app/controllers/group_formations_controller.rb` (spec §9.1: only `filtered_groups` changed)

```ruby
class GroupFormationsController < ApplicationController
  before_action :set_course

  def show
    authorize @course, :grouping?

    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @my_group = @course.project_groups
                       .includes(project_group_members: :user)
                       .joins(:project_group_members)
                       .find_by(project_group_members: { user_id: current_user.id })

    @my_group_can_confirm = @my_group.present? && !@my_group.confirmed? && @my_group.confirmable?

    @my_group_invite_token = @my_group.project_group_invite_links.find_by(sender: current_user)&.token if @my_group
    @incoming_join_requests = @my_group.present? ? @my_group.project_group_invites.pending_for_group(@my_group).where(kind: :direct_request) : []
    @incoming_direct_invites = ProjectGroupInvite.for_course(@course).sent_to(current_user).pending.where(kind: :direct_invite)
    @my_requested_group_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_request).pluck(:project_group_id)
    @my_invited_student_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_invite).pluck(:recipient_id)

    @groups = @course.project_groups
                     .includes(:project, project_group_members: :user)
                     .order(:created_at)
    enrolled_student_ids = @course.enrolments.where(role: :student).pluck(:user_id)
    grouped_student_ids = ProjectGroupMember.joins(:project_group)
                                            .where(project_groups: { course_id: @course.id })
                                            .pluck(:user_id)
    ungrouped_ids = enrolled_student_ids - grouped_student_ids
    @ungrouped_students = User.where(id: ungrouped_ids).order(:name)

    @filtered_groups = filtered_groups
    @filters_active = formation_filters_active?
    @group_list_state = list_state(@groups, @filtered_groups)
    @total_group_count = @filtered_groups.count
    @show_all = params[:show_all] == 'true'
    @filtered_groups = @filtered_groups.first(Rails.application.config.participants_pagination_threshold) unless @show_all

    return unless request.headers['HX-Request']

    render partial: 'group_formations/groups_table',
           locals: {
             course: @course,
             groups: @filtered_groups,
             my_group: @my_group,
             requested_group_ids: @my_requested_group_ids,
             filters_active: @filters_active,
             list_state: @group_list_state,
             total_count: @total_group_count,
             displayed_count: @filtered_groups.count,
             show_all: @show_all
           }
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def filtered_groups
    groups = @groups.to_a
    status = params[:status_filter].to_s
    query = params[:search_query].to_s.strip.downcase

    groups = case status
             when 'confirmed' then groups.select(&:confirmed?)
             when 'draft'     then groups.reject(&:confirmed?)
             when 'invalid'   then groups.select { |group| helpers.group_size_state(group, @course) != :ok }
             else groups
             end

    if query.present?
      groups = groups.select do |group|
        group.group_name.to_s.downcase.include?(query) ||
          group.project_group_members.any? { |member| member.user.name.to_s.downcase.include?(query) }
      end
    end

    groups
  end

  def formation_filters_active?
    [params[:search_query], params[:status_filter]].any? { |value| value.present? && value != 'all' }
  end

  def list_state(base_list, filtered_list)
    return :matched if filtered_list.any?

    base_list.any? ? :no_matches : :empty
  end
end
```

### `app/views/shared/_header.html.erb` (spec §10, one line; the file was not visible)

Find the right-hand action group with `grep -n "Log out" app/views/shared/_header.html.erb` and add this line immediately before the **desktop** Log out button:

```erb
<%= yield :header_actions %>
```

Nothing else changes in the header. The bell is student-only and the settings gear is coordinator-only, so they never share the slot. Do not add `max-lg:hidden` unless the owner reverses the decision (spec §1).

---

## 5. File index (in place of raw reprints)

Each file's raw source is the text between its `BEGIN` / `END` banners in sections 1 and 2.

| File | Strict locals | Call sites | Status vs previous dump |
|---|---|---|---|
| `group_formations/show.html.erb` | none (reads ivars) | route | replaced (§11) |
| `group_formations/_groups_table.html.erb` | `course:, groups:, my_group:, requested_group_ids:, filters_active:, list_state:, total_count:, displayed_count:, show_all:` | `show` and the htmx branch of `GroupFormationsController#show` | replaced (§7) |
| `group_formations/_manage_dialog.html.erb` | `group:, course:, leader: false, label: nil` | table action cell (`leader: false`, coordinator/lecturer); my-group card (`leader: true`) | replaced (§14). Now trigger + `<dialog>` + placeholder only |
| `group_formations/_student_picker.html.erb` | `students:, verb:, url:, disabled_ids: [], limit: 6, show_instid: false` | `_create_group_dialog` ("Create"), `groups/edit` ("Invite", "Add") | replaced (§13) |
| `group_formations/_ungrouped_dialog.html.erb` | `students:, invited_ids:, manage: false` | `show` header | **new** (not in spec; built from the mockup and spec rules) |
| `group_formations/_create_group_dialog.html.erb` | `students:, url:` | `show` toolbar (coordinator/lecturer) | **new** (same) |
| `group_formations/_ungrouped_student.html.erb` | `student:, invited: false` | `_ungrouped_dialog`; `group_members#destroy` `turbo_stream.append` into `#ungrouped-students-list` | rewritten. Strict locals unchanged, instid removed (D11) |
| `group_formations/_notification.html.erb` | `avatar_name:, name:, action:, subtitle: nil, accept_url:, decline_url:` | bell (join requests, direct invites) | replaced (§12) |
| `group_formations/_status_pill.html.erb` | `confirmed:` | table rows, my-group card, `groups/edit` (coordinator/lecturer) | replaced (§6) |
| `shared/_person.html.erb` | `name:, tag: nil` | table detail, pickers, ungrouped rows, Manage members, join requests | replaced (§6) |
| `shared/_confirm_dialog.html.erb` | none | `show` once | rewritten (body is now a `<div>` because the controller injects `<p>` children) |
| `groups/edit.html.erb` | none (reads the four frame ivars) | lazy frame GET `edit_course_group_path` | rewritten (section 2) |
| `group_formations/_my_group_card.html.erb` | n/a | n/a | **DELETE**: inlined into `show` (spec §2 item 3) |
| `group_members/_dissolve_warning_modal.html.erb` | `member:, result:` | `group_members#destroy` `turbo_stream.append` into `#modals` | unchanged. Already a native `<dialog>` with `p-0` and an inner flex column |
| `courses/_tab_shell.html.erb`, `courses/_tab_strip.html.erb`, `courses/_flash.html.erb`, `shared/_empty_state.html.erb`, `shared/_table_empty_state.html.erb` | n/a | n/a | unchanged. `_table_empty_state` is no longer used by formation. Keep it, the Groups and People tables still use it |

---

## 6. Notes for the reviewer

### Deviations from the spec (all small, all easy to revert)

1. **`target: "_top"` also on the live placeholder frame in `_manage_dialog`** (the spec puts it only on the response frame in `groups/edit`). Turbo copies only the children of a response frame into the live frame, not its attributes, so a `target` on the response alone can be dropped. Forms inside the frame would then navigate the frame instead of doing a full visit and the redirect would blank the dialog. The Manage link carries its own `data-turbo-frame`, so it is unaffected.
2. **Detail row on an invalid group:** `bg-surface-hover/50` is applied only when the group is valid. The mockup (`tbody.grp:not(.invalid) tr.detail`) keeps the amber background on invalid groups. The spec applied the grey overlay to every group.
3. **`instid` in search text:** in `_student_picker` the `data-list-filter-text` haystack includes `instid` only when `show_instid` is true, and `_ungrouped_student` searches by name only. This is the same D11 intent: students cannot search by an ID they are never shown.
4. **Last-member removal copy** in `groups/edit` ("X is the last member, so G will be deleted.") is built in the view. The spec's `remove_confirm_body` has no last-member case and was kept verbatim. The mockup has the case.
5. **New files not covered by the spec:** `_ungrouped_dialog`, `_create_group_dialog`, `_ungrouped_student`, `shared/_confirm_dialog` and `groups/edit` were written from the mockup plus spec rules (native `<dialog>`, `p-0`, inner flex column, `GROUP_DIALOG_*` constants, one `button_to` per picker row, instid only in `show_instid` pickers, coordinator/lecturer wording). The approval switch uses `bg-outline` for its off state, which is the nearest border-grade token to the mockup's gray-300. Check it for contrast on `bg-surface`.

### Open items

- **Spec §17 is missing.** The document ends at §14, but §0 says "work in the order in §17". The order in plan §7 was followed instead.
- **Token check (spec §3) was not run.** It needs the repo: `grep -nE "surface-variant-deep|primary-container-alt|primary-container-ring|on-surface-muted|on-surface-disabled|on-surface-strong|warning-container-alt|warning-border|--color-warning|--color-error-hover|--color-success|--radius-card" app/assets/tailwind/application.css`. Also confirm `error-container`, `success-container`, `surface-hover`, `outline` and `--spacing-header`. Add anything missing to `@theme` using the plan §6.1 mapping. Add the new button variants (tonal, row, row-disabled, small outline, text, danger text) to `/styleguide` §5. `primary-container-hover` must have no remaining uses (it was in the old helper only).
- **`shared/_header.html.erb` was not visible.** Only the one-line `yield :header_actions` edit is specified (section 4).
- **Nothing has been executed.** There was no Rails app, no test run and no browser pass. Behaviour is by construction against the plan's contracts (§4.5 DOM ids, `turbo_stream` branches, `_top` frame).
- **Likely test churn:** labels changed ("Request" → "Request to join", filter "Draft" → "Not confirmed (n)", bell now always renders for students in an open formation). Leaders of a confirmed group no longer have Manage (Reopen only). Assertions that relied on the old "Leave" button for leaders must move to the Manage footer.
- **Dead ivar:** `@my_group_can_confirm` is still set and unused. It stays until the backend pass.

### Delete in the same PR

`app/views/group_formations/_my_group_card.html.erb`. The old `group_browse_filter_controller.js` and `combobox_modal_controller.js` are already deleted per plan §1. Run the plan §7 greps afterwards. The first one should now also be clean for `app/views/shared/_confirm_dialog.html.erb`.

### Quick self-checks run mentally against the spec rules

- No `gray-*`, `blue-*`, `amber-*`, `red-*`, `green-*`, no hex, no `<style>`, no inline JS in any file above.
- User-facing copy uses "coordinator" / "lecturer". The word "staff" appears only in variable names.
- Every dialog (`ungrouped`, `create group`, `manage`, `confirm`) is a native `<dialog>` with `p-0` and an inner flex column.
- Detail `<tr>` has no `display` utility, so `hidden` still wins on mobile (bug 1).
- Bell: `@incoming_join_requests` is used only when the current user leads their group (bug 3). `instid` is rendered only inside `show_instid: true` pickers (bug 4).