# ADR 002 — Method switches reproduce the overwrite rule with a confirmation

Date: 2026-08-28
Status: Accepted

## Context

Outside selection, choosing a lecturer cleared already-filled field values and
choosing a topic pre-filled them from the topic's `current_instance`; the page
then reloaded, and switching method warned "You'll lose your current form
data." Inside a modal there is no reload, so the same rule must run
client-side.

## Decision

Applying a picker selection mirrors the old server behavior in the browser:

- picking a topic sets `based_on_topic` to the topic id and pre-fills the
  template fields from the topic's current instance;
- picking a lecturer sets `own_proposal_<enrolment_id>` and clears the filled
  field values;
- switching method while unsaved content is present shows the existing
  "You'll lose your current form data" confirmation before applying.

## Consequences

- The rule lives in the Stimulus picker controller; server-side
  `?topic_id`/`?lecturer_id`/`clear_*` handling stays for deep links.
- Pre-fill data for topics must be embedded on the page (JSON/`data-*`),
  adding a per-topic field-value payload to `new`/`edit`.