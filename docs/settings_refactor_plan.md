# Course Settings Redesign — Regression Audit Prompt & Safe Refactor Workflow

Context: `main` = source of truth for working behavior. `refactor/design` = the Tailwind/Google-Sans redesign branch. As of this writing, `app/views/courses/settings.html.erb` is **identical** on both branches (`git diff main refactor/design -- app/views/courses/settings.html.erb` returns nothing) — course/settings hasn't been touched yet, same stage `projects/edit` was at. The uploaded mockup (Google-Classroom-style, hardcoded into a `<div class="fixed inset-0 ...">` overlay) is the next view to wire in.

I cloned the repo and diffed the mockup against the actual `main` version of `app/views/courses/settings.html.erb`, `app/controllers/courses_controller.rb`, and the four partials it renders, instead of reasoning about this generically. Three things worth knowing before you hand this off:

- **The mockup nests `_course_code_form.html.erb` inside the outer settings `<form>` — main does not.** On `main`, `render "course_code_form", course: @course` happens at line 33, *before* the `form_with url: handle_settings_course_path(...)` block even opens. In the mockup, the equivalent render call sits inside "SECTION 2: General → Coursecode," which is inside the outer `form_with ... id: "course-settings-form"` block. The problem: `_course_code_form.html.erb` wraps its own `form_with url: update_coursecode_course_path(@course), ..., data: { controller: "coursecode-form-handler" }`. A `<form>` nested inside another `<form>` is invalid HTML5, and browsers silently drop the inner `<form>` open tag rather than rendering two independent forms. Practically: the element carrying `data-controller="coursecode-form-handler"` never gets created, so Stimulus never connects to it — the "Generate/Re-Generate Join Code" button and the "Allow joining via course code" toggle would stop working. It won't fail loudly. `handle_settings` doesn't write `coursecode`/`coursecode_enabled` at all (that's `update_coursecode`'s job, a separate route/action), so the outer form would just redirect with "Course successfully updated" while the code silently never changes.
- **That regression has zero existing test coverage to catch it.** There is no `test/system/courses/` directory at all, and no controller/request test for `#settings`/`#handle_settings`/`#grouping_preview`, and no policy test for `CoursePolicy`. The only two tests that touch coursecode (`test/integration/update_coursecode_test.rb`, `test/integration/enroll_via_coursecode_test.rb`) `post` directly to `update_coursecode_course_path` — they never render `settings.html.erb`, so they'd stay green even if the nested-form bug above shipped. This form has a thinner safety net than `projects/show` did; lean on Part 1's audit and manual browser testing more than on "CI will catch it."
- **`_grouping_settings.html.erb` was reproduced inline in "SECTION 4: Grouping (Inlined and Restyled)" instead of rendered as a partial.** I compared it field-by-field against the actual partial (toggle, mode cards, min/max, htmx preview endpoint, open/closed toggle, datetime window) and nothing appears dropped — this one's a faithful, careful port, not a functional regression. But `_grouping_settings.html.erb` is rendered from nowhere else in the codebase, so once this ships it becomes an orphaned partial with a live duplicate sitting in the parent view — two copies of the same logic to keep in sync. Worth a deliberate decision (redesign the partial in place vs. inline it and delete the original) before wiring, not an accident of how the mockup happened to be built.

Two smaller, pre-existing things surfaced along the way that aren't new regressions but are worth keeping in mind while you're in this code: `_course_code_form.html.erb` receives a `course:` local it never actually uses (the body reads `@course` directly throughout), and `_supervisor_capacity_settings.html.erb`/`_grouping_settings.html.erb` both read `@course`/`@capacity_result`/`@lecturer_enrolments` as instance variables rather than locals. None of that is caused by the redesign, but if you're touching these partials anyway, it's a natural place to apply the locals-only rule from your own workflow.

---

## Part 1 — Regression Audit Prompt (paste this to the audit agent)

Run this once the mockup has actually been wired into a working branch (e.g. a feature branch off `refactor/design`) — today, `refactor/design` and `main` are identical for this view, so there's nothing to diff yet. Use it on its own agent session/branch checkout, separate from whoever is doing the implementation work. Its only output should be a report — no fixes.

```
You are auditing a Rails app (hackerspacemmu/ProPro) for regressions introduced by a
UI/partial redesign of the course settings page. You are NOT implementing anything and
you must not modify any files. Your only deliverable is a written audit report.

BRANCHES
- Reference (known-good behavior): main
- Candidate (redesign in progress): <the branch course/settings was wired into>

Check out both into separate worktrees (or diff via `git diff main...<candidate>`) so you
can read full file contents on each side, not just diff hunks — partial renames and a
render call moving in/out of a form block are both easy to miss in a line-diff.

SCOPE (in this order — stop and report after each pass rather than batching):
1. app/controllers/courses_controller.rb — ONLY the `settings`, `handle_settings`,
   `update_coursecode`, and `grouping_preview` actions, plus the `set_course` and
   `set_lecturer_enrolments` before_actions and the `load_capacity_result` private
   method. This controller is large and has unrelated work in flight elsewhere
   (course creation, student/lecturer invite flows) — do not treat diffs in those
   sections as in-scope findings.
2. app/policies/course_policy.rb — specifically `update?`, since that's what gates
   both `settings` and `handle_settings`.
3. app/views/courses/settings.html.erb, and every partial referenced from it on
   EITHER branch (grep both branches for every `render "..."` / `render partial:`
   call from this view — a section that was a partial on one side and inlined
   markup on the other still needs a side-by-side comparison).
4. config/routes.rb — the `settings` / `handle_settings` / `update_coursecode` /
   `grouping_preview` routes nested under `resources :courses`.
5. app/javascript/controllers/coursecode_form_handler_controller.js,
   grouping_settings_controller.js, supervisor_capacity_controller.js,
   textarea_resize_controller.js — referenced via data-controller in the views above.
6. test/integration/update_coursecode_test.rb, test/integration/enroll_via_coursecode_test.rb,
   test/models/course_test.rb. Note explicitly in your report that there is currently
   no test/system/courses/**, no request/controller test for #settings/#handle_settings/
   #grouping_preview, and no CoursePolicy test — do not assume coverage exists anywhere
   you haven't personally located a test file for.

FOR EACH FILE THAT DIFFERS BETWEEN BRANCHES, do the following:

A. Controller/route parity
   - Diff the exact param whitelist in `handle_settings` (it's a manual hash of
     `params[:course][:x]` reads, not `.permit`), every before_action, and every
     redirect/flash/render call. Flag ANY difference, even ones that look purely
     cosmetic.

B. Policy/authorization parity
   - Confirm `settings` and `handle_settings` both still call
     `authorize @course, :update?` and that `update?` still resolves the same way
     (`coordinator`). For every difference, state explicitly: what capability
     changed, who gains or loses it, and whether it looks intentional or accidental.

C. Partial contract parity ("locals in vs locals out"), with one extra check specific
   to this view:
   - Build the usual table: old partial | locals/ivars it relied on | where each
     now lives in the new markup.
   - ADDITIONALLY: for every partial that itself contains a `<form>` tag (currently:
     `_course_code_form.html.erb`), confirm it is NOT rendered from anywhere inside
     another open `<form>` in the new markup. Nested forms are invalid HTML5;
     browsers silently drop the inner `<form>` open tag rather than creating two
     forms, which detaches any Stimulus controller declared via `data-controller`
     on that tag and can cause fields meant for one endpoint to submit to another
     (or nowhere) without an error. Search the rendered output (not just the ERB
     source) for this if there's any doubt.

D. Feature/interaction inventory
   - Walk the OLD view (`main`) top to bottom and list every distinct user-facing
     behavior: every field, every radio/toggle pair, every conditional card state
     (e.g. the locked "Final student list" card, the auto-close window toggle),
     every computed label. For each, find its equivalent in the NEW view and mark
     it PRESERVED / RELOCATED / CHANGED / REMOVED. Pay particular attention to the
     grouping section's conditional states (`@course.student_list_finalised?`,
     `@course.grouping_enabled?`) since those drive which of two mutually exclusive
     cards renders.

E. Dead code / orphan check
   - Confirm whether `_grouping_settings.html.erb` is still rendered from
     anywhere. If the new settings view reproduces its markup inline instead, flag
     this explicitly as NEEDS DECISION (keep as a restyled partial vs. delete the
     original) rather than letting an unrendered partial sit in the codebase.
   - Any local declared in a render call but never referenced in the partial body
     (e.g. check whether `_course_code_form.html.erb`'s `course:` local is ever
     actually used, versus the body reading `@course` directly).

F. Test coverage parity
   - Confirm `test/integration/update_coursecode_test.rb` and
     `enroll_via_coursecode_test.rb` still pass, but explicitly note in your report
     that passing tells you nothing about whether the coursecode form is correctly
     wired into the settings page's DOM — both tests `post` directly to the
     controller action and never render `settings.html.erb`.
   - Flag the complete absence of system/request/policy test coverage for this
     page as a NEEDS DECISION item, not something to silently accept.

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

## Part 2 — Workflow for finishing course/settings

**Step 1 — Freeze a feature inventory before touching anything, using `main`.**
For `CoursesController#settings`/`#handle_settings`, write down:
- The exact whitelist `handle_settings` writes: `course_name`, `course_description`,
  `supervisor_projects_limit`, `require_coordinator_approval`,
  `auto_approve_copied_topics_without_changes`, `starting_week`,
  `use_progress_updates`, `number_of_updates`, `lecturer_access`, `student_access`,
  `file_link`, `toggle_topics`, `supervisor_auto_calculate_enabled` — plus the
  separate grouping branch (`grouping_enabled`, `student_list_finalised`,
  `group_min`, `group_max`, `grouping_open`, `grouping_opens_at`,
  `grouping_closes_at`, each with special-case logic via `disable_grouping!` /
  `revert_to_default_mode!`), and the `supervisor_capacity_offsets`/
  `supervisor_capacity_excluded` params handled separately via
  `SupervisorCapacityUpdater`.
- **`coursecode` and `coursecode_enabled` are explicitly NOT part of this list** —
  they only ever go through `update_coursecode`. This is your anchor for finding #1
  above: any wiring that submits those fields through the settings form instead of
  the coursecode form's own endpoint is wrong by construction.
- Every `authorize @course, :update?` check gating these actions.
- Every partial currently involved (`_course_code_form`, `_supervisor_capacity_settings`,
  `_grouping_settings`, `_copy_course_overlay`, `_flash`) and, for each, what it
  actually reads — several of these read `@course`/`@capacity_result`/
  `@lecturer_enrolments` as instance variables rather than locals, which the
  controller sets via `set_lecturer_enrolments` and `load_capacity_result` — so
  wiring the new sections needs those before_actions to keep running, not just the
  render calls to keep passing the right locals.

This is your acceptance checklist for the rewired version, not a spec to redesign around.

**Step 2 — Map the mockup to that inventory, gap by gap.**
- Coursecode subsection: mark this "needs re-homing," not "needs wiring." The fix
  isn't extra data binding — it's moving the render call back outside the settings
  `<form>` (e.g. directly above `<main>`, alongside the sticky top nav), since CSS
  can make two sibling forms sit visually inside the same card but HTML nesting
  can't fake two independent `<form>` elements.
- Grouping section: decide partial-vs-inline (finding #2) before wiring — that
  decision changes whether Step 4's partial cleanup even applies here.
- Supervisor Capacity: the mockup already renders `_supervisor_capacity_settings`
  correctly as a partial in roughly the same position as `main` — low risk, just
  confirm `@capacity_result`/`@lecturer_enrolments` still load the same way in the
  new layout.
- Everything else (Class Details fields, Permissions & Rules toggles,
  `student_access` radios): field names already line up 1:1 with `handle_settings`'s
  whitelist — low risk, mostly a "did the visual rewrite typo a field name" check.

**Step 3 — Wire one section at a time, smallest first.**
Suggested order for this form specifically:
1. Class Details (`course_name`, `course_description`, `file_link`, `starting_week`) —
   plain fields, no partials, no JS.
2. Permissions & Rules toggles + `student_access` radios — same: plain
   radios/enum, nothing dynamic to break.
3. Supervisor Capacity — the partial render is already correct; this step is just
   re-placing it inside the new layout and confirming the two ivars still load.
4. Grouping section — bigger blast radius: htmx preview endpoint, a Stimulus
   controller, two mutually-exclusive conditional card states, and the
   partial-vs-inline decision from Step 2.
5. Coursecode subsection, last and on its own — it needs structural surgery
   (moving outside the form), not re-skinning. After wiring it, manually click
   "Generate Join Code" and toggle "Allow joining via course code" in an actual
   browser, since nothing in the automated suite exercises that path through this
   page.

After each section, run the existing tests plus a manual pass against that
section's line items from Step 1 before moving to the next one.

**Step 4 — Clean up partials as you wire, using two rules, not vibes.**
- **A partial exists only if it's reused, or is a genuinely reusable component.**
  `_grouping_settings.html.erb` is currently used from exactly one place — decide
  deliberately whether it stays a partial (restyled) or gets inlined and deleted,
  rather than ending up with both.
- **Every partial takes locals, never instance variables**, declared explicitly
  via `<%# locals: (...) %>`. `_course_code_form.html.erb` already receives a
  `course:` local it doesn't use (the body reads `@course` instead) — if you're
  touching this partial anyway, make it actually use the local you're passing it.
  Same applies to `_supervisor_capacity_settings.html.erb` (`@capacity_result`,
  `@lecturer_enrolments`) if it gets touched during the grouping/capacity work.

**Step 5 — Once course/settings is wired, re-run Part 1's audit scoped to it.**
Additionally, since this page currently has zero system/request/policy test
coverage, add at least one system test that clicks through a full settings save,
and one that specifically exercises the coursecode generate/toggle path — that's
the one part of this page with no existing safety net at all, so it shouldn't
ship without new coverage rather than relying on the audit alone.