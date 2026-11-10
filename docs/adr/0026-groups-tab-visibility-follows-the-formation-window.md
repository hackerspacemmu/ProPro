# ADR 0026 — Groups tab visibility follows the formation window

Date: 2026-11-10
Status: Accepted (amends ADR 0024)

## Context

ADR 0024 kept the course Groups tab and the group formation page as two
separate surfaces, characterising the Groups tab as "read-mostly" — a
monitoring table — and the formation page as the write surface. Plan
decision D30 ("the Groups tab shows unconfirmed groups only when
formation is off") was still PROPOSED when 0024 was accepted.

Two facts forced D30 to be decided:

- While formation is **open**, students still forming see every group,
  confirmed or not, on a tab meant to answer "who is in which group,
  and what happened to their project". Not-confirmed groups have no
  project, so half-formed groups sit next to finished ones.
- Once the window is **not open**, leftover not-confirmed groups can no
  longer be acted on by students from the formation page, so the
  coordinator needs them on the Groups tab to confirm them (O11).

## Decision

**The Groups tab's base list is scoped by the formation window.** While
`Course#grouping_window_open?` is true, the tab lists confirmed groups
only; coordinators manage unconfirmed ones on the formation page. When
the window is not open — closed by date, grouping disabled, or before
it opens — the tab lists every group, including not-confirmed ones, with
a quiet "Not confirmed" pill, an amber row, a "Not confirmed" filter
option and the coordinator attention banner.

The tab also stops being purely read-only for coordinators: its Manage
dialog (the same lazy-loaded `groups#edit` frame the formation page
uses) gains a Status section with coordinator Confirm / Reopen
(`Groups::Coordinator::Confirmer` / `Reopener`), returning to the tab
with filters preserved. Writes stay behind the same resourceful routes
and policies (ADR 0025); only the entry point is new.

ADR 0024's core decision — two separate surfaces, neither renamed nor
merged — stands. Its "read-mostly" characterisation of the Groups tab is
amended: the tab is read-only for students and lecturers, and a write
surface for coordinators.

## Consequences

- A student in a not-confirmed group does not see their own group on
  the Groups tab while formation is open; the Overview's My Group card
  and the formation page keep their context.
- The tab's header count follows the window-scoped base list, not the
  filtered list; the footer keeps the filtered count.
- A stale `status_filter=draft` param is ignored while the window is
  open, so a leftover link never renders an empty list.
- The formation page stays the student write surface; nothing here moves
  student actions.
- The `draft` param value survives until the P7 vocabulary rename
  (`not_confirmed`).

## References

- ADR 0024 — two group surfaces stay separate (amended here)
- ADR 0025 — group formation routes are resourceful
- `app/controllers/groups_controller.rb` — window-scoped base list
- `docs/Grouping/MASTER_IMPLEMENTATION_PLAN.md` — D30, O11
