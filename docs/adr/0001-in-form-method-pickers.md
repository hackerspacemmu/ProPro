# ADR 001 — In-form method pickers replace the link-out selection flow

Date: 2026-08-28
Status: Accepted

## Context

Selecting the proposal method (own proposal vs based on a topic) navigated
away from the form: "Change"/"Browse" went to `course_lecturers_path` /
`course_topics_path` carrying `from_edit_project`/`from_new_project`/
`project_id`, and the "Propose to this Lecturer" / topic pages bounced back
with `?lecturer_id`/`?topic_id`, forcing a page reload. The new full-screen
form is self-contained and the mockup shows Change/Browse as in-form actions.

## Decision

The "Propose to Lecturer" and "Base on a Topic" cards open in-page modal
dialogs (native `<dialog>` + Stimulus, reusing the existing modal pattern)
that list lecturers with capacity and selectable topics. Picking applies the
selection in place. The `based_on_topic` hidden-field contract with
`create`/`update` is unchanged.

## Consequences

- No page reload on method change; selection state is client-side.
- The external propose links on `lecturers/show` and topic pages no longer
  drive this entry path, but their `?lecturer_id`/`?topic_id` params remain
  supported by `new`/`edit` controllers (e.g. deep links still work).
- The pickers need server-side data on the form page: lecturers + capacity
  (already loaded) and topics with their pre-fill field values (added).