# Revert Plan — Restore copy-topic provenance (indicator · diff · auto-approve)

Date: 2026-10-10
Status: Implemented (2026-10-10). Describe the planned revert — with one UI
decision layered on top at implementation time: the diff was moved from the
Details panel into the Compare Versions tab (version 1 only) and its copy
reworded. See "UI placement (decided during implementation)" below.

## Summary

Copying a topic (`topics/new` → "Reuse details from another topic") used to
record where the copy came from, show a **"Copied from"** indicator and a
**source-vs-current diff** on `topics/show`, and optionally
auto-approve a copy that was submitted unchanged. The **display half survives**
in the current design; the **write half** was deleted, so the feature is dead
end-to-end.

This plan restores the write half **verbatim from the last good commit**, with
no schema, migration, or policy changes.

## Regression

Introduced by commit `67117099` ("Update schema", 2026-07-27, branch history
shared with `main`). The schema diff in that commit is unrelated table cleanup
(dropping `ownerships`, `topic_responses`, `project_group_invites`,
`supervisor_variable_capacity_enabled`). The controller diff silently removed
the copy-provenance write path:

- `TopicsController#create` stopped reading `params[:source_topic_id]`,
  stopped writing `source_topic_id` on the topic, stopped writing
  `source_field_id` on each instance field, and stopped consulting the
  auto-approve setting.
- The private helper `topic_unchanged_from_source?` was deleted.

Every other layer was left intact, which is the tell that this was collateral,
not an intentional removal:

| Layer | State after `67117099` |
| --- | --- |
| `projects.source_topic_id` (topic provenance column) | still in `db/schema.rb` + migration `20260701144548` |
| `project_instance_fields.source_field_id` | still in `db/schema.rb` + migration |
| `courses.auto_approve_copied_topics_without_changes` | still in `db/schema.rb` + migration, model attribute + validation, and the `handle_settings` whitelist |
| Course-settings toggle "Auto-approve unchanged copied topics?" | still rendered (`courses/settings.html.erb:145-152`) |
| "Copied from" indicator markup | still rendered (`topics/_topic_overview.html.erb:30-40`) |
| `topics/_source_topic_diff.html.erb` | byte-identical to the last good commit |
| `TopicPolicy` | byte-identical to the last good commit |

Result today: the toggle renders, saves, and is copied between courses, but
**nothing reads it**; the indicator and diff markup render but are gated on
`topic.source_topic`, which is always `nil` because no copy ever records its
source. The UI promises a behavior the backend ignores.

**Last good state:** `24da0c05` (parent of `67117099`).

## Scope

In:

- Restore the copy-provenance write path in `TopicsController#create`.
- Restore the `topic_unchanged_from_source?` helper.
- Restore the `source_fields[...]` hidden-input writes in the new copy-topic
  Stimulus controller so the diff has something to compare.

Out (explicitly):

- **Schema / migrations.** Nothing to add; all columns exist.
- **Policies / gates.** Unchanged; restored code preserves the exact gates.
- **Method picker / `based_on_topic`.** Separate feature on a separate table;
  see below. Not touched.

(The diff was later restyled — diffy grid + pills + "(Latest)" label; that is
render work, not a gate or policy change. See "UI placement" below.)

## Change 1 — `TopicsController#create` (restore, verbatim)

`app/controllers/topics_controller.rb`. The current `create` is identical to
the last good version **except** for the four restored lines marked below.

```ruby
def create
  begin
    ActiveRecord::Base.transaction do
      status = @course.require_coordinator_approval? ? :pending : :approved

      source_id = params[:source_topic_id].presence

      status = :approved if status == :pending && source_id && @course.auto_approve_copied_topics_without_changes? && topic_unchanged_from_source?(source_id, params[:fields])

      @topic = Topic.create!(
        course: @course,
        owner: current_user,
        source_topic_id: source_id
      )

      title_value = nil
      params[:fields]&.each do |field_id, value|
        title_value = value if ProjectTemplateField.find(field_id).is_project_title?
      end

      @instance = @topic.topic_instances.create!(
        version: 1,
        title: title_value,
        created_by: current_user,
        status: status
      )

      params[:fields]&.each do |field_id, value|
        source_field_id = params.dig(:source_fields, field_id.to_s).presence

        @instance.project_instance_fields.create!(
          project_template_field: ProjectTemplateField.find(field_id),
          value: value,
          source_field_id: source_field_id
        )
      end
    end
  rescue StandardError
    redirect_to course_path(@course), alert: 'Topic creation failed'
    return
  end

  redirect_to course_topic_path(@course, @topic), notice: 'Topic created!'
end
```

Notes:

- `@topic` is created with the raw `source_topic_id` param, exactly as in the
  last good commit. Preserve verbatim; do not "improve" it in this change.
- `create` carries no `authorize` call in either version — preserved.

## Change 2 — restore `topic_unchanged_from_source?` (verbatim)

Add to the `private` section of `TopicsController` (deleted in `67117099`):

```ruby
def topic_unchanged_from_source?(source_id, submitted_fields)
  return false if submitted_fields.blank?

  source_topic = Topic.find_by(id: source_id)
  return false unless source_topic&.current_instance

  source_fields_by_label = source_topic.current_instance.project_instance_fields
                                       .includes(:project_template_field)
                                       .each_with_object({}) do |field, hash|
    label = field.project_template_field.label.to_s.downcase.strip
    hash[label] = field.value.to_s.strip
  end

  raw_submitted = submitted_fields.to_unsafe_h

  raw_submitted.all? do |field_id, value|
    target_field = ProjectTemplateField.find_by(id: field_id)
    return false unless target_field

    target_label = target_field.label.to_s.downcase.strip
    source_value = source_fields_by_label[target_label]

    value.to_s.strip == source_value
  end
end
```

## Change 3 — `source_fields[...]` hidden inputs (verbatim port)

`app/javascript/controllers/copy_topic_controller.js`, inside
`copyTopicsDetails()`, after `sourceFieldId` is resolved. The new controller
copies values into the main form but no longer records which source field each
value came from; without this, `_source_topic_diff` has no `source_field_id` to
compare against. Ported verbatim from the now-dead `overlay_controller.js`
(`app/javascript/controllers/overlay_controller.js:134-145`):

```js
const existingHidden = mainForm.querySelector(
  `input[name="source_fields[${fieldId}]"]`,
);
if (existingHidden) existingHidden.remove();

if (sourceFieldId !== "") {
  const hiddenInput = document.createElement("input");
  hiddenInput.type = "hidden";
  hiddenInput.name = `source_fields[${fieldId}]`;
  hiddenInput.value = sourceFieldId;
  mainForm.appendChild(hiddenInput);
}
```

`overlay_controller.js` is dead code (no `data-controller="overlay"` remains);
it is not restored or removed by this change.

## UI placement (decided during implementation)

Planned change 1–3 restored the data; the render side was then adjusted per
interview (the "Copied from"-pill + diff UI review):

- The **source-vs-current diff lives on the Compare Versions tab**
  (`topics/show.html.erb` panel-compare), where version comparisons belong. It
  replaces the version comparison for **single-version copied topics**: the
  gate is `@instances.size == 1 && @topic.source_topic.present? &&
  (@is_coordinator || @topic.owner == current_user)` — `create` is the only
  action that records provenance, so the comparison only ever applies to a copy
  that has not been edited to v2+. If the gate fails the version diff renders
  instead (one branch wins; the two never render together).
- **Diffy treatment.** The source comparison uses the same pill + two-column
  diff grid as the version diff (`_diff_grid` partial, extracted from
  `_compare_versions_tab`). Left pill = the **source topic's current title**,
  right pill = **Version 1 (Latest)**, joined by the `sync_alt` arrow — left
  being the old/red/deletions side, right the current/green. Unchanged rows
  show the shared no-changes state: "No field changes detected" + **"The copy
  matches its source topic."** No "Compared with the source topic" card header —
  pills and grid only.
- **"(Current)" → "(Latest)".** The version selector labels and the version-diff
  right pill now say "(Latest)" throughout the topic and project show pages
  (the review-action version dropdown 1 of N, and `_compare_versions_tab` in
  both topic and project variants). "Latest" marks the newest version without
  implying a context-dependent "current" reading.
- The **"Copied from" indicator stays in the Details panel** (`_topic_overview`)
  regardless of version and viewer.
- Empty-state matrix for the Compare Versions tab: unchanged single-version
  copy (eg. auto-approved) → diff-grid no-change state; single version, no
  source or non-gated viewer → "Only one version exists"; two or more versions
  → ordinary version diff.

## Gates and policies — unchanged (must stay)

All restored code keeps the exact gates from the last good commit. Reviewed and
confirmed identical:

| Gate | Location | Rule |
| --- | --- | --- |
| Indicator | `topics/_topic_overview.html.erb:30` | `topic.source_topic.present? && (course.enrolments.exists?(user: current_user, role: :coordinator) || topic.owner == current_user)` |
| Diff | `topics/show.html.erb` panel-compare | `@instances.size == 1 && @topic.source_topic.present? && (@is_coordinator || @topic.owner == current_user)` (renders `_source_topic_diff`); else the version diff |
| Auto-approve | `TopicsController#create` | `status == :pending && source_id && @course.auto_approve_copied_topics_without_changes? && topic_unchanged_from_source?(source_id, params[:fields])` |
| Change status | `TopicPolicy#change_status?` | `coordinator && course.require_coordinator_approval?` |
| Topic create | `TopicPolicy#create?` | `coordinator || lecturer` |
| Topics action gate | `before_action :toggle_topics` (except `index`) | unchanged |

`TopicPolicy` is byte-identical between `24da0c05` and HEAD — no edits.

## Schema and migrations — none

All three columns already exist and no migration is needed:

- `projects.source_topic_id` (topics share the `projects` table via
  `Topic.table_name = 'projects'`)
- `project_instance_fields.source_field_id`
- `courses.auto_approve_copied_topics_without_changes`

## Tests

Controller + system, extending the existing copy-topic coverage (not new
suites).

- `test/controllers/topics_controller_test.rb`
  - copied topic persists `source_topic_id`;
  - instance fields persist `source_field_id` when `source_fields[...]` is sent;
  - `auto_approve_copied_topics_without_changes` on + unchanged values →
    `approved`; any changed value → `pending`; setting off + unchanged →
    `pending`.
  - `topics/show` renders the source-vs-v1 comparison on the Compare Versions
    tab for a single-version copied topic: the `(Latest)` pills and the
    `del`/`ins` marked-up values; a topic with earlier versions, or a
    single-version copy viewed by a non-gated viewer, shows only the ordinary
    comparison (version diff / "Only one version exists").
- `test/system/topics/copy_topic_dialog_test.rb`
  - `topics/show` shows the "Copied from" indicator (Details) and — after
    clicking the Compare Versions tab — the source-title pill ⇄ "Version 1
    (Latest)" grid with the changed copy value, for the owner.

## Accepted limitations (decided, not open)

Restored verbatim, per ADR 0020 — both were the original behavior:

- **Label matching.** "Unchanged" is judged by comparing each submitted value
  to the source's field with the same `project_template_field.label`
  (downcased/stripped), not by template-field id.
- **Version 1 only.** Only `create` records `source_field_id`. Because the
  comparison is gated to single-version copies (see UI placement), the
  information loss after an edit is self-consistent: a copied topic edited to
  v2+ shows only the ordinary version diff, never a degraded source
  comparison. `update` / `instance_to_edit` is not extended by this change.

## Out of scope — future note (not part of this revert)

The proposal **method picker** (`projects/new` / `edit`) represents its choice
in a single hidden field, `based_on_topic`, whose value is a stringly-typed
`own_proposal_<enrolment_id>` or `<topic_id>`, parsed by
`ProjectsController#create` / `#update`. That is unrelated to topic-copy
provenance and is not touched here:

- Topic-copy provenance writes `projects.source_topic_id` on the **topic row**
  (read as `topic.source_topic`).
- The method picker writes `project_instances.source_topic_id` on the
  **project-instance row** (read as `project_instance.source_topic`).

Different tables, different associations, no collision. A future change could
give the proposal method a proper column instead of the encoded string; that is
deliberately deferred.

## References

- Decision record: `docs/adr/0020-copy-topic-provenance.md` — local-only;
  `docs/adr` is gitignored (as of `59042816`), so this plan doc is the tracked
  record.
- Glossary terms: **copied topic** · **source topic** · **auto-approve
  unchanged copy** (CONTEXT.md, tracked)
- Regression commit: `67117099` ("Update schema")
- Last good commit: `24da0c05`
- Migration: `db/migrate/20260701144548_add_source_topic_to_topics.rb`
- ADR 0019 — course tabs are routes (referenced for doc conventions only)
