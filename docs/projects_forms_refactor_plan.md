# ProPro Redesign — Regression Audit Prompt & Safe Refactor Workflow

Context: `main` = source of truth for working behavior. `refactor/design` = new Tailwind/Google-Sans redesign, built mockup-first then wired up. `projects/show` is already redesigned; `projects/edit` and `projects/new` are next (the uploaded ERB is the target mockup for edit, not yet wired in).

I pulled both branches to ground this doc in real diffs instead of writing something generic. Two concrete things worth knowing before you hand this off:

- **`app/policies/project_policy.rb` already differs between branches** — `refactor/design` adds `return true if coordinator` inside `update?` (or similar) that isn't on `main`. That's a genuine permission change bundled into a "visual" redesign branch, exactly the kind of thing you don't want to discover in prod.
- **`test/system/projects/project_versioning_test.rb` was NOT updated** for the new `show` DOM/copy (tabs went from "Details / Progress Updates / Comments (n)" to "Project Details / Compare Versions / Progress Updates", and comments moved from a tab into a permanent sidebar). The old mobile-only rendering path (`data-controller="mobile-tabs"`, duplicate `_project_fields` render for small screens) was deleted outright — `_project_header.html.erb` (373 lines) and `_project_fields.html.erb` (70 lines) no longer exist in `refactor/design`. Nothing references them anymore (no dead `render` calls), so that part was cleaned up correctly — but it means mobile-specific behavior was either intentionally dropped or needs to be re-solved elsewhere, and nobody has confirmed which.

Those two are seed examples, not the whole list — use Part 1 to find the rest systematically.

---

## Part 1 — Regression Audit Prompt (paste this to the audit agent)

Use this on its own agent session/branch checkout, separate from whoever is doing the implementation work. Its only output should be a report — no fixes.

```
You are auditing a Rails app (hackerspacemmu/ProPro) for regressions introduced by a
UI/partial redesign. You are NOT implementing anything and you must not modify any
files. Your only deliverable is a written audit report.

BRANCHES
- Reference (known-good behavior): main
- Candidate (redesign in progress): refactor/design

Check out both into separate worktrees (or diff via `git diff main...refactor/design`)
so you can read full file contents on each side, not just the diff hunks — partial
renames make line-diffs misleading.

SCOPE (in this order — stop and report after each pass rather than batching):
1. app/controllers/projects_controller.rb, project_groups_controller.rb,
   project_templates_controller.rb
2. app/policies/project_policy.rb, project_group_policy.rb
3. app/views/projects/**, and any partial referenced from it (grep the redesign
   branch for every `render "..."` / `render partial:` call, then locate each)
4. config/routes.rb (projects-related resources/nested routes)
5. app/javascript/controllers/** referenced via data-controller attributes in the
   above views (e.g. tabs, mobile-tabs, and anything else)
6. test/system/projects/**, test/models tied to Project/ProjectInstance, and any
   controller/request specs for the above controllers

FOR EACH FILE THAT DIFFERS BETWEEN BRANCHES, do the following:

A. Controller/route parity
   - Diff params permitted, before_actions, redirects/flash, instance variables
     assigned. Flag ANY difference, even ones that look purely cosmetic — a
     dropped before_action or a renamed instance variable is invisible in a
     visual review but breaks the view silently.

B. Policy/authorization parity
   - Diff every Pundit (or equivalent) policy method line by line. Do not assume
     a change is "obviously fine" because it looks small — a single added
     `return true if X` line is a real permission grant. For every such
     difference, state explicitly: what capability changed, who gains or loses
     it, and whether it appears intentional (tied to a described feature) or
     accidental (leftover from an experiment, or a merge artifact).
   - Cross-check: does every `policy(@project).something?` call site in the old
     view have an equivalent authorization check somewhere in the new view? A
     redesign that removes a UI element without removing the underlying
     permission check is usually fine; one that removes the permission check
     itself (or moves an action outside the guarded block) is not.

C. Partial contract parity ("locals in vs locals out")
   - For every partial that was renamed, split, or merged (e.g. old
     `_project_header.html.erb` + `_project_fields.html.erb` →
     new `_context_header.html.erb` + `_project_overview.html.erb` +
     `_compare_versions_tab.html.erb`, etc. — confirm actual names on your
     checkout, this repo's names will drift), build a table:

       old partial | locals it received | where each local's DATA now lives
       new partial(s) | locals declared (check for `<%# locals: (...) %>`)

     Flag any local that was used in the old partial but has no home in the
     new one — that's either dropped functionality or a live bug waiting to
     happen (NameError on a missing local, or a silently blank section).

D. Feature/interaction inventory
   - Walk the OLD view top to bottom and list every distinct user-facing
     behavior: every `if`/`unless` branch, every link/button/form, every
     conditional class, every empty-state, every count or computed label
     (e.g. "Comments (n)", "X/Y approved · Z pending"). For each one, find its
     equivalent in the NEW view and mark it:
       - PRESERVED (same behavior, possibly restyled)
       - RELOCATED (moved to a different tab/panel/modal — note where)
       - CHANGED (behavior itself is different — describe precisely)
       - REMOVED (no equivalent found — flag as a question, not an assumption)
   - Pay special attention to responsive/mobile-only code paths in the old
     view (e.g. `data-controller="mobile-tabs"`, `hidden md:block` pairs).
     If the new markup has no mobile equivalent, say so explicitly rather than
     letting it slide as a styling detail.

E. Dead code / orphan check
   - Any partial, stimulus controller, helper, or route left on either branch
     that is no longer rendered/called by anything.
   - Any locals declared in a `<%# locals: (...) %>` comment that are never
     used in the partial body, or used-but-undeclared.

F. Test coverage parity
   - Flag every system/request test that references DOM text, CSS selectors,
     or `data-*` attributes that no longer exist on the redesign branch —
     these will pass on main and silently rot or hard-fail on the redesign
     branch. List them by file and line.
   - Flag features found in step D that have NO test coverage on either
     branch — not a blocker, but worth surfacing.

OUTPUT FORMAT
Produce a single markdown report with sections matching A–F above. Within each
section, group findings by severity:
   - BREAKING — will error or silently no-op in production
   - BEHAVIOR CHANGE — works, but does something different than main (may be
     intentional; needs a human decision either way)
   - COSMETIC — visual only, no functional impact
   - NEEDS DECISION — ambiguous; you found a difference but can't tell intent
For every finding, cite exact file paths and, where possible, line numbers on
both branches. Do not editorialize about which design is "better" — your job
is to make every functional delta visible, not to judge the redesign.
```

---

## Part 2 — Workflow for finishing `projects/edit` and `projects/new`

You already know the risk: the uploaded mockup is a hardcoded snapshot (static "Test Lecturer 1", static "2/3 approved · 1 pending", a placeholder textarea) with no wiring to real data yet, and the old `_project_edit.html.erb` / `_project_details.html.erb` / `_proposal_method.html.erb` almost certainly loop over dynamic template fields, real supervisor-approval state, and policy-gated edit rules that the mockup doesn't represent at all. Mockup-first is fine as a design tool — the risk is entirely in the wiring step. So the goal isn't "don't do mockup-first," it's "don't let the mockup silently define the feature set."

**Step 1 — Freeze a feature inventory before touching `edit`/`new`, using `main`.**
Do this by hand or with an agent, but do it *before* wiring, not after — otherwise you'll rediscover requirements one bug report at a time. For `projects_controller#edit`/`#update` and `#new`/`#create`, list:
- every param permitted and every validation/callback that fires on save
- every `policy(@project).x?` check gating a field, button, or section
- every piece of *dynamic* data the current view renders (template fields loop, approval counts, topic-catalog data, methodology options) vs what's currently hardcoded in your mockup
- every partial currently involved (`_project_edit`, `_project_details`, `_proposal_method`, `_project_new`) and what locals each one needs today

This list is your acceptance checklist for the rewired version — not a spec to redesign around, just a "don't forget this exists" list.

**Step 2 — Map the mockup to that inventory, gap by gap.**
Go section by section through the mockup and mark each piece as: *already dynamic in the mockup's structure and just needs real data*, *currently hardcoded and needs to become a loop/partial*, or *missing entirely from the mockup* (you'll need to design a spot for it, e.g. where does the free-edit-fields policy state show up?). Don't wire anything yet — this pass is just so wiring doesn't turn into archaeology mid-implementation.

**Step 3 — Wire one section at a time, smallest first.**
Suggested order for the edit form specifically, since it's lower-risk to higher-risk:
1. Proposal Method selector cards (mostly static toggle state + one relationship — supervisor)
2. Simple fields (title, dropdown) — these map straight to template fields
3. Methodology radio / dynamic field types — this is where the field-type loop lives
4. Rich text / description — likely the most custom (toolbar, markdown) and most likely to hide edge cases (empty content, existing saved markdown rendering)

After each section, run existing tests plus a manual pass against that section's line items from Step 1's inventory before moving to the next section. Small blast radius per commit makes it obvious which change caused which regression.

**Step 4 — Clean up partials as you wire, using two rules, not vibes.**
This is straight from the reusable-components guidance you shared, and it's worth making a hard rule for this refactor rather than a suggestion:
- **A partial exists only if it's reused, or is a genuinely reusable component** (a field renderer, a card, an item row). Don't extract a partial just to shorten a long view file — that's what the old `_project_header.html.erb` (373 lines) and `_project_details.html.erb` (376 lines) look like they became: grab-bags that grew because "extract to partial" was used as a stand-in for "this method is getting long," rather than because the markup was actually reused elsewhere. If a chunk of the new edit/create view isn't rendered from more than one place, it can usually just stay inline in `edit.html.erb`/`new.html.erb`.
- **Every partial takes locals, never instance variables**, and should declare them explicitly with Rails' strict-locals comment: `<%# locals: (project:, fields:, ...) %>`. The redesign branch already does this correctly in `_context_header.html.erb` — hold every new/changed partial in `edit`/`new` to that same standard. This alone prevents a whole class of "partial silently reads a stale `@instance_variable`" bugs, and it makes Part 1's contract-parity check (section C above) mechanical instead of guesswork, since the locals list is right there in the file.

**Step 5 — Once edit/create are wired, re-run Part 1's audit prompt scoped to them.**
Same process that should be run against `show` now applies to `edit`/`new`/`create` — controller/policy parity, partial contract parity, feature inventory, dead code, test coverage. Treat it as the exit criteria for calling the redesign "done," not an afterthought.