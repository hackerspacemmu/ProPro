# Merge Conflict Resolution: refactor/design ← main

Date: 2026-09-07

## Context

Merging `main` (older branch — OTP removal, is_staff removal, claim form changes) into `refactor/design` (HEAD — new design with `@theme` semantic tokens, hex colors, redesigned views).

**Strategy**: Keep `refactor/design`'s (HEAD) versions for all styling/structural conflicts. Pull in `main`'s claim form. Delete both orphaned files.

## Conflict Summary

Two divergent design approaches across 16 conflicted files:

- **HEAD (refactor/design)**: Semantic tokens (`text-on-surface`, `bg-surface`, `text-primary`, `border-outline-variant`, `bg-success-container`, etc.) via `@theme`
- **main**: Hardcoded hex colors (`text-[#5F6368]`, `bg-[#E0E0E0]`, `text-[#3C4043]`, etc.) — older Google-Classroom style

Most conflicts are purely styling. Several also carry structural/functional differences.

## Resolution Decisions

### 1. version_select_controller.js (add/add) → KEEP HEAD

HEAD has separate `project` / `topic` values with a branching `baseUrl` getter. main generalized to `resourceId` + `resource` (string). Keeping HEAD for consistency with existing topic/project view patterns.

### 2. homescreen/show.html.erb (content) → KEEP HEAD

HEAD uses `@theme` tokens, a `courses/_course_card` partial, clean layout. main has inline course card markup with hardcoded hex colors and a floating green `+` FAB button.

### 3. projects/show.html.erb (content) → KEEP HEAD

HEAD has clean tab panel structure. main adds mobile/tablet project actions section and a desktop-only progress update card inline — not part of the new design.

### 4. _compare_versions_tab.html.erb (add/add) → KEEP HEAD

Purely styling — same logic, `@theme` semantic tokens vs hex colors. 7 conflict markers, all the same pattern.

### 5. _context_header.html.erb (add/add) → KEEP HEAD

Mostly styling. main adds comment annotations (`<%# Sticky Tabs %>`, `<%# Comments trigger %>`) and uses `Google Sans` font. HEAD uses `DM Sans`.

### 6. _review_action_bar.html.erb (add/add) → KEEP HEAD

HEAD uses semantic tokens. main adds a `current_user:` local parameter that HEAD doesn't pass — removing the need for that extra plumbing.

### 7. _review_actions.html.erb (add/add) → KEEP HEAD

Beyond styling, main adds `current_user:` local, derives `is_member`/`is_history` at the top, and restructures coordinator/owner/student action logic. HEAD has the original action structure with `<section>` wrappers.

### 8. _topic_comments.html.erb (content) → KEEP HEAD

main moved student restriction INTO the partial (`if !@is_student` + fallback "Comments Restricted" section). HEAD keeps the restriction in `topics/show.html.erb` (wrapping the render call). Decision: keep it in show.html.erb.

### 9. _topic_overview.html.erb (add/add) → KEEP HEAD

Purely styling — 8 conflict markers, all semantic tokens vs hex colors.

### 10. _topic_review_card.html.erb (add/add) → KEEP HEAD

HEAD uses semantic tokens. main adds `current_user:` local (matching the `_review_actions` change).

### 11. topics/show.html.erb (content) → KEEP HEAD

Multiple structural differences beyond styling:
- HEAD uses `@current_fields` / `@compare_fields` / `@compare_index`; main uses `@fields` / `@next_fields` / `@index`
- HEAD uses `current_tab_index` helper; main uses inline `topic_tab_slugs.index(cookies[...])`
- HEAD does student restriction inline (lines 174-198); main moved it into `_topic_comments`
- HEAD uses `h-[calc(100vh-var(--spacing-header))]`; main uses `min-h-[calc(100vh-3.5rem)]`

### 12. user/claim.html.erb (content) → TAKE MAIN'S VERSION

HEAD has a "New Staff" form (email + OTP + password + confirmation). main has a "New User" claim form (email + institution ID + password). main's version is the correct one — part of the OTP/is_staff removal.

### 13. change_status_test.rb (content) → KEEP HEAD

HEAD uses `data-testid` CSS selectors and has 5 tests (including coordinator edit tests). main uses text-based assertions (`click_button 'Approve'`) and has 3 tests.

### 14. topic_versioning_test.rb (content) → KEEP HEAD

HEAD uses `assert_selector` with CSS selectors and `first(...).select(...)`. main uses `find()` with `option[selected]` and a `version_select_id` helper.

### 15. _topic_fields.html.erb (modify/delete) → DELETE

Deleted in HEAD (replaced by `_topic_field_list`), modified in main. Delete it.

### 16. new_student.html.erb (modify/delete) → DELETE

Deleted in main, modified in HEAD. No longer needed.

## Post-Resolution Notes

- main's OTP-removal and is_staff-removal commits should be auto-merged into non-conflicting files (controllers, models, routes, migrations). If anything breaks, check those diffs.
- The `current_user:` local parameter added by main in several topic partials is NOT needed since HEAD handles user checks differently.
