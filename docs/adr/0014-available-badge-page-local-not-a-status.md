# ADR 014 — "Available" swaps the status pill in the Topics Directory, page-local

Date: 2026-09-06
Status: Accepted

## Context

The mockup draws an "Available" pill on topics-directory rows where the app's
rows normally render a status pill. `Topic#status` (`app/models/topic.rb:20`)
is a hard 4-value enum — `pending`/`approved`/`rejected`/`redo`
(`not_submitted` never renders) — and it is the real approval state every role
reads. Adding `available` as a status would be a breaking migration touching
mailers, CSV export, `SupervisorCapacityCalculator`, and `TopicPolicy`.

The audience for this page is browse-first (ADR 013): students shopping
topics to propose to. Approved topics are all they can see (ADR 013, the
scope policy), so for students the only actionable distinction left on this
page is claimed vs. unclaimed — which is exactly what the mockup's pill
conveys.

The mockup shows the pill green on every row; two blue rows under the pinned
"(You)" group were discussed and confirmed as an authorial artifact — the
pill is always green.

## Decision

1. `Topic#available?` = `approved? && proposed_project_instances.none?`
   (`proposed_project_instances`, `app/models/topic.rb:15`, populates when a
   student picks the topic via `source_topic_id` from the browse flow). Plain
   model method — no migration, no enum change.
2. In Topics Directory rows only, the status pill is **replaced by** green
   "Available" when `available?`. Rows that are not available keep their real
   status pill: approved-and-claimed shows "Approved"; a lecturer's own
   pending/redo/rejected topics in the pinned "(You)" group keep their status
   pills. Students only ever see approved topics, so on their view an
   approved row reads either "Available" or "Approved".
3. Always green. The mockup's two blue "(You)" pills are not reproduced.
4. The replacement is additive, not a fork: `_row_item`'s existing
   `pill_label` local already overrides the label, and approved already
   colors the pill/icon green — so `_topic_card` gains an optional
   `available_pill:` local (default `false`) that passes
   `pill_label: "Available"` when true and `topic.available?`. `_row_item`
   needs no pill change at all; every non-directory call site is
   byte-identical. (`_row_item` does gain one unrelated fix — the meta-line
   separator skips the leading "•" when `meta_parts` is empty, needed for the
   grouped rows' `hide_owner:`.)
5. `available?` is a display concern only — never a substitute authorization
   check. `TopicPolicy::Scope` stays the only gate (ADR 004, ADR 013).

## Consequences

- Approved-unclaimed rows read exactly like the mockup: green "Available".
- Claimed/pending/redo/rejected rows keep their informative status pill — no
  approval signal is lost on the page, so the swap is safe for coordinators
  and lecturers reviewing statuses.
- One tiny model method, zero migration, zero status-enum change.
- Costs: `proposed_project_instances.none?` per approved row is an extra
  association query per row; fine at present scales (no pagination, ADR 013),
  worth an eager-load if the page grows.

## References

- ADR 004 — `available?` does not weaken authorization-gating authority.
- ADR 013 — the browse-first framing that justifies the swap.
- Plan: `docs/topics_directory_refactor_plan.md`, §0 Decision Log, §6.