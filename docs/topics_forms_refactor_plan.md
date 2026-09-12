# topics/new & topics/edit Refactor Plan (Design-Only Pass)

Grounded against `hackerspacemmu/ProPro` @ `main` (`244ef6d`), same approach
as `TOPICS_SHOW_REDESIGN_AUDIT.md`: copy the already-built projects/
components from `refactor/design` (local checkout, unpushed), swap in
topics' own data/logic, no controller/model/policy changes.

**Scope:** `app/views/topics/new.html.erb`, `app/views/topics/edit.html.erb`,
their field-rendering partial, and the "reuse details from another topic"
modal (`_copy_topic_overlay.html.erb` + `_copy_topic_details.html.erb`).

---

## 1. What's copyable vs. what's project-only

You listed four things already built on the projects side:
`template_fields`, `topics_picker`, `proposal_method`, `lecturer_picker`.
Checked what each actually is on `main` (the redesigned versions are on the
unpushed branch, but the underlying data/flow is the same):

- **`template_fields`** — the field-list renderer. **Copy this.** Same
  concept, same field types, same course-level template config, used by
  both Project and Topic forms already.
- **`proposal_method`**, and whatever it's been split into as
  `topics_picker`/`lecturer_picker` on your branch — these exist to let a
  **student choose a lecturer or an existing topic to base a *project*
  proposal on** (`_proposal_method.html.erb:120-181` renders `courses/topic_card`
  for a *selected* topic; the lecturer half shows capacity info from
  `SupervisorCapacityCalculator`). **None of this applies to topics/new or
  topics/edit.** A topic doesn't pick a lecturer or another topic to propose
  against — a lecturer just authors it. Don't wire any of these three into
  the topic forms; they're context for what exists on the projects side, not
  components topics needs.

So the actual copy list for this pass is **one component**
(`template_fields`) plus a **rebuild** of the copy-topic modal (§3), which
has no projects/ equivalent to copy from.

**One thing to *not* copy the habit of:** `_proposal_method.html.erb` takes
`course:` as a declared local (`<%# locals: (course:, ...) %>`, line 1) but
then reaches for `@course` directly anyway at lines 9, 21, 32, 111, 120. If
the copied `template_fields` partial is written cleanly (see §2), don't
carry this inconsistency over — it's a real gap between what the partial
claims to need and what it actually touches, and it's worth not repeating
per the Copeland locals-only rule this whole redesign has been following.

---

## 2. `template_fields` — copy map

**Source (`refactor/design`, local):** whatever `_project_new.html.erb` was
renamed/restyled to (per your note, now shared by `projects/show` and
`projects/edit` too — likely for rendering `free_edit` fields inline). On
`main` today it's `app/views/projects/_project_new.html.erb` (100 lines),
already locals-only: `template_fields:`, `field_values:`, `input_classes:`
— no instance variables referenced inside it. Good baseline to copy as-is.

**Destination:** one shared `app/views/topics/_template_fields.html.erb`
(or promote straight to `app/views/shared/` if you're ready — this partial
has zero model-specific logic in it, it only touches `field` objects and a
plain hash, so it's actually a stronger `shared/` candidate than anything
from the `show` redesign was, since it never references `@project`/`@topic`
even implicitly).

**Wire into both forms:**
- `topics/new.html.erb` — replace the inline `@template_fields.each` block
  (lines 79-184 today) with
  `render "template_fields", template_fields: @template_fields, field_values: {}, input_classes: input_classes`.
  Topics/new never has existing values to prefill from the server —
  the copy-topic flow fills values client-side after the fact (§3), so an
  empty hash is correct here, not a bug to chase.
- `topics/edit.html.erb` — same partial,
  `field_values: @existing_values` (topics_controller.rb:93-96 already
  builds this hash keyed by `project_template_field_id`, matching what the
  copied partial expects via `field_values[field.id]`). No controller
  change needed — `@existing_values` already exists, you're just passing it
  under the local name the shared partial uses.

Both current files independently duplicate the exact same
shorttext/textarea/dropdown/radio switch statement (`topics/new.html.erb:108-180`,
`topics/edit.html.erb:101-172`) — this copy is also a real DRY win on its
own, not just a style match.

---

## 3. The copy-topic modal — needs a rebuild, not a copy

`_copy_topic_overlay.html.erb` currently uses `data-controller="overlay"` —
a custom controller that toggles CSS classes on a `fixed inset-0 ... opacity-0
pointer-events-none` div (`overlay_controller.js`). **Not a `<dialog>`.** Per
your note, wire it up to the native pattern.

**Important:** `overlay_controller.js` is shared infrastructure — its
`selectSetting` method also backs the *course settings* copy feature
(`courses/_copy_course_details.html.erb`, same controller, different
methods). **Don't modify or delete `overlay_controller.js`.** That other
usage is out of scope and must keep working. Build a new controller for the
topic-copy modal instead of repurposing the shared one.

**Checked whether `field_expand_modal_controller.js` itself can just be
attached, not copied — and part of it can.** Stimulus allows multiple
`data-controller` values on one element, and a `<dialog>` can be a target
for more than one controller at once. So `close()` and `closeOnBackdrop()`
don't need to be reimplemented at all: put
`data-controller="field-expand-modal copy-topic"` on the wrapper (matching
the one place it's already used, `_project_details.html.erb:2`), give the
`<dialog>` both `data-field-expand-modal-target="dialog"` and
`data-copy-topic-target="dialog"`, and wire Cancel/backdrop to
`click->field-expand-modal#close` exactly as `_project_details.html.erb:123`
already does. Zero new code for closing, and `field_expand_modal_controller.js`
itself stays untouched (same "don't modify it, only attach to it" reasoning
as `overlay_controller.js` above — it's currently only used in one place,
but no reason to make it a two-purpose file when attaching alongside it
costs nothing).

**`open()` is the one piece that genuinely can't be reused as-is.** Its
whole job is template-cloning: `button.querySelector("template")`, and it
returns early doing nothing if there's no `<template>` in the trigger
button (`field_expand_modal_controller.js`, `open()`). It also assumes
`title`/`content` targets exist on the dialog and writes into them
(`this.titleTarget.textContent = ...`, `this.contentTarget.innerHTML = ""`)
— calling it against our dialog would throw, since our content is the
turbo frame itself, not a cloned template, and we're not giving it `title`/
`content` targets to write into. So the new `copy-topic` controller needs
its own `open()` — but because the dialog's content is already
server-rendered (not something to clone in), that method is one line:
`this.dialogTarget.showModal()`.

Net result: the new controller (`copy_topic_controller.js` — dropping
"modal" from the name since it's no longer the thing that owns the
modal-ness, `field-expand-modal` handles that half) only carries `open()`
plus the four topic-specific behaviors below. This is the same shape the
projects/show plan used for `record_update_modal_controller.js`, just
splitting out the part that's genuinely reusable instead of re-typing it.

**What has to survive the migration** (currently on `overlay_controller.js`,
needs to move to the new `copy_topic_controller.js`):
- `selectTopic` — clicking an approved-topic card sets the turbo frame's
  `src` to `new_course_topic_path(@course, source_topic_id: topic.id)`,
  loading step 2 (the merge form) into the same frame. This is what makes
  `TopicsController#new` special-case `source_topic_id` and return just the
  `_copy_topic_details` partial (`topics_controller.rb:75-78`) — keep that
  controller behavior exactly as-is, it's already view-agnostic.
- `updateDropdown` — live preview when picking which source field to copy
  a value from, scoped to the closest `.field-row`.
- `copyTopicsDetails` — the actual copy: reads every
  `select[data-target-field-id]` in the merge form, writes matching values
  into the *main* new-topic form's inputs (found via
  `document.querySelector("form[action*='/topics']")`), then closes the
  modal. Preserve this exactly; it's the feature.
- `returnToList` — "← Back" inside the merge step, restores the frame's
  original content.

**What changes:**
- Wrapper div: `data-controller="overlay"` becomes
  `data-controller="field-expand-modal copy-topic"`.
- Trigger button ("Reuse details from another topic"):
  `data-action="click->overlay#open"` becomes
  `data-action="click->copy-topic#open"` (the new one-liner).
- Cancel button and any explicit close affordance:
  `data-action="click->overlay#close"` becomes
  `data-action="click->field-expand-modal#close"` — reused directly, not
  reimplemented.
- Backdrop click-to-close: comes free from `field-expand-modal`'s
  `connect()` — no action wiring needed at all, same as
  `_project_details.html.erb` gets it for free today.
- The manual `opacity-0`/`pointer-events-none` class toggling and the
  `document.body.style.overflow` scroll-lock in `overlay_controller.js`
  (line 15) have no equivalent to port — native `<dialog>` via `showModal()`
  handles scroll-locking on its own, so that line's job just goes away
  rather than needing a replacement.
- Everything inside the dialog (the turbo frame, the two partials'
  internal markup) restyle to match the new design system, but the
  step-1-list → step-2-merge-form flow via `turbo_frame_tag "overlay_content"`
  doesn't need to change structurally.

**Two things worth flagging, found while tracing this (not to fix this
pass — view-only scope, and one of these may need a controller change
anyway):**

1. `_copy_topic_details.html.erb:2` wraps everything in
   `form_with url: import_details_course_path(target), method: :post`, but
   the actual "Copy Details" button (line 124) is `type="button"`, not
   `type="submit"` — it only ever triggers `copyTopicsDetails()` via JS, so
   this form is never actually submitted. Checked `CoursesController#import_details`
   (`courses_controller.rb:342-361`): it only handles `mode: 'settings'` and
   `mode: 'template'`, both course-level — there's no branch for topic-field
   copying at all. This `form_with` wrapper looks like it was copy-pasted
   from `courses/_copy_course_details.html.erb` (which posts to the same
   route for a real reason) and never trimmed down. Likely safe to drop the
   `form_with`/`f.hidden_field` wrapper entirely and just keep the `<div>`
   content, but flagging rather than doing it unprompted since it touches
   how the partial's markup is structured.
2. `TopicsController#create` (`topics_controller.rb:101-129`) never reads
   `params[:source_topic_id]` or `params[:source_fields]` — only
   `params[:fields]`. Since `copyTopicsDetails()` writes copied values
   straight into the main form's `fields[...]` inputs, the *values* do make
   it through on submit — but the `source_topic_id` hidden field
   (`main_source_topic_id`, `new.html.erb:71`) appears to never get read
   server-side, meaning the new topic's `source_topic` association may not
   actually get set via this flow. That's a controller-side question, not a
   styling one — flag it for a follow-up ticket, don't chase it in this
   pass.

---

## 4. Gates in scope for these two views

Shorter list than `show` — these forms don't have much conditional logic
beyond field rendering and the copy-modal's own gates:

**`topics/new.html.erb` / `topics/edit.html.erb`:**
- `field.required` — asterisk + `required:` HTML attribute per field.
- `field.free_edit` — "Editable Post-Approval" badge next to the label.
- `field.hint.present?` — optional hint text under the label.
- `field.field_type` switch (`shorttext`/`textarea`/`dropdown`/`radio`/else)
  — which input renders. This is the bulk of both files and is exactly what
  moves into the shared `_template_fields.html.erb`.

**`_copy_topic_overlay.html.erb`:**
- `@approved_topics.present?` — grid of topic cards vs. "You don't have any
  approved topics yet" empty state. Note `@approved_topics` (`topics_controller.rb:80-83`)
  is scoped to `Course.managed_by(current_user)` — i.e. courses *this
  lecturer coordinates/teaches*, not every course in the system. Preserve
  that scope implicitly by not changing the controller; just know the list
  you're rendering is already access-controlled upstream.
- `params[:show_all_course_topics] == "true"` — checkbox toggling whether
  the list includes topics from all of this lecturer's coordinated courses
  or just the current one.

**`_copy_topic_details.html.erb`:**
- `initial_field.present?` + the dropdown/radio `allowed_options.include?`
  check (lines 30-38, repeated at 53-62 for the `valid_options` list) —
  decides whether a source field's value is even offered as a copy option
  (a dropdown/radio field can only be pre-filled from a source value that's
  still a valid option in *this* course's template, not just copied blindly).

---

## 5. Prompt for the implementation agent

> You are refactoring `app/views/topics/new.html.erb` and
> `app/views/topics/edit.html.erb`. Extract the shared field-rendering
> block from both into `app/views/topics/_template_fields.html.erb`,
> copied from the equivalent `projects/` partial (locals-only:
> `template_fields:`, `field_values:`, `input_classes:` — see
> `TOPICS_CREATE_EDIT_REFACTOR_PLAN.md` §2 for the exact wiring on each
> call site). Do **not** wire in `proposal_method`, `topics_picker`, or
> `lecturer_picker` — those are project-only concepts and don't apply here.
>
> Rebuild the "reuse details from another topic" modal
> (`_copy_topic_overlay.html.erb` + `_copy_topic_details.html.erb`) to use
> a native `<dialog>`. Don't reimplement closing behavior — attach the
> existing `field-expand-modal` controller alongside a new, small
> `copy_topic_controller.js` on the same wrapper (Stimulus supports
> multiple `data-controller` values on one element), and reuse its `close()`
> and automatic backdrop-click-to-close as-is, same as
> `_project_details.html.erb` already does. The new controller only needs
> its own `open()` (one line: `showModal()` — `field-expand-modal#open`
> can't be reused, it hard-requires a `<template>` in the trigger button
> and writes into `title`/`content` targets this dialog doesn't have) plus
> `selectTopic`, `updateDropdown`, `copyTopicsDetails`, and `returnToList`
> moved over from `overlay_controller.js`. Leave `overlay_controller.js`
> itself untouched — it also backs the unrelated course-settings-copy
> feature, and `field_expand_modal_controller.js` untouched too — attach to
> it, don't edit it. Full behavior list is in §3.
>
> You are not the controller/model/policy agent — no changes to
> `app/controllers/topics_controller.rb`, `app/controllers/courses_controller.rb`,
> or any model this pass, even for the two flagged findings in §3 (the
> unused `import_details` form wrapper, the unread `source_topic_id` in
> `create`). Note them in your PR description; don't fix them.
>
> There are no existing automated tests covering topics/new, topics/edit,
> or the copy-topic flow (checked — none exist on `main`), so there's
> nothing to break here in the way the `show` refactor had to worry about.
> Worth adding basic system test coverage for the new `<dialog>` interaction
> as part of this work, but that's a nice-to-have, not a blocker.

---

## 6. Still true from before

Same guardrails as the `show` doc: work in the local `refactor/design`
checkout regardless of push status; keep new/copied partials locals-only so
a future `shared/` promotion (this one's an even better `shared/` candidate
than `show`'s partials were, per §2) is a clean move, not a rewrite.