# ADR 0027 — The formation window is derived, not stored

Date: 2026-11-10
Status: Accepted (supersedes parts of ADR 0023; amends ADR 0026)

## Context

The grouping window had three columns: `grouping_enabled`,
`grouping_opens_at` and `grouping_closes_at`, plus a boolean
`grouping_open` that duplicated the first and never changed when the end
date passed. Nothing flipped it, so raw reads drifted after close. The
Grouping section of Course Settings exposed an "Open from" date and a
mode-card picker ("Default" / "Auto-Confirmability"), names that did not
match what coordinators were actually deciding.

The only production course with grouping on is a disposable testing
course the owner is willing to delete, so no data migration preserves
the old closed state. Courses with grouping on and no end date are open
once the columns drop.

## Decision

**The window is computed from the enable switch and the optional end
date.**

- `Course#grouping_window_open?` is `grouping_enabled? && (grouping_closes_at.nil? || Time.current <= grouping_closes_at)`.
  Enabling grouping opens it immediately; an end date only closes it.
- `grouping_open` and `grouping_opens_at` are dropped. No course can be
  "enabled but not yet open".
- Turning grouping off still clears `grouping_closes_at`; saving settings
  never changes the window by itself.
- The Grouping section is rebuilt around two switches: **Student
  self-grouping** (`grouping_enabled`) and **Prevent leftover students**
  (`student_list_finalised`). Min/max sizes stay optional, the
  distribution preview appears with Prevent leftover students, and
  Student Access carries only an optional **End group formation** date
  with Set date / Remove date. The mode cards, the finalised-list lock
  and the "Open from" date are gone.
- `student_list_finalised` keeps its name until the vocabulary pass; only
  the UI label changes.

## Consequences

- One source of truth: every surface asks `grouping_window_open?`.
- A course with grouping enabled and no end date is open from the moment
  it is enabled; there is no scheduled-open state.
- ADR 0026's "before it opens" case no longer exists; the Groups tab
  shows unconfirmed groups only when grouping is disabled or the end date
  has passed.
- The old closed state is not preserved for the testing course with
  grouping on and no end date; it becomes open once the columns drop. The
  owner accepts this and may delete the course. No data migration was
  written.

## References

- ADR 0023 — grouping settings live only in Course Settings (superseded
  in part: mode naming, finalised lock)
- ADR 0026 — Groups tab visibility follows the formation window
- `app/models/course.rb` — `grouping_window_open?`
- `app/views/courses/settings.html.erb` — the Grouping section
- `db/migrate/20261110090000_remove_grouping_window_flags_from_courses.rb`
