# courses/show — Tab & Header Navigation Plan

Suggested repo path: `docs/courses_show_tabs_plan.md`

**Replaces the tab-bar sections of `courses_show_refactor_plan.md`** for
implementation purposes. Kept short on purpose — no alternatives-considered
essay — so it fits easily in context.

**Status:** mostly decided. Two open questions below block implementation.

---

## Confirmed: one IA at every breakpoint

Same tabs, same panels, regardless of screen width. No primary/overflow
"More" split is needed for the tab row — 4 tabs fit at any width. This makes
the earlier primary/overflow implementation work (§4.2 / "Ticket 1") for the
tab row unnecessary; don't build it if it hasn't started. (Breadcrumb
collapse can keep whatever breakpoint suits it on its own — it no longer
needs to be reconciled with a tab-overflow breakpoint, since tabs don't
overflow anymore.)

---

## Tab structure

### Coordinator / Lecturer

| Tab | Contains |
|---|---|
| Overview | Project details, Supervised Projects (see Q1), Reviewed Proposals, Pending Topics |
| Topics | Topic Directory |
| People | Lecturers, Students |
| Groups | Own tab (see note below) |

### Student

| Tab | Contains |
|---|---|
| Overview | Project details, My Project (own section, not a separate tab) |
| Topics | Topic Directory |
| People | Lecturers, Students |
| Groups | *Assumed same as coordinator — see Q2* |

---

## Header icons (coordinator/lecturer only, same at every breakpoint)

| Icon | Notes |
|---|---|
| Settings | Coordinator only. Header, not the tab row, not a dropdown. |
| Project template | Coordinator only, out of scope for this ticket — reserve the header slot now so it isn't a layout change later. |

---

## Naming

"Project Details" tab renamed to "Overview" (unchanged from earlier draft).

----