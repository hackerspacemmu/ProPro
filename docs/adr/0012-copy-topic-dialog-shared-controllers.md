# ADR 012 — Copy-topic modal reuses field-expand-modal by attaching two controllers to one element

Date: 2026-09-03
Status: Accepted

## Context

`topics/new` has a "reuse details from another topic" surface (`_copy_topic_overlay`
+ `_copy_topic_details`) backed by `overlay_controller.js`, a custom controller
that toggles CSS classes on a `fixed inset-0 ... opacity-0 pointer-events-none`
div. This pass rebuilds it as a native `<dialog>`. `overlay_controller.js` also
backs the unrelated course-settings-copy feature, so it can't be edited or
deleted here. In parallel, `field_expand_modal_controller.js` already implements
the exact closing behavior the dialog needs: a `close()` (`dialog.close()`) and a
`connect()`-wired backdrop-click-to-close (`closeOnBackdrop`).

The naive path would copy that closing logic into a fresh controller. That
causes the two dialog controllers to drift and re-lists the closing contract a
second time in the codebase.

## Decision

Attach both controllers to the same wrapper element —
`data-controller="field-expand-modal copy-topic"` — and give the `<dialog>` both
`data-field-expand-modal-target="dialog"` and `data-copy-topic-target="dialog"`.
Cancel and backdrop-click-to-close use `field-expand-modal#close` /
`field-expand-modal`'s automatic `closeOnBackdrop` as-is. The new
`copy_topic_controller.js` only supplies `open()` (one line: `showModal()`, since
`field-expand-modal#open` hard-requires a `<template>` in the trigger and writes
into `title`/`content` targets this dialog doesn't have) plus the four
topic-specific behaviors moved over from `overlay_controller.js` (`selectTopic`,
`updateDropdown`, `copyTopicsDetails`, `returnToList`).

Neither `overlay_controller.js` nor `field_expand_modal_controller.js` is
modified; `copy-topic` attaches alongside `field-expand-modal`, it doesn't
replace it.

## Consequences

- The `<dialog>` closing contract lives in exactly one controller
  (`field-expand-modal`), not two.
- `copy_topic_controller.js` stays small and single-concern (open + copy logic).
- Both shared controllers are left untouched, so the course-settings-copy
  feature and the existing field-expand dialog keep working.
- Relies on Stimulus supporting multiple `data-controller` values on one element
  and on a `<dialog>` being a target for more than one controller at once —
  both supported.
