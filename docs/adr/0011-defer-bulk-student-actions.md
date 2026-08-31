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
  - Email = client-side `mailto:` compose (also serves as re-send invite),
  - Remove = existing `EnrolmentsController#destroy` for that row;
- no bulk endpoint, no server-side email, no N-of-M affordance.

This ADR records the deferral so the mockup's select-all / bulk widgets are not
later misread as regressions or as implemented-but-broken.

## Consequences

- No new backend surface; the refactor remains a view/data reorganization.
- A future bulk session still fits the shipped row layout — the single-select
  checkbox is the migration seam.
- Then-open questions for that session: batch-unenroll must mirror the
  grouped-course semantics (membership cleanup, group dissolution); the bulk
  email mechanism (mailto vs app mailer) is unresolved.
- Anyone reading the mockup should consult this ADR before "implementing" the
  visible bulk UI.