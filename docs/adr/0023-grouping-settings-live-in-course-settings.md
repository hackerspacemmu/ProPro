# ADR 0023 — Grouping settings live only in Course Settings

Date: 2026-10-21
Status: Accepted

## Context

The student self-grouping feature grew its own settings surface: a
coordinator `<details>` panel at the top of the grouping workspace
(`/courses/:course_id/project_groups`) with its own form, its own
`project_groups#update_settings` endpoint, and its own copy of the
grouping rules. Meanwhile the Course Settings page grew a **Grouping**
section of its own (Student Self-Grouping, Beta) with the same fields,
posted through `courses#handle_settings`.

After `main` was merged into `feat/student-grouping-crud` the two
surfaces collided head-on:

- The workspace panel rendered in the **pre-redesign** markup
  (`new_tailwind` stylesheet, which `main` deleted), so it no longer
  matched the rest of the app.
- It was the only place on the workspace page that told a coordinator
  whether grouping was on, which mode the course was in, and the
  min/max limits — but it was also a second, differently-shaped editor
  for settings that Course Settings already owns.
- The two editors disagreed on shape (`courses#handle_settings` reads
  nested `course[...]` params; `project_groups#update_settings` reads
  flat params) and on behaviour, so the same course could be left in a
  different state depending on which form was used last.

The two modes also had three names in the tree at once — "Default" /
"Final student list" on the Course Settings form, "Default mode" /
"Auto-Eligibility mode" on the workspace page, and "Default mode" /
"Auto-Confirmability mode" in
`Queries::GroupSizeConfirmabilityCalculator`.

## Decision

**Course Settings is the only grouping-settings UI.** The workspace
panel is deleted, and the mode vocabulary is fixed.

- **One editor.** The Grouping section of `courses/settings.html.erb`
  (Student Self-Grouping, Beta) is the only place grouping is
  configured. `courses#handle_settings` is the only write path with a
  UI.
- **The workspace page keeps a status bar, not a form.** The
  coordinator `<details>` panel is replaced by a read-only bar showing
  the window state, the mode, and the min/max limits, plus a
  **Grouping settings** link to `settings_course_path(@course)` for
  anyone who passes `CoursePolicy#manage_groups?`. The bar is shown to
  every viewer, so students and lecturers keep seeing the mode.
- **The two modes are named "Default mode" and "Auto-Confirmability
  mode"** — the calculator's wording, which describes what the mode
  actually checks (whether a group size may be confirmed) rather than
  the coordinator's mental model ("my list is final"). The boolean
  attribute stays `student_list_finalised`; only the user-facing text
  changes. Course Settings' "Student list mode" section header becomes
  "Grouping mode".
- **The finalised-list lock is `main`'s, and it stays.** Once a course
  is persisted with grouping enabled in Default mode, the
  Auto-Confirmability radio is disabled and cannot be selected. The
  reverse direction (Auto-Confirmability → Default) *is* allowed and
  goes through `Course#revert_to_default_mode!`, which destroys draft
  groups and leaves confirmed groups alone. Turning grouping off
  entirely (`Course#disable_grouping!`) also destroys draft groups.
- **`project_groups#update_settings` is kept but is no longer
  reachable from any UI.** It is a second write path for the same
  settings and should be deleted; it is kept here only so the merge
  does not have to touch the route table. Nothing renders a form for
  it.

## Consequences

- There is exactly one place to learn what the grouping settings are
  and one place to change them.
- The workspace page no longer carries the old stylesheet or a second
  copy of the form, so it stops drifting from the app's design.
- Coordinators lose the ability to toggle grouping without leaving the
  workspace; they get one click to Course Settings instead.
- `project_groups#update_settings` is dead weight — a route with no
  form. It is recorded here so the next reader knows it is deliberate
  debt and not an oversight.
- The Auto-Confirmability mode cannot be entered once a course has
  been saved in Default mode. If a coordinator imported the wrong
  student list, they must turn grouping off and back on rather than
  flipping the mode.

## Known debt (out of scope, listed only)

- `project_groups#update_settings` should be deleted along with its
  route (`patch :update_settings`).
- The grouping workspace page still carries the pre-redesign markup;
  only its settings panel was removed. A restyle to the current design
  system is separate work.

## References

- ADR 0022 — project and topic tabs are routes (the route-per-tab
  pattern the two group surfaces also follow; its "known debt" list
  names the `groups` / `project_groups` naming overlap)
- `app/services/queries/group_size_confirmability_calculator.rb` — the
  two modes' rules, and the source of the "Auto-Confirmability" name
- `app/views/courses/settings.html.erb` — the Grouping section
- `app/views/project_groups/index.html.erb` — the status bar
