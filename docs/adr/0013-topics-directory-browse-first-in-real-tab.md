# ADR 013 — Topics Directory: browse-first, rendered in the real Topics tab

Date: 2026-09-06
Status: Accepted

## Context

The mockup (and the first pass of the plan) framed the eventual Topics tab as
a **review** surface: an "Overview-active + To Review" tab strip and a
sidebar-chrome — a mirror of the Projects tab. But the mockup's top chrome is
stale scaffolding. Interview with the stakeholder reframed who this page is
for and why.

All three roles matter equally — coordinator, lecturer, student — and the
primary problem is **browse**, not review: students finding topics to propose
to, other lecturers browsing what topics exist. The mockup's stale chrome
(Overview-active tab, To Review tab, sidebar) is discarded.

## Decision

1. This pass touches only the content of the Topics tab
   (`_topic_directory_tab.html.erb` and its partials). The 4-tab bar in
   `courses/show.html.erb`, `tabs_controller.js`, and every other tab are
   off limits.
2. Audience is browse-first for all three roles; mockup fidelity is a goal,
   but layout choices are driven by browse, not by reusing the Projects
   review chrome.
3. `TopicPolicy::Scope` remains the only visibility gate, exactly as today
   (coordinator → all; lecturer → own-any + others'-approved; student →
   approved-only). The `student_access` / `lecturer_access` course settings
   are **not** consulted for topic visibility on this page — they aren't
   today either; they keep governing `ProjectPolicy`/lecturer-profile views
   unchanged. This is deliberate and documented so a future reader who
   expects those settings to matter here isn't surprised.
4. There is **no pagination** on this tab for now (few supervisors per
   course). Rendering everything is fine; the story of rendering everyone
   can hold is left open deliberately as a flagged future follow-up, not
   built this pass.
5. The Topics search is **not** wired into the `/` keyboard shortcut at all.
6. `require_coordinator_approval?` explanatory copy is dropped from this
   tab. The setting's behavior and logic are preserved — it still gates
   policies/flows — only its copy stops rendering here.
7. Layout follows the mockup: stacked action bar (`+ Create` top-left, the
   only Create door into topic creation, since `topics/index.html.erb` has
   none), full-width search pill, "Topic filter" M3 select + "Collapse all".
   Supervisor groups A→Z with newest-first rows; the current user's own
   supervisor group is pinned first with a "(You)" suffix for staff only
   (this replaces the old "My Topics" section). Zero-topic supervisors still
   render (mockup's Kevin row). No supervisor-capacity figures in headers.

## Consequences

- The tab bar stays untouched; no To Review tab, no Overview-active hack, no
  5th tab.
- Mockup fidelity is scoped to the tab's inner content; stale top chrome is
  not rebuilt.
- Grouping and pinning behavior is a new partial
  (`_topics_by_supervisor_list.html.erb`) mirroring the
  `_groups_table.html.erb` htmx pattern so the existing htmx swap branch in
  `CoursesController#show` can render it.
- No migration is introduced by this ADR (see ADR 014 for the only model
  addition).
- Future consideration: introduce pagination / "everyone can hold" only if
  a course actually exceeds a sane supervisor count.

## References

- ADR 004 (policy is authoritative) — scoping stays there.
- ADR 014 — the page-local "Available" pill swap (the lone model method this
  feature adds).
- Plan: `docs/topics_directory_refactor_plan.md`, §0 Decision Log.
