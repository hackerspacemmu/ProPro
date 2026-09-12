# `refactor/design` Audit — vs `main`

Scope: `app/views`, `app/javascript/controllers`, `app/helpers`, `app/presenters`, `app/assets` on `refactor/design` (merge-base `88506851`), diffed against `main`, cross-checked against *Sustainable Web Development with Ruby on Rails* (Copeland) ch. 7–8 and 10–11. Not an implementation pass — findings and recommendations only.

This branch touches 241 files (+29,053/‑11,420). It's a huge, genuinely disciplined redesign — good ADRs, a real glossary (`CONTEXT.md`), a presenter with its own test, an internal Tailwind audit doc, no jQuery, no framework sprawl in JS. The findings below are the gaps in an otherwise strong pass, not a verdict on the branch.

---

## 1. Unused partials (the "backup left behind" check)

Cross-referenced every `_*.html.erb` against every `render` call in `app/` (including controller-level `render partial:` for AJAX/Turbo responses). **9 partials are dead** — zero render call anywhere:

| Partial | Verdict |
|---|---|
| `app/views/courses/_course_card.html.erb` | Orphaned. No caller anywhere in the repo. |
| `app/views/lecturers/_lecturer_card.html.erb` | Orphaned. **Also** sets `content_for :no_footer` — see §4. |
| `app/views/project_templates/_new_field.html.erb` | Orphaned. |
| `app/views/projects/_comment.html.erb` | Orphaned — superseded. `_project_comments.html.erb` and `_topic_comments.html.erb` now inline the comment-row markup directly instead of calling `render "comment"`. Confirm that was deliberate (dropping the abstraction) and not an accidental fork; if deliberate, delete this file so the next person doesn't "fix" `_project_comments` by pointing it back at a partial two different views no longer agree on. |
| `app/views/topics/_topbar.html.erb` | Orphaned, and worth deleting first. CRLF line endings, pre-Tailwind classes (`topbar-icon`, `topbar-info`, `topbar-actions`) that no longer exist in any stylesheet — this is a fossil from before the CSS migration in §5, not just before this branch. |
| `app/views/project_groups/_group_list.html.erb` | Orphaned. |
| `app/views/project_groups/_grouping_closed.html.erb` | Orphaned. |
| `app/views/project_groups/_my_group.html.erb` | Orphaned — superseded by `_my_group_panel.html.erb`, which duplicates its purpose and *is* live. |
| `app/views/project_groups/_no_group.html.erb` | Orphaned. |
| `app/views/project_groups/_ungrouped_students.html.erb` | Orphaned. |

**Chain note:** `_group_card.html.erb` is only rendered by `_group_list.html.erb`, and `_group_list.html.erb` is itself never rendered — so `_group_card` is dead too even though a naive one-hop check would call it "used." `project_groups/index.html.erb` renders its whole browse/filter grid inline now and only calls out to `_my_group_panel`. That leaves **6 of the 8 partials in `app/views/project_groups/` dead**, with only `index.html.erb` and `_my_group_panel.html.erb` live.

This lines up with your backend note: grouping isn't merged to `main` yet, and the DB has zero confirmed groups in production. My read is `project_groups/` is exactly the kind of directory that accumulates this — a UI was built ahead of the backend, the backend direction changed (confirmed-vs-all-groups), and the index page got rewritten inline without anyone deleting the partials it used to call. Worth sweeping this directory in the same pass as the group-table decision, since whoever resolves that will already be in this code.

Also flag `app/javascript/controllers/hello_controller.js` — zero `data-controller="hello"` anywhere, it's the Stimulus scaffold default (present on `main` too, so not this branch's doing, but it's dead weight sitting next to real controllers and worth a one-line deletion whenever someone's next in that folder).

**Not flagged, confirmed live:** `_project_card.html.erb` (0 hits in this branch's diff, but rendered from `courses/profile.html.erb` and `lecturers/show.html.erb` — both Follow-up pages, correctly untouched).

---

## 2. Partials vs. Copeland 7.3 ("Use Locals to Pass Parameters")

34 of 78 partials document their interface with a `<%# locals: (...) %>` header — good, that's the right convention and more than half the codebase doesn't have it, so it's clearly an intentional practice, not an accident.

The gap: **25 partials reach into controller instance variables instead of receiving locals**, and a meaningful chunk of those are partials this branch wrote or rewrote, not legacy carryover:

- `shared/_header.html.erb`, `shared/_sidebar.html.erb` — both use `@course`
- `projects/_project_overview.html.erb`, `_project_details.html.erb`, `_proposal_list_item.html.erb`, `_project_comments.html.erb`
- `topics/_topic_comments.html.erb`, `_copy_topic_details.html.erb`, `_review_actions.html.erb`, `_copy_topic_overlay.html.erb`
- `courses/_project_details_card.html.erb`, `_topic_card.html.erb`, `_overview_tab.html.erb`, `_people_tab.html.erb`, `_topic_directory_tab.html.erb`, `_groups_tab.html.erb`

The sharper version of this finding: **four of those — `_project_overview`, `_project_comments`, `_topic_comments`, `_review_actions` — already have a `locals:` strict-locals header, and still reach for `@course`/`@window`/`@is_coordinator` in the body.** That's not just missing the convention, it's declaring the convention and then quietly opting back out of it. A partial with a `locals:` header reads as "here is the complete interface" — a reviewer or a future editor has no reason to grep the body for hidden `@` dependencies once that header is there. Right now they'd need to.

`shared/_header.html.erb` and `_sidebar.html.erb` are the two highest-leverage ones to fix, precisely because they're rendered on ~30 views (per the header's own comment) — every one of those call sites has an implicit, undeclared dependency on `@course` being set (or nil-safe, which it correctly is here — see §6).

## 3. Helpers vs. Copeland 8.1 ("Don't Conflate Helpers with Your Domain")

Mixed. `ApplicationHelper` and `BreadcrumbHelper` are good examples of the chapter's positive case — `status_badge_classes`, `format_timestamp`, `render_custom_breadcrumbs` are pure markup/formatting, exactly what 8.2 asks for. Two others aren't:

- **`ProjectsHelper#name(user_id)`** runs `User.find_by(id: user_id)` — a database query inside a view helper. This is the chapter's core warning case verbatim, and it's an N+1 risk if it's called per-row anywhere.
- **`CoursesHelper#group_project_for` / `#student_project_for`** reach into `@projects_by_owner` (a controller ivar) and do a hash lookup — domain-shaped logic, and it inherits the same undeclared-dependency problem as §2 since it's not an argument.
- **`ProjectsHelper#show_progress_tab?` and `TopicsHelper#show_progress_tab?`** are byte-for-byte identical (`@course.use_progress_updates && @current_instance.status == 'approved'`), duplicated across two helper modules instead of living in one place — a small DRY miss, but an easy one to fix since it's a single method.

## 4. Presenters vs. Copeland 8.3

`OverviewPresenter` is a good instance of the pattern the chapter actually endorses: plain Ruby object, explicit keyword-arg constructor, intention-revealing query methods (`show_pending_topics?`, `any_sections?`), no view-rendering logic bleeding in, and it has its own unit test (`test/presenters/overview_presenter_test.rb`). This is worth calling out as a positive pattern to repeat elsewhere, not just a pass/fail.

The catch: `courses/_overview_tab.html.erb` receives it as `@presenter`, not as a local. The whole value of building an explicit object here is that a partial's dependency on it becomes visible and testable at the call site — stuffing it into an ivar and reaching for it inside the partial throws that away and makes `_overview_tab` no different from any other ivar-coupled partial in §2.

## 5. `content_for` called from inside a partial

`app/views/lecturers/_lecturer_card.html.erb` calls `content_for :no_footer, true` in its own body. A partial reaching up to flip page-level layout flags breaks the "partial is an isolated, reusable component" contract from 7.3.1/7.3.2 — render this partial twice, or from a page that already made its own footer decision, and the outcome depends on render order. (It's also one of the 9 dead partials from §1, so it's not live today — but it's the kind of pattern that should get caught in review before it ships again, not just deleted this once.)

Smaller consistency note: `sessions/new.html.erb` and `passwords/{new,edit}.html.erb` use `<% provide :no_footer, true %>` while every other page uses `<% content_for :no_footer, true %>`. They're aliases, so nothing's broken, but two spellings of the same call in one codebase is exactly the kind of needless inconsistency the book's "Just Use ERB" chapter argues against — pick one.

---

## 6. Correctness vs. `main` — shared header/sidebar/footer

`application.html.erb`'s `unless content_for?(:no_sidebar/:no_header/:no_footer)` gating is unchanged from `main` — this branch didn't introduce that mechanism, it's inherited. What changed is what gets rendered inside it: `shared/_header.html.erb` and `_sidebar.html.erb` are new, and both touch `@course`.

Checked this specifically because `_header`/`_sidebar` now render globally on pages that may have no `@course` — static pages, `user/profile`, the homescreen. **Both partials guard correctly**: the header's coordinator-icons block is behind `@course.present? && policy(@course).update?` (with a comment noting exactly why: "header is shared by ~30 views"), and the sidebar's only `@course` use is an equality check (`course == @course`) that's nil-safe by construction. No regression here — flagging it as checked, not as a bug.

One pre-existing (not new) gap worth a note while you're in this area: the sidebar only actually paints on pages that either render `shared/_sidebar` directly inline (`courses/show`, `projects/show`, `topics/show` — the three fully-rewritten pages) or explicitly populate `content_for(:sidebar)` (`courses/profile.html.erb`, `lecturers/show.html.erb` — both bridged to the new sidebar as part of this branch, good). Everything else that doesn't opt out via `no_sidebar` — `participants/index`, `progress_updates/*`, `project_groups/index`, `static_pages/*`, `user/profile` — just silently renders without a sidebar, because nothing populates the yield. That's the same architecture `main` had (I diffed `main`'s layout to confirm), so it's not something this branch broke. But several of those pages are on your Follow-up list, so it's worth deciding now whether "no sidebar" is the intended interim state for them or just an artifact of the old layout nobody's revisited — otherwise whoever redesigns `user/profile.html.erb` next will inherit an ambiguous default.

CSS cleanup: confirmed the entire legacy `app/assets/stylesheets/` directory — including the literally-named `backup_courses.css` — was deleted in this branch in favor of `app/assets/tailwind/application.css`. That's exactly the cleanup this audit is checking for, done correctly. Good sign that the team does clean up when it gets to it; the partials in §1 are just what didn't get swept yet.

---

## 7. JavaScript vs. Copeland ch. 10–11

Stimulus-only, no jQuery, controllers eager-loaded via the standard `eagerLoadControllersFrom` importmap convention — this is squarely "carefully choose one framework" done right, and it's a clean fit for "embrace server-rendered Rails views."

One thing worth a deliberate look: **htmx and Turbo Frames are both in active use for the same job** — swapping a fragment of HTML in response to a request. Turbo Frames handle the copy-topic and copy-course overlays and the coursecode widget; htmx (extensively — 6+ partials) handles the courses/show People, Groups, and Topics-directory search/sort/filter/paginate. If htmx was picked deliberately for that corner because `hx-include`/`hx-vals` composes multiple sibling filter inputs into one request more declaratively than Turbo Frames does out of the box, that's a legitimate, defensible reason — worth writing down as an ADR next to the others in `docs/adr/`, the same way the coursecode widget and sidebar-collapse decisions are. Right now it reads as two different answers to "how do we swap HTML" living in different corners of the same app, and the next contributor won't know which one to reach for on the next table.

`_topic_picker.html.erb`'s `<script type="application/json">` block isn't an issue — it's a JSON data-island read by a Stimulus target, not inline imperative JS. Flagging that I checked it and it's fine, since it was the only inline `<script>` in a touched view.

---

## 8. Tailwind, `@theme`, and your question about a pass over refactored pages

**Yes — and it's already partially in motion, which is worth knowing before you scope the pass.** Your own `docs/tailwindcss_audit_plan.md` mapped every hardcoded hex to a Material 3 semantic token back when `@theme` didn't exist at all, and the `added in @themes and switched course/show to use it now` commit acted on it — `app/assets/tailwind/application.css` now has a real `@theme` block with 27 tokens (`--color-on-surface`, `--color-primary`, `--radius-panel`, `--breakpoint-comments`, etc.), and `courses/show` was migrated to use them.

Re-running the same measurement your audit doc used, live on this branch right now:

- **56 distinct hex colors** still appear as raw `text-[#...]`/`bg-[#...]`/etc. across `app/views/` — of which **only 22 map to an existing `@theme` token**. The other 34 (mostly near-duplicate blues — `#1557b0`, `#1967d2`, `#1a6abf`, `#1f78d1` — and a long, barely-distinguishable grey ramp — `#f8f9fa`, `#efefef`, `#e8eaed`, `#eef0f4`, `#ebebeb`, `#dfdfdf`, `#e1e1e1`, `#d9d9d9`, `#c4c4c4`) don't have a home yet — they're either genuinely new colors or someone eyeballed a shade instead of reusing the token, and you can't tell which without going file by file.
- **1,067 arbitrary hex utility usages total** across `app/views/`, and **64 of the 105 view files touched by this branch** (61%) still contain at least one. `#5F6368`, `#1A73E8`, `#3C4043`, `#E0E0E0`, `#DADCE0` are the top five by volume, and every one of them is a byte-for-byte match for an already-defined token (`on-surface-variant`, `primary`, `on-surface`, `outline-variant`, `outline`).
- Your own style guide mockup already flags one instance of exactly this drift by name: it calls out `projects_show_html.erb`'s comment timestamps using `text-[#5F6368]` instead of the token used on every other comments panel.

So: `course/show` is done, the token set and mapping work is done, and the rest is a mechanical find-and-replace across the other five-plus redesigned view groups (`projects/*`, `topics/*`, `shared/_header`/`_sidebar`, the comments partials) — not new design work, just applying a decision that's already made. I'd scope it as its own short pass rather than folding it into feature work, since it touches almost every file this branch touched and is easy to verify mechanically (grep for the theme's hex values in bracket-notation and swap to the token class).

## 9. Your question about the style guide

`ProPro_Design/style_guide.html.erb` is comprehensive as a reference — 23 sections covering colors, typography, radius, spacing, nav, tabs, cards, buttons, forms, comments, diff viewer, tables, dropdowns, modals, and more. Two things worth knowing before you feed the new components into it:

1. It lives at `ProPro_Design/`, outside `app/views` — it's not a route in the app, just a static mockup file, so it's hand-maintained and can't reuse your actual partials even if you wanted it to.
2. It's already drifted from the real tokens: it styles everything with inline `style="color: var(--gm3-sys-color-on-surface, #1f1f1f)"` — a `--gm3-sys-color-*` naming scheme with hardcoded hex fallbacks — which doesn't match the `--color-on-surface` tokens actually defined in `@theme` today. It's a second, parallel source of truth for the same colors, and it's already out of sync with the one that ships.

Given that, "add the established components to the style guide" is worth doing as a live Rails page (even a dev-only route) that literally `render`s `shared/_row_item`, `shared/_empty_state`, `shared/_form_action_bar`, `_section_header`, etc. with representative locals, rather than hand-copied markup snippets. That gets you two things at once: the style guide can never drift from the real components again (it *is* them), and it becomes a forcing function for §2's locals problem — a partial that can't be rendered with a clean `locals:` interface is annoying to drop into a style guide page, which is exactly the kind of pressure that gets that convention followed consistently instead of on 34 of 78 files.

---

## Summary

| Area | Finding |
|---|---|
| Unused partials | 9 confirmed dead, `project_groups/` is 6-of-8 dead and tied to the unmerged grouping feature |
| Locals convention | 34/78 partials documented; 16 touched-this-branch partials use ivars instead, 4 contradict their own `locals:` header |
| Helpers | 1 DB query in a helper, 1 ivar-coupled domain lookup, 1 duplicated method across two modules |
| Presenter | Well-built, undermined by ivar injection at the one call site |
| JS | Clean Stimulus-only setup; htmx + Turbo Frames doing the same job in different corners, undocumented |
| CSS cleanup | Legacy stylesheets fully removed — done correctly |
| Layout/header/sidebar | Nil-safe against courseless pages — no regression found |
| `@theme` | 1,067 raw hex usages remain, 61% of touched files affected, mechanical (not design) work remaining |
| Style guide | Comprehensive but disconnected from the app and already drifted from the real tokens |