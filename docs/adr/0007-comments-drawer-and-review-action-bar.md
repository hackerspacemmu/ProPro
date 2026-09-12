# ADR 007 — Comments as a drawer, not a fourth tab (pinned review action bar)

Date: 2026-08-29
Status: Accepted

## Context

The master plan (`docs/projects_show_refactor_plan.md` §7 item 4, Ticket 4)
and the `ProPro_Design/projects_show_responsive.html.erb` mockup said: on small
screens the comments pane becomes a **4th tab** in the tab bar. That was
rejected. Three text tabs already nearly fill a narrow viewport; adding a
fourth guarantees overflow, scrolling-to-discover, and a different tab set at
different widths — the exact fragile pattern the redesign was removing. A
separate sticky bottom action bar (mockup "Option 3B") was also rejected as a
carrier for supervisor actions alone.

Only comments were ever the problem, and only on mobile. Review actions
(Approve / Request Changes / Reject) and the version switcher are the things a
supervisor must find and act on without hunting — they do not belong behind a
comments icon.

## Decision

Two independent mobile presentations that together leave the tab bar a fixed,
width-invariant set (Project Details / Compare Versions / Progress Updates) and
change nothing on desktop:

1. **Pinned review action bar (mobile only).** The version switcher plus the
   policy-driven actions render in a `fixed bottom-0` bar, thumb-reachable on
   every tab. On desktop the same controls render in the "Review Project" card.
   Both frames render **one** shared partial, `_review_actions`, so there is a
   single source of truth for the controls and the role gates
   (`change_status? && current_version == latest_version` → split-button;
   `update?`/owner → Edit; `is_history` → Jump To Latest).

2. **Comments drawer (mobile only).** The comments pane is a single element
   that is the static sticky comments column on desktop and an off-canvas
   slide-in panel on mobile (`fixed top-0 right-0 bottom-0 ... translate-x-full`
   with `min-[1245px]:static min-[1245px]:translate-x-0`), opened by a chat
   icon + count badge in the sticky tab bar, with backdrop, Escape-to-close,
   and body scroll lock.

Supersedes the "Comments = 4th tab" plan-doc/mockup direction. The shared
`min-[1245px]` breakpoint matches existing app-wide usage (`topics/show`,
comments sticky heights).

## Consequences

- Tab bar tab set is identical at every width; the only width-driven chrome is
  the trigger icon (mobile) and the review card (desktop).
- Two frame partials (`_project_review_card`, `_review_action_bar`) render the
  same `_review_actions` controls; touching the gate logic in one place keeps
  both surfaces correct. The version `<select>` therefore exists twice in the
  DOM (one `display:none` frame) — safe because `select_tag nil` emits no `id`.
- The controls all render for every viewer regardless of role: a viewer with no
  actions still gets the version switcher, preserving today's always-on review
  card.
- Device QA is required on iOS Safari (fixed positioning + address bar), which
  is why the drawer uses `top/right/bottom: 0` instead of `h-full`.