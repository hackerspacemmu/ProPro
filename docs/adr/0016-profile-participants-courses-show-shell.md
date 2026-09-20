# ADR 016 — Course participant profiles mirror the courses/show shell and reuse the flat proposal row

Date: 2026-09-19
Status: Accepted

## Context

`courses/profile.html.erb` (the student/group profile reached from the course's
People/Groups tables) had drifted into a distinct visual language from the rest
of the app: it lived on `bg-gray-50`, used its own `w-[95%] mx-auto` main
sections, and rendered the Current Project through the old full project card
(`courses/_project_card` + `_project_card_contents`). That card also powered the
two project/proposal sections on `lecturers/show`.

At the same time `courses/show` had been rebuilt as a white internal-scroll panel
(`main.flex-1.bg-white.rounded-tl-panel.h-[calc(100vh-var(--spacing-header))]`)
with an inline `shared/sidebar` in its own `<div class="flex">`, and a flat row
list item (`projects/_proposal_list_item` → `shared/_row_item`) had become the
standard way to render a proposal/project in a list. The design mockup
(`ProPro_Design/profile_mockup.html.erb`) specified a Classroom-style centered
column (`max-w-5xl`) with a hero (banner band + overlapping avatar), a two-cell
facts strip (Project Status | Supervisor) split by a hairline, and Group Members
as one divided list.

## Decision

- **Profile page chrome** = the `courses/show` shell: `content_for :body_class,
  "bg-surface-tint"`, `shared/sidebar` rendered inline inside the page's own
  `<div class="flex">`, and `main.flex-1.bg-white.rounded-tl-panel.
  overflow-x-hidden.overflow-y-auto.h-[calc(100vh-var(--spacing-header))]`
  (no `border-t border-l` — the mockup's artificial border pokes out of the
  rounded top-left corner, so it is not reproduced). Content lives in a centered
  `w-[95%] max-w-5xl mx-auto pt-8 pb-16` reading column.
- **Hero** mirrors the mockup per scenario: group = banner band + group name from
  the batched hero; student = banner band + overlapping avatar (`-mt-12`, then
  `sm:pt-14` in the identity row), name, email, and the coordinator-only Remove
  From Course pill top-right in the identity row. The hero itself carries the
  facts strip (Project Status pill + Supervisor), not a separate Profile
  Information card.
- **Group Members** is a single divided list (`divide-y divide-outline-variant`)
  with avatar + name + STUDENT ID (kept from the old view) + email, Classroom
  "People" style.
- **Current Project** reuses `projects/_proposal_list_item` (the same flat row as
  `courses/show` overview and `lecturers/show`) instead of `_project_card`. The
  caller passes `path:` (preserving `from_participant` / `participant_type` so
  the project-show breadcrumb still resolves to this profile) and
  `linkable: policy(project).show?`. The row renders only when the project has a
  `project_instance` (the old card was silently empty without one); otherwise
  `shared/_empty_state` shows "No project has been submitted yet."
- **`_project_card` removal** is global, not profile-only: the two remaining
  `_project_card` call sites on `lecturers/show` (Projects and Incoming Proposals)
  now render `projects/_proposal_list_item` in a divided list, keeping the
  lecturer-scoped path (`course_lecturer_project_path`) and the same policy gate.
  `_project_card` and `_project_card_contents` are deleted (zero call sites).
- Both partials are unchanged in behavior and keep their locals-only, ivar-free
  contracts so they stay reusable from any presenter or controller context.

## Consequences

- Profile and lecturers/project rows share one visual grammar with `courses/show`
  (flat rows, status-pill palette, white panel chrome); the old card grid is gone
  everywhere.
- Participant-scoped deep-links into the project show survive because the row's
  `path` is caller-supplied rather than derived inside the partial.
- Removing a project's `project_instance` history no longer crashes the profile
  render (guarded on `@current_instance`, matching the old silent-empty
  behavior).
- System/controller coverage was added for both profile scenarios and both
  `lecturers/show` sections, which previously had none.