# ADR 004 — ProjectPolicy is authoritative; add no view-level checks

Date: 2026-08-28
Status: Accepted

## Context

Both `main` and `refactor/design` grant coordinators `update?` on projects
(`project_policy.rb`), including approved/locked ones. The redesign asked
whether the method section should be hidden from coordinators; earlier notes
claimed the branches already diverged here. A line-by-line diff shows they
**do not** diverge — the coordinator grant exists on both.

## Decision

Do not invent view-level authorization. The views render exactly what the
policy permits: students editing their own proposal, coordinators viewing
approved/locked forms in a readonly state derived from `approved?` and
`free_edit`. No new checks are added or removed.

## Consequences

- No risk of a regression hiding or exposing an action that policy allows.
- "Readonly" is expressed in markup, not authorization.