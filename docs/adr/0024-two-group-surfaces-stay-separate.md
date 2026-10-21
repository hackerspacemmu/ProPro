# ADR 0024 — The course Groups tab and the grouping workspace stay separate surfaces

Date: 2026-10-21
Status: Accepted

## Context

Two surfaces render the same `ProjectGroup` records, and both are called
"Groups":

- **The course Groups tab** — `/courses/:course_id/groups` →
  `groups#index` (ADR 0019). A monitoring table: Group / Members
  (expandable) / Project Title / Status / Supervisor, with search,
  status and lecturer filters, re-rendered over htmx. Policy-scoped, and
  built for a coordinator answering "who is in which group, and what
  happened to their project".
- **The grouping workspace** — `/courses/:course_id/project_groups` →
  `project_groups#index`. Where students actually form groups: my-group
  panel, browse groups (All / Draft / Confirmed), ungrouped students,
  create / join / invite / confirm / dissolve.

They overlap: both list groups, both have a search box, and both show
members. Before the merge only the second existed, in its pre-redesign
form. The merge brought `main`'s Groups tab alongside it, and ADR 0022's
route audit already flagged the "`groups` / `project_groups` naming
overlap" as known debt.

Three ways out were on the table: rename the workspace so the two are
distinguishable, fold one into the other, or keep both.

## Decision

**Both surfaces stay, with their current names.** The Groups tab
remains the coordinator's monitoring table; the grouping workspace
remains the participation surface students and group leaders work in.
The naming overlap is accepted, not fixed, in this pass.

- The **Groups tab** is read-mostly: it answers questions about groups
  that already exist. It links out to projects, not to the workspace.
- The **grouping workspace** is write-mostly: it is where a group is
  created, joined, confirmed or dissolved. It links out to nothing —
  it *is* the destination for grouping actions.
- Neither is renamed and neither is merged into the other. The two
  routes stay separate, as ADR 0019 and ADR 0022 require routes to be.

## Consequences

- "Groups" is ambiguous in this codebase: it names a course tab, a
  route segment, and a model. Anyone reading the code has to know which
  surface is meant from the route or the controller, not the word.
- The two surfaces can drift — the workspace still carries the
  pre-redesign markup while the Groups tab follows the current design
  system — and a group can look different in each.
- Two search boxes over the same records means two ways to find the
  same group, with different results.
- A student who is only asked to "join a group" is sent to one surface;
  a coordinator asked "who is in that group" is sent to another. The
  hand-off between them is a URL, not a link on the page.

## Known debt (out of scope, listed only)

- Renaming one of the two surfaces, or merging them, is still open.
  The Groups tab's members column already expands to show the same
  member list the workspace shows in its group cards, so the data
  overlap is real, not just the naming.
- ADR 0022's route audit lists the `groups` / `project_groups` overlap
  among ~35 non-canonical routes left alone; this ADR makes the naming
  half of that deliberate.

## References

- ADR 0019 — course tabs are routes
- ADR 0022 — project and topic tabs are routes; participant profiles
  are routes (its "known debt" list names this overlap)
- ADR 0023 — grouping settings live only in Course Settings
- `app/controllers/groups_controller.rb` and
  `app/views/courses/_groups_tab.html.erb` — the Groups tab
- `app/controllers/project_groups_controller.rb` and
  `app/views/project_groups/index.html.erb` — the grouping workspace
