# ADR 0020 — Copy-topic provenance: record the source, show it, optionally auto-approve

Date: 2026-10-10
Status: Accepted

> Note: `docs/adr` is gitignored (as of `59042816`); this record is local-only
> by repo convention. The tracked decision record is `docs/revert_copy_topic.md`.

## Context

A topic created via the "Reuse details from another topic" modal used to know
where it came from. `TopicsController#create` recorded the **source topic** and
each copied field's origin; `topics/show` rendered a "Copied from" indicator and
a source-vs-current diff; and, when the coordinator had enabled
"Auto-approve unchanged copied topics?", a copy submitted with values identical
to its source was created `approved` instead of `pending`.

Commit `67117099` ("Update schema") deleted that write path as collateral while
cleaning up unrelated tables. It left every other layer intact — the columns
(`projects.source_topic_id`, `project_instance_fields.source_field_id`,
`courses.auto_approve_copied_topics_without_changes`), the course-settings
toggle, and the indicator/diff markup — so the settings UI kept promising a
behavior the backend no longer performed, and the "Copied from" markup stopped
reaching the page because `topic.source_topic` was always `nil`.

Two data paths share the name "source topic" but never collide:

- **Topic-copy provenance** — the topic row's `source_topic_id` (topics share
  the `projects` table), read as `topic.source_topic` for the indicator, the
  diff, and the auto-approve check.
- **Method picker / "Base on a Topic"** — the project instance's
  `source_topic_id` (`project_instances` table), read as
  `project_instance.source_topic` for "Based on Topic". Its choice travels as
  the stringly-typed `based_on_topic` param.

## Decision

Restore the write path **verbatim** from the last good commit (`24da0c05`),
keeping the feature's original contract and all of its gates. `docs/revert_copy_topic.md`
is the working plan.

- `TopicsController#create` reads `params[:source_topic_id]`, stores it on the
  topic, stores each field's `source_field_id` from `params[:source_fields]`,
  and applies the auto-approve branch:
  `status = :approved if status == :pending && source_id &&
  @course.auto_approve_copied_topics_without_changes? &&
  topic_unchanged_from_source?(source_id, params[:fields])`.
- `topic_unchanged_from_source?` is restored as-is.
- The new `copy_topic_controller.js` writes the `source_fields[...]` hidden
  inputs its predecessor `overlay_controller.js` used to.
- **UI placement.** The **source-vs-version-1 comparison** sits on the
  **Compare Versions** tab (`topics/show` panel-compare), sharing the version
  diff's **diffy treatment**: a shared `_diff_grid` partial, with pills
  `[source topic title] ⇄ Version 1 (Latest)` instead of `Version N ⇄ Version
  N+1`. It is gated to **single-version copied topics** visible to
  `coordinator || topic.owner` (`@instances.size == 1 && @topic.source_topic.present? &&
  (@is_coordinator || @topic.owner == current_user)`); when the gate fails the
  ordinary version comparison renders instead (they never render together). No
  card header — pills and grid only. The Overview/Details panel hosts only the
  "Copied from" indicator; the diff no longer lives there.
- **"(Current)" → "(Latest)"** throughout the topic and project show pages: the
  version-selector option labels (`1 of N (Latest)`) and the version-diff right
  pill. "Latest" marks the newest version without the context-dependent
  "current" reading.
- No schema or migration changes (all columns already exist). No `TopicPolicy`
  changes (byte-identical). The "Copied from" indicator stays in the Details
  panel with its same gate; only the underlying data changes.

Two known limitations are **accepted deliberately**, matching the original
behavior:

- **Label matching.** "Unchanged" is judged by comparing each submitted value
  to the source's field with the same `project_template_field.label`
  (downcased/stripped), not by template-field id. Fragile if labels collide or
  are renamed, but it is the original contract.
- **Version 1 only.** Only `create` records `source_field_id`. Because the
  comparison is gated to single-version copies, the information loss after an
  edit is self-consistent: a copied topic that has moved to v2+ never shows the
  comparison at all, rather than showing a degraded one. Extending `update` to
  carry provenance forward is out of scope.

## Consequences

- Copying a topic restores its provenance end-to-end: the "Copied from"
  indicator (Details panel), the source-vs-current diff (Compare Versions tab,
  version 1), and the honor of the
  "Auto-approve unchanged copied topics?" setting (which previously saved but
  was never read).
- The method picker / `based_on_topic` path is untouched and unaffected.
- Coverage: a controller test locks in the three `create` branches
  (unchanged+on → `approved`, changed → `pending`, off → `pending`) and the
  `source_topic_id` / `source_field_id` writes; the copy-topic system test
  asserts the indicator on Details and the diff on the Compare Versions tab.
- Future cleanups (a real column for the proposal method instead of the
  encoded `based_on_topic` string; provenance on later versions; id-keyed
  matching) are deferred, not abandoned.

## References

- `docs/revert_copy_topic.md` — working plan with verbatim code
- Regression: `67117099`; last good: `24da0c05`
- Migration: `db/migrate/20260701144548_add_source_topic_to_topics.rb`
- Related glossary: **copied topic**, **source topic**,
  **auto-approve unchanged copy** (CONTEXT.md)