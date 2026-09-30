# ADR 0018 — A browse table's empty state is decided in the controller, from its base list

Date: 2026-09-26
Status: Accepted

## Context

The three filterable lists on `courses/show` — Groups, Students (People tab),
topics directory — are htmx targets (ADR 015) whose containers are swapped
wholesale, so each one is re-rendered by the `courses#show` htmx branch from
the same locals the page path passes. All three also have a filter: a search
box plus, for Groups and Students, status and supervisor selects.

Each partial carried its own empty-state markup, and each one branched on the
filters *by reading `params` from the view*. `_groups_table.html.erb` handled
exactly one of its three filters, so a search that matched nothing, or a
supervisor filter that matched nothing, fell through to its default branch and
told the coordinator **"No groups have been created yet."** — a false claim
about their course. `_students_table.html.erb` never branched at all and always
said "No students have been enrolled yet." The topics directory's single
sentence, "No topics are currently available.", was at least neutral, but
equally indistinguishable from a filter miss.

Two things were already true and made the split possible:

- Each action holds the **unfiltered, policy-scoped** list and the filtered one
  at the same instant — `@group_list` (`courses_controller.rb:47`) beside
  `@filtered_group_list`, `@student_list` beside `@filtered_student_list`,
  `@topic_list` beside `@filtered_topic_list`. Both are already loaded, so
  comparing them costs no query.
- ADR 015 established the locals-not-ivars seam in spirit and the partials'
  own header comments state it outright ("rendered from BOTH the page path and
  the courses#show htmx branch, so it only ever uses locals"). Reading `params`
  in a partial that re-renders on every keystroke contradicted the convention
  the file declared two lines above the code that broke it.

The interesting part is not the mechanism — it is that a filter miss and a
genuinely-empty list are different *claims about the world*, and the old code
had no way to tell them apart.

## Decision

1. `CoursesController#list_state(base_list, filtered_list)` returns one of three
   symbols, and the partials receive it as a `state:` local:

   - `:matched` — the filter returned rows (the state is never rendered)
   - `:no_matches` — the base has rows, the filter returned none
   - `:empty` — the base itself is empty

2. The base is always the **unfiltered, policy-scoped** list, never the
   unscoped one. A student on a course with no approved topics has an empty
   base — they filtered nothing out, so "no matches" would be its own lie.

3. The base and the filtered list are both compared **after** the 25-row
   truncation, so the state and the rows the partial receives can never
   disagree.

4. The controller hands over a **symbol**; the view owns the copy. `state` says
   which situation this is, and the partial maps it to words. User-facing
   strings stay in the view, matching how `shared/_empty_state` already takes
   `heading:`/`description:` from its callers.

5. One generic no-matches message serves every filter — "No *nouns* match your
   current filters." plus a muted "Try adjusting your search or filters." With
   three filters a per-filter message set is seven branches and seven tests,
   each one a chance to be wrong the moment a filter is added. Specificity is
   available in the control the user is looking at, not in the message.

6. `filters_active:` is a second local, reported rather than re-derived. It
   cannot be folded into `state`: under a search that *does* match, the state
   is `:matched` but rows must still auto-expand, and the topics directory
   must still drop its empty supervisor groups. It is computed from
   `PARTICIPANT_FILTER_KEYS` / `TOPIC_FILTER_KEYS` (`"all"` being the selects'
   neutral choice, so not active).

7. The two table-shaped empties share `shared/_table_empty_state`
   (`colspan:`, `heading:`, `hint:`), so Groups and Students cannot drift a
   third time. The topics directory keeps its own `<p>` — a `<tr>` cannot be a
   `<p>` — but takes the same two-state logic. `shared/_empty_state` is
   untouched: its root is a `<div>` with a 180px illustration, unusable inside a
   `<tbody>`, and it has five other call sites.

## Consequences

- A filter miss can no longer assert that nothing exists. The regression guard
  is the *negative* assertion in every no-matches test
  (`assert_no_match 'No groups have been created yet.'`), which is the check
  that would have caught the original defect.
- The three swapped partials no longer read `params` at all. The filter
  *controls* (`_groups_tab`, `_students_section`, `_topics_section`) still do,
  to echo their own current `value`/`selected` — a control reflecting state is
  not a decision, and that is where the convention stops.
- The controller grows three ivars and two small private methods, and threads
  two locals through the ivar→locals seam. Every future filterable list is
  expected to pay that same small toll.
- Adding a filter no longer means writing copy. It means adding a key to
  `PARTICIPANT_FILTER_KEYS`/`TOPIC_FILTER_KEYS` so `filters_active?` sees it.
- "Show all N" and the "Showing X of Y" footer are unchanged. `@total_group_count`
  is the count of *matches* taken before truncation, so "Showing 25 of 40" under
  an active search is correct, not a bug. `@total_count` (assigned twice) and
  `@displayed_count` were read by no view and are deleted.

## References

- ADR 015 — the htmx decision this extends; it fixes the mechanism but is silent
  on who decides what the swapped partial shows.
- ADR 013 — the topics directory's browse-first shape, which is why a student's
  policy-scoped list is the meaningful base there.
