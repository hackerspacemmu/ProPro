# ADR 006 — Preserve course-config gating in the method section

Date: 2026-08-28
Status: Accepted

## Context

The method section is gated by `@course.toggle_topics || !@course.solo_supervisor?`
and internally varies by course config: solo supervisor courses have no
lecturer card and default to `own_proposal_<sole lecturer>`; `toggle_topics`
off hides the topic card entirely. The mockup shows only the happy path —
both cards — as if every course had both choices.

## Decision

The two-card design still honors every course config. Solo courses show only
the topic card when topics are on (own-proposal default otherwise); topic
cards vanish when `toggle_topics` is off; the section itself stays hidden when
neither choice exists. "Current gating" is the spec, not the mockup.

## Consequences

- The redesign cannot accidentally introduce a lecturer picker or topic
  picker where the course forbids it.
- Test coverage must include solo-supervisor and topics-off variants, since
  they exercise the less-common branches.