# ADR 011 — Defer bulk student actions on the People tab (select-all / bulk remove / bulk email)

Date: 2026-08-31
Status: Accepted

## Context

The `ProPro_Design/people_tab.html.erb` mockup shows a select-all checkbox, an
Actions dropdown ("Email students" / "Remove"), and per-row checkboxes. This
refactor's Students section keeps the mockup's row layout but deliberately does
not ship the bulk layer: single-select only, select-all removed. Bulk Remove
would need a coordinated batch-unenroll endpoint (including the grouped-course
membership cleanup semantics in `EnrolmentsController#destroy`), and bulk Email
would need a server-side mailer flow — both new backend surface with
destructive / nuisance semantics. The refactor mandate is to reorganize the tab
surface against existing enrollment machinery, not to build bulk operations.

## Decision

Select-all, bulk remove, and bulk send-email are deferred to a future session.
This session ships:

- a per-row single-select checkbox (radio-style), with no select-all control;
- the Actions dropdown acting on the ONE selected row:
  - **Email** dispatches per row: an unregistered (invited) row
    (`!user.has_registered`) calls the real server action
    `UserController#resend_invite` (`POST /user/:id/resend_invite`), which
    finds-or-creates the `Otp` and sends `GeneralMailer.ProPro_Invite` with a
    working claim token; a registered row opens a client-side `mailto:` compose.
    These are two different features wearing one dropdown label, and both are
    the real behavior — `mailto:` alone does not (and cannot) re-send an invite.
    The resend path is also what preserves the only re-send-invite surface after
    the refactor deletes `_participants_table.html.erb` (its lines 137/271 are
    the sole callers of `resend_invite_path` today).
  - **Remove** = existing `EnrolmentsController#destroy` for that row. Because
    that action currently authorizes solely on a forgeable `params[:coordinator_id]`
    (`app/controllers/enrolments_controller.rb:8` checks the parameter, never
    `current_user`), this refactor ships the IDOR fix in the same ticket:
    drop `coordinator_id`, authorize with
    `current_course.coordinator_ids.include?(current_user.id)`, and scope the
    enrolment find to the course. This mirrors the fix already shipped on
    `feat/student-grouping-crud` so the later merge is a no-op here.
- no bulk endpoint, no server-side bulk email, no N-of-M affordance.

This ADR records the deferral so the mockup's select-all / bulk widgets are not
later misread as regressions or as implemented-but-broken.

## Consequences

- No *unplanned* new backend surface; the only backend change is the
  authorization self-contained IDOR fix above.
- A future bulk session still fits the shipped row layout — the single-select
  checkbox is the migration seam.
- Then-open questions for that session: batch-unenroll must mirror the
  grouped-course semantics (membership cleanup, group dissolution); bulk email
  mechanism (mailto vs app mailer) is unresolved per-student.
- Any future bulk route should follow the existing top-level convention —
  `config/routes.rb:14` is `resources :enrolments, only: [:destroy]`, not
  nested under courses; `course_id` travels as a required parameter, not path
  nesting.
- Anyone reading the mockup should consult this ADR before "implementing" the
  visible bulk UI.