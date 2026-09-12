# ProPro — Tailwind Sustainability Audit: Results
**Branch:** `refactor/design` · **Scope:** redesigned views only (`courses/show`, `courses/settings`, `projects/show`, `projects/new`, `projects/edit`, `topics/*`, `shared/_header`, `shared/_sidebar`, `application.html.erb`) plus the asset pipeline that feeds them.

---

## 0. Ground truth confirmed by this pass (grep/wc counts, not estimates)

| Signal | Count | Where |
|---|---|---|
| Distinct hardcoded hex colors in `app/views/` | 47 | arbitrary classes + `style=` |
| Arbitrary bracket values (`text-[...]`, `w-[...]`, `p-[...]`, etc.) | ~1,599 | across `app/views/` |
| Inline `style="..."` attributes | 143, across 30 files | mostly font-family declarations |
| No `tailwind.config.*` file anywhere | 0 | confirmed absent |
| No `@theme {}` block in `app/assets/tailwind/application.css` | 0 | confirmed — zero design tokens defined anywhere |
| `min-[1245px]:` custom breakpoint, repeated raw | 38× | `projects/show`, `topics/show`, related partials |

Tailwind v4 is in use (`@import "tailwindcss"` syntax, no config JS), which is exactly what makes the missing `@theme` block worse — v4's whole pitch is CSS-native tokens, and none are defined. Every color/spacing/radius/breakpoint decision is being re-invented ad hoc, per element, per view.

---

## 1. Fonts — confirmed "4 fonts" complaint, with specifics

> **RESOLVED 2026-09-04:** Google Sans has been swapped to **DM Sans** across the codebase (layout `<link>`, all inline `font-family` stacks, the Tailwind arbitrary `Google_Sans` classes, the `font-google-sans` no-op class, and the `ProPro_Design/` mockups). `GOOGLE_SANS_FONT` → `DM_SANS_FONT` in `breadcrumb_helper.rb`. Inter was removed from the layout `<link>` (dead on all redesigned pages) and the body font changed to Roboto. The record below is the *pre-swap* state.

### 1A. All distinct font-stack strings (pre-swap)

**10 distinct font stacks** found across views and stylesheets, plus `inherit`:

| # | Stack | Fallback chain | Delivery | Occurrences |
|---|---|---|---|---|
| 1 | `'Google Sans', Roboto, Arial, sans-serif` | GS → Roboto → Arial → sans-serif | Inline style | 8 |
| 2 | `Google Sans,Roboto,Arial,sans-serif` | GS → Roboto → Arial → sans-serif | Inline style / Ruby constant | 3 |
| 3 | `'Google Sans', sans-serif` | GS → sans-serif | Inline style | 21 |
| 4 | `font-[Google_Sans arbitrary class]` | GS → sans-serif | Tailwind arbitrary class | 6 |
| 5 | `font-['Roboto',sans-serif]` | Roboto → sans-serif | Tailwind arbitrary class | 9 |
| 6 | `font-['Inter']` | Inter only (no fallback) | Tailwind class on `<body>` | 1 |
| 7 | `"Inter", sans-serif` | Inter → sans-serif | Legacy CSS | 4 |
| 8 | `Inter, sans-serif` | Inter → sans-serif | Inline style (mailers) | 7 |
| 9 | `Arial, sans-serif` | Arial → sans-serif | Inline style (mailers) | 22 |
| 10 | `-apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif` | System stack | Legacy CSS | 2 |

**4 distinct Google Sans variants** exist, differing in quoting, fallback depth, and syntax:

| Variant | Fallbacks | Quoting | Issue |
|---|---|---|---|
| `'Google Sans', Roboto, Arial, sans-serif` | Roboto, Arial, sans-serif | Single-quoted | Deep fallback chain |
| `Google Sans,Roboto,Arial,sans-serif` | Roboto, Arial, sans-serif | Unquoted | Browser may parse space as separator |
| `'Google Sans', sans-serif` | sans-serif only | Single-quoted | Shallow fallback |
| `font-[Google_Sans arbitrary class]` | sans-serif only | Tailwind class | Different syntax entirely |

Variant 2 (unquoted) risks the browser looking for a font named just `Google` due to the space.

### 1B. `GOOGLE_SANS_FONT` constant

```ruby
# app/helpers/breadcrumb_helper.rb, line 2
GOOGLE_SANS_FONT = 'Google Sans,Roboto,Arial,sans-serif'
```

Used on lines 32 and 44 via `style: "font-family: #{GOOGLE_SANS_FONT}"`. Renders the unquoted form.

### 1C. Files using each Google Sans variant

**Variant 1** (`'Google Sans', Roboto, Arial, sans-serif`):
- `shared/_sidebar.html.erb:17,23,34,52`
- `courses/show.html.erb:46`
- `topics/_context_header.html.erb:65`
- `projects/_project_header.html.erb:70`

**Variant 2** (`Google Sans,Roboto,Arial,sans-serif`):
- `shared/_header.html.erb:20`
- `breadcrumb_helper.rb:2,32,44`

**Variant 3** (`'Google Sans', sans-serif`):
- `projects/_record_update_modal.html.erb:13`
- `projects/_lecturer_picker.html.erb:11`
- `projects/_progress_updates.html.erb:52`
- `projects/_topic_picker.html.erb:9`
- `projects/_project_review_card.html.erb:6`
- `projects/_project_overview.html.erb:27`
- `projects/_project_comments.html.erb:13`
- `projects/edit.html.erb:39`
- `projects/new.html.erb:26`
- `topics/_topic_review_card.html.erb:6`
- `topics/_topic_overview.html.erb:26`
- `topics/_topic_comments.html.erb:13`
- `topics/edit.html.erb:39`
- `topics/new.html.erb:26`
- `courses/_students_section.html.erb:9`
- `courses/_groups_tab.html.erb:8`
- `courses/_lecturers_section.html.erb:8`
- `courses/settings.html.erb:23`
- `courses/_copy_course_overlay.html.erb:16,30`

**Variant 4** (`font-[Google_Sans arbitrary class]`):
- `projects/new.html.erb:68`
- `projects/edit.html.erb:42,88`
- `topics/new.html.erb:61`
- `topics/edit.html.erb:42`
- `topics/_copy_topic_overlay.html.erb:26`

### 1D. Inter usage in redesigned pages

**Inter is NOT the effective font on ANY redesigned page.** Every redesigned page wraps its content in `<div class="... font-['Roboto',sans-serif]">` which overrides the body's `font-['Inter']`:

| Page | Override location |
|---|---|
| courses/show | `courses/show.html.erb:21` |
| courses/settings | `courses/settings.html.erb:13` |
| projects/show | `projects/show.html.erb:20` |
| projects/new | `projects/new.html.erb:9` |
| projects/edit | `projects/edit.html.erb:21` |
| topics/show | `topics/show.html.erb:22` |
| topics/new | `topics/new.html.erb:9` |
| topics/edit | `topics/edit.html.erb:21` |

**Where Inter IS the effective font (only):** the header and sidebar chrome — the "Log out" button text, mobile breadcrumb text, sidebar logout text. All nav links override to Google Sans.

**Verdict:** Inter (fully loaded, 4 weights) is functionally dead as a UI font on redesigned pages. The effective fallback chain is: Google Sans (phantom) → Roboto → Material Symbols.

---

## 2. Tailwind bundle duplication — highest-leverage fix

### 2A. Asset pipeline

- **Pipeline:** Propshaft (not Sprockets)
- **Tailwind gem:** `tailwindcss-rails` ~> 4.3 (resolved 4.3.0), `tailwindcss-ruby` 4.1.12
- **Source input:** `app/assets/stylesheets/new_tailwind.css` (1 line: `@import "tailwindcss"`)
- **Compiled output:** `app/assets/builds/tailwind.css` (minified v4.1.12 output)
- **No** `tailwind.config.js` exists anywhere

### 2B. Layout stylesheet loading

`app/views/layouts/application.html.erb`:
```erb
<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
<%= yield :stylesheets %>
```

The layout loads `"tailwind"` once, globally. All per-view calls are redundant.

### 2C. Redundancy quantification

**Category A — `content_for :stylesheets` calls (21 views):**

All load `"tailwind", "new_tailwind"`. Both are redundant/dangerous:

| # | File |
|---|---|
| 1 | `homescreen/show.html.erb:2` |
| 2 | `project_templates/edit.html.erb:2` |
| 3 | `sessions/new.html.erb:2` |
| 4 | `lecturers/show.html.erb:2` |
| 5 | `user/profile.html.erb:2` |
| 6 | `user/new_student.html.erb:3` |
| 7 | `user/new_staff.html.erb:3` |
| 8 | `passwords/new.html.erb:2` |
| 9 | `progress_updates/new.html.erb:3` |
| 10 | `progress_updates/show.html.erb:3` |
| 11 | `progress_updates/edit.html.erb:3` |
| 12 | `topics/index.html.erb:2` |
| 13 | `static_pages/terms_of_service.html.erb:3` |
| 14 | `static_pages/about.html.erb:3` |
| 15 | `static_pages/privacy_policy.html.erb:3` |
| 16 | `project_groups/index.html.erb:3` |
| 17 | `courses/settings.html.erb:2` |
| 18 | `courses/add_lecturers.html.erb:2` |
| 19 | `courses/add_students.html.erb:2` |
| 20 | `courses/new.html.erb:2` |
| 21 | `courses/profile.html.erb:2` |

**`new_tailwind.css` is one line: `@import "tailwindcss"`** — a Tailwind v4 build directive, not valid browser CSS. When Propshaft serves it to the browser, the `@import "tailwindcss"` resolves to nothing (browsers can't resolve a bare `"tailwindcss"` import). All 21 `"new_tailwind"` loads produce **zero visual effect** — pure dead weight HTTP requests.

**Category B — Direct body-injected calls (3 views):**

These place `<link>` tags in `<body>` (invalid HTML) and load only `"tailwind"` (already in layout):

| # | File | Line |
|---|---|---|
| 22 | `projects/show.html.erb` | 4 |
| 23 | `topics/show.html.erb` | 4 |
| 24 | `courses/show.html.erb` | 5 |

**Category C — Legacy `courses` stylesheet (3 views):**

| View | Also loads Tailwind? |
|---|---|
| `user/new_student.html.erb` | Yes (redundant) |
| `user/new_staff.html.erb` | Yes (redundant) |
| `passwords/edit.html.erb` | **No** — only stylesheet on this page |

### 2D. Summary

| Metric | Count |
|---|---|
| Total `stylesheet_link_tag` calls (layout + all views) | 28 |
| Layout-level `"tailwind"` loads | 1 (canonical) |
| Redundant `"tailwind"` loads in views | **24** |
| Ineffective `"new_tailwind"` loads (no-op in browser) | **21** |
| **Total redundant / dead stylesheet tags** | **45** |
| Views loading legacy `"courses"` CSS | 3 |

---

## 3. Legacy CSS — disposition

| File | Lines | Selectors | `stylesheet_link_tag` refs | Verdict |
|---|---|---|---|---|
| `courses.css` | 840 | 63 | 3 views | **PARTIALLY LIVE** — 2 of 63 classes (`.main`, `.container`) used; ~97% dead |
| `projects.css` | 889 | 79 | 0 views | **DEAD** |
| `lecturers.css` | 495 | 43 | 0 views | **DEAD** |
| `project_templates.css` | 352 | 20 | 0 views | **DEAD** |
| `backup_courses.css` | 482 | 24 | 0 views | **DEAD** |
| `application.css` | 159 | — | 0 views | **DEAD** |

**`courses.css`** — loaded by `passwords/edit`, `user/new_staff`, `user/new_student`. Of its 63 class selectors, only `.main` and `.container` are actually used on those 3 pages. The element-level rules (`body`, `html`, `h1`-`h5`, etc.) do apply but could be replaced with Tailwind.

**`projects.css`** — 889 lines, zero views load it. All projects views use Tailwind. **Safe to delete.**

**`lecturers.css`** — 495 lines, zero views load it. **Safe to delete.**

**`project_templates.css`** — 352 lines, zero views load it. Some class names appear in partials but the stylesheet is never linked. **Safe to delete.**

**`backup_courses.css`** — 482 lines, zero views load it. Appears to be a frozen copy of an older `courses.css`. **Safe to delete.**

**`application.css`** — 159 lines, zero views load it. Styles for `.topbar`, `.breadcrumb`, `.sidebar`, `.side-action`, `.sidebar-divider` are all inert. **Safe to delete.**

**Total dead legacy CSS: 2,837 lines** (projects + lecturers + project_templates + backup_courses + application) safe to delete immediately. `courses.css` needs 3 pages migrated first.

---

## 4. Design-spec drift — live vs. `ProPro_Design/style_guide.html.erb`

### 4A. CSS custom properties

**Zero usage.** The style guide references `var(--gm3-sys-color-on-surface, #1f1f1f)` in its `style=` attributes, but no `--gm3-sys-color-*` variables are defined anywhere in the codebase. The live implementation hardcodes every hex value directly in Tailwind arbitrary value classes.

### 4B. Color divergences

| # | Issue | Spec | Actual | Files |
|---|---|---|---|---|
| 1 | Headings use `#202124` instead of `#1f1f1f` | `text-[#1f1f1f]` | `text-[#202124]` | `_row_item:32`, `_overview_tab:15`, `_section_header:8,18` |
| 2 | Row item Redo pill uses `#E65100` | `text-[#F57F17]` | `text-[#E65100]` | `_row_item:13` |
| 3 | Primary button hover `#1557B0` | `hover:bg-[#1B66C9]` | `hover:bg-[#1557B0]` | `projects/edit:55,106`, `projects/new:38,86`, `topics/edit:55,96`, `topics/new:38,82`, `topics/_copy_topic_details:15,129` |
| 4 | Row item hover `#F1F3F4` | `hover:bg-[#F8F9FA]` | `hover:bg-[#F1F3F4]` | `_row_item:28` |
| 5 | Row item meta text 15px | `text-[14px]` | `text-[15px]` | `_row_item:51` |
| 6 | Row item pill `rounded` | `rounded-full` | `rounded` (4px) | `_row_item:34` |
| 7 | Project overview badge `rounded-[4px]` | `rounded-full` | `rounded-[4px]` | `_project_overview:18` |
| 8 | Eyebrow label wrong weight+color | `font-medium text-[#5F6368]` | `font-semibold text-[#3C4043]` | `_template_fields:15` (projects), `_template_fields:9` (topics) |
| 9 | Comment timestamps wrong size+color | `text-[14px] text-[#444746]` | `text-[12px] text-[#5F6368]` | `_project_comments:62` |
| 10 | Section headings in settings `text-3xl` (30px) | `text-[22px]` | `text-3xl` (30px) | `settings:55,82,109,206` |
| 11 | Eyebrow labels `text-[11px]` | `text-xs` (12px) | `text-[11px]` | `_project_details:40,71`, `_project_overview:35,44,49,63`, `_project_comments:37`, `_topic_field_list:39,54`, `_topic_comments:37`, `_topic_overview:45,50,70` |
| 12 | Row item title `font-normal` | `font-medium` (500) | `font-normal` (400) | `_row_item:50` |
| 13 | Projects canvas corner `rounded-tl-[16px]` | `rounded-tl-[28px]` | `rounded-tl-[16px]` | `projects/show:25` |
| 14 | Beta tag in settings uses `amber-*` palette | `bg-[#FFF8E1] text-[#F57F17]` | `bg-amber-100 text-amber-800` | `settings:206` |

### 4C. Generic Tailwind palette leakage (violates spec line 65-66)

The spec explicitly states: "Do not use generic Tailwind palette colors (`gray-*`, `blue-*`, `red-*`, `amber-*`) anywhere."

| File | Violations |
|---|---|
| `_course_code_form.html.erb` | `border-gray-100`, `text-gray-700`, `text-amber-600`, `border-gray-300`, `placeholder-gray-400`, `focus:ring-green-500`, `focus:border-green-500`, `bg-blue-200`, `hover:bg-blue-300`, `text-gray-800`, `bg-gray-400`, `peer-focus:ring-green-500`, `peer-checked:bg-green-500` |
| `_flash.html.erb` | `bg-red-50`, `border-red-500`, `text-red-800`, `text-red-700`, `bg-green-50`, `border-green-500`, `text-green-800`, `text-green-700` |
| `_project_header.html.erb` | `bg-green-50`, `border-green-200`, `text-green-700`, `bg-red-50`, `border-red-200`, `text-red-700` |
| `_project_actions.html.erb` | `text-green-600`, `bg-green-500` |
| `_groups_tab.html.erb` | `bg-gray-50`, `border-gray-200`, `text-gray-700`, `rounded-md` |
| `_students_section.html.erb` | `bg-gray-50`, `border-gray-200`, `text-gray-700`, `rounded-md`, `text-red-600`, `text-red-500`, `text-blue-600` |
| `settings.html.erb` | `text-gray-800` (×4), `border-gray-200`, `bg-amber-100`, `text-amber-800`, `text-amber-600` |
| `_overview_tab.html.erb` | `text-black` |
| `_topic_actions.html.erb` | `bg-gray-600`, `hover:bg-gray-700`, `border-blue-100`, `text-blue-600`, `bg-blue-50` |
| `_project_comments.html.erb` | `text-gray-300`, `text-gray-500`, `text-gray-400` |
| `_compare_versions_tab.html.erb` | `text-gray-300`, `text-gray-400` |
| `_progress_updates.html.erb` | `text-gray-300` |
| `application.html.erb` | `md:bg-sky-100`, `text-gray-950`, `text-gray-600`, `hover:bg-gray-50`, `hover:text-gray-900` |

### 4D. Typography divergences

| # | Issue | Spec | Actual | Files |
|---|---|---|---|---|
| 1 | Body font is Inter | Google Sans / Roboto | Inter | `application.html.erb:28` |
| 2 | Google Sans never loaded | Loaded in layout | Only referenced in views | `application.html.erb` (absent) |
| 3 | Section headings `text-3xl` (30px) | `text-[22px]` | `text-3xl` | `settings:55,82,109,206` |
| 4 | Eyebrow labels `text-[11px]` | `text-xs` (12px) | `text-[11px]` | 6 files, ~15 instances |

### 4E. Button hover inconsistency

| View pattern | Hover value | Correct? |
|---|---|---|
| `settings.html.erb` Save | `#1B66C9` | YES |
| `_project_actions.html.erb` Edit | `#1B66C9` | YES |
| `_record_update_modal.html.erb` Save | `#1B66C9` | YES |
| `_progress_updates.html.erb` Record | `#1B66C9` | YES |
| `projects/edit.html.erb` (both buttons) | `#1557B0` | **NO** |
| `projects/new.html.erb` (both buttons) | `#1557B0` | **NO** |
| `topics/edit.html.erb` (both buttons) | `#1557B0` | **NO** |
| `topics/new.html.erb` (both buttons) | `#1557B0` | **NO** |
| `topics/_copy_topic_details.html.erb` | `#1557B0` | **NO** |

---

## 5. Cross-page consistency

### 5A. Discrepancies found

| # | Concept | courses/show | projects/show & topics/show | Severity |
|---|---|---|---|---|
| D1 | Main shell corner radius | `rounded-tl-[28px]` (line 25) | `rounded-tl-[16px]` (lines 25, 27) | High — visible |
| D2 | Inner card corner radius | `rounded-[10px]` (overview_tab, topic_directory_tab, project_details_tab) | `rounded-[8px]` (project_overview, project_details, topic_overview, topic_field_list) | Medium — subtle but visible |
| D3 | Tab bar container horizontal padding | `px-4 sm:px-8` (line 31) | `px-8` fixed (lines 41, 39) | Low — only visible on <640px |
| D4 | Content panel horizontal padding | `px-6` (line 66) | `px-8` via `p-8` (lines 49, 51) | Low — 8px difference |

### 5B. Values confirmed consistent

| Concept | Value | Files |
|---|---|---|
| `min-h-[calc(100vh-3.5rem)]` | All three show pages | `courses/show:25`, `projects/show:25`, `topics/show:27` |
| Header `min-h-[3.5rem]` | Single source | `shared/_header.html.erb:1` |
| `max-w-5xl` (1024px) | All three show pages | `courses/show:66`, `projects/show:49`, `topics/show:51` |
| Tab height `h-[3rem]` | All three show pages | `courses/show:47`, `projects/_project_header:71`, `topics/_context_header:66` |
| Tab underline `h-[3px] rounded-t-[3px]` | All three show pages | Consistent |
| Tab button padding `px-3 sm:px-6` | All three show pages | Consistent |
| Tab gap `gap-x-2` | All three show pages | Consistent |
| Comments drawer `w-[360px] max-w-[90vw]` | projects & topics | Identical |
| Comments mobile height `h-[600px]` | projects & topics | Identical |
| Comments desktop height `min-[1245px]:h-[700px]` | projects & topics | Identical |
| Backdrop `bg-black/40` | projects & topics | Identical |
| Review card `rounded-[8px] p-5 gap-5` | projects & topics | Identical |
| Review action bar | projects & topics | Identical |
| Flash messages | projects & topics | Identical |
| Left pane `border-r border-[#E0E0E0]` | projects & topics | Identical |

### 5C. `min-[1245px]:` breakpoint — full inventory

**38 occurrences across 10 files:**

| File | Lines | Count | Purpose |
|---|---|---|---|
| `projects/show.html.erb` | 49, 114, 115, 129, 130, 131, 148 | 9 | Content pb, comments drawer translate/sticky/h/transition/shadow/border, backdrop |
| `topics/show.html.erb` | 51, 96, 97, 111, 112, 113, 147 | 9 | Same |
| `projects/_project_header.html.erb` | 90 | 1 | Comments trigger `hidden` |
| `topics/_context_header.html.erb` | 83 | 1 | Comments trigger `hidden` |
| `projects/_project_review_card.html.erb` | 3 | 1 | Review card `hidden`/`flex` |
| `topics/_topic_review_card.html.erb` | 3 | 1 | Review card `hidden`/`flex` |
| `projects/_review_action_bar.html.erb` | 7 | 1 | Action bar `hidden` |
| `topics/_review_action_bar.html.erb` | 7 | 1 | Action bar `hidden` |
| `projects/_review_actions.html.erb` | 55 | 5 | Dropdown menu origin flip |
| `topics/_review_actions.html.erb` | 57 | 5 | Dropdown menu origin flip |

Not used in: `shared/_sidebar.html.erb` (uses `lg:` / 1024px), `shared/_header.html.erb`, `courses/show.html.erb`.

---

## 6. Color palette — usage map

### 6A. Summary

| Metric | Value |
|---|---|
| Distinct hex colors (views only) | 47 |
| Total hex color occurrences (views) | 1,037 |
| Arbitrary bracket color values in views | 1,033 |
| Inline style color declarations | 1 |
| CSS custom property definitions (`--gm3-sys-color-*`) | 0 |

### 6B. Color map — sorted by occurrence count

#### Tier 1 — M3 Gray Scale Foundation

| Hex | Count | Semantic roles | M3 token |
|---|---|---|---|
| `#5f6368` | **189** | Secondary-text: labels, meta, hints, timestamps, chevrons, sidebar secondary | `on-surface-variant` |
| `#3c4043` | **143** | Primary text: body copy, titles, labels, table cells, comment bodies | `on-surface` |
| `#1f1f1f` | **29** | Heading text: modals, form headers, review cards, page titles | `on-surface` (alt) |
| `#202124` | **4** | Row-item titles, section header titles | `on-surface` (alt) |
| `#ffffff` | **20** | Surface background: cards, drawers, tab bars | `surface` |
| `#f8fafd` | **14** | Page/app background: body bg, sidebar bg | Custom tint |

#### Tier 2 — M3 Primary Blue Family

| Hex | Count | Semantic roles | M3 token |
|---|---|---|---|
| `#1a73e8` | **139** | Primary blue: links, buttons, borders, focus rings, avatars | `primary` |
| `#0b57d0` | **12** | Active tab text + underline, sidebar active | `primary` (dark) |
| `#1557b0` | **10** | Primary button hover (wrong — should be `#1B66C9`) | primary hover |
| `#1b66c9` | **5** | Primary button hover (correct) | primary hover (alt) |
| `#e8f0fe` | **20** | Primary container tint: pending pills, icon containers | `primary-container` |
| `#d3e3fd` | **3** | Sidebar active-item bg | `primary-container` |
| `#d2e3fc` | **1** | Tertiary container ring | primary-container lineage |
| `#1967d2` | **6** | Pending blue status pills | `primary` alt |

#### Tier 3 — Borders & Dividers

| Hex | Count | Semantic roles | M3 token |
|---|---|---|---|
| `#e0e0e0` | **114** | Default border/divider/outline | `outline-variant` |
| `#dadce0` | **68** | Input/control border | `outline` |
| `#f1f3f4` | **45** | Neutral muted surface + row hover | `surface-variant` |

#### Tier 4 — Status / Semantic Colors

| Hex | Count | Semantic roles | M3 token |
|---|---|---|---|
| `#137333` | **32** | Green: approval/success badges, approve buttons | `tertiary` (green) |
| `#e6f4ea` | **14** | Approved badge background | green container |
| `#c5221f` | **30** | Red: rejection/error/destructive, required markers | `error` |
| `#fce8e6` | **14** | Red/error container background | `error-container` |
| `#f57f17` | **12** | Amber: redo/pending-warning pills | `tertiary` (amber) |
| `#fff8e1` | **8** | Amber container background | amber container |
| `#fef7e0` | **3** | Amber container (redo) background | amber container |
| `#0f5c29` | **4** | Green hover-darken | tertiary hover |
| `#a50e0e` | **1** | Red hover-darken | error hover |
| `#b06000` | **2** | Amber/dark-orange redo text | on-tertiary |
| `#e37400` | **2** | Darker orange redo text/dot | Google orange |
| `#f2de8a` | **2** | Amber border for redo banners | amber outline |
| `#e65100` | **1** | Redo text in `_row_item` (wrong — should be `#F57F17`) | deep-orange |

#### Tier 5 — Greys & Neutrals

| Hex | Count | Semantic roles | M3 token |
|---|---|---|---|
| `#9aa0a6` | **5** | Disabled/muted text | on-surface-variant (disabled) |
| `#e1e3e1` | **3** | Neutral avatar/meter bg | surface-variant |
| `#d9d9d9` | **1** | Legacy avatar bg | legacy grey |
| `#7e7e7e` | **2** | Muted meta text | legacy grey |
| `#454343` | **1** | Legacy body text | legacy grey-black |
| `#313848` | **2** | Legacy file-link text | legacy navy |
| `#399be2` | **1** | Legacy file-icon bg | legacy blue |
| `#ebf0f9` | **2** | Legacy border | legacy pale blue |

### 6C. M3 Token Mapping Summary

| M3 Token Family | Hex values used | Notes |
|---|---|---|
| `primary` | `#1A73E8`, `#0B57D0`, `#1557B0`, `#1B66C9`, `#1967D2` | Blue family |
| `on-surface` | `#3C4043`, `#1F1F1F`, `#202124` | Text |
| `on-surface-variant` | `#5F6368`, `#9AA0A6` | Secondary text / disabled |
| `surface` | `#FFFFFF`, `#F8FAFD` (custom) | Card/page backgrounds |
| `surface-variant` | `#F1F3F4`, `#E1E3E1`, `#D9D9D9` | Muted surfaces/avatars |
| `outline` / `outline-variant` | `#DADCE0`, `#E0E0E0` | Borders/dividers |
| `primary-container` | `#E8F0FE`, `#D3E3FD`, `#D2E3FC` | Blue tints |
| `error` / `error-container` | `#C5221F`, `#A50E0E`, `#FCE8E6` | Red family |
| `tertiary` (green) | `#137333`, `#0F5C29`, `#E6F4EA` | Green/success |
| `tertiary` (amber) | `#F57F17`, `#E37400`, `#E65100`, `#B06000`, `#FFF8E1`, `#FEF7E0`, `#F2DE8A` | Amber/warning/redo |

The redesigned UI is a **Google M3 palette implemented entirely via Tailwind arbitrary-value hex literals** — no semantic token abstraction layer exists.

---

## 7. Workstream status (ordered by leverage)

| # | Workstream | Status | Key finding |
|---|---|---|---|
| 1 | **Bundle duplication** (§2) | **DONE** | 45 redundant/dead stylesheet tags across 24 views; `new_tailwind.css` is a no-op in the browser; highest-leverage fix |
| 2 | **Token extraction** (§6) | **DONE** | 47 distinct hex colors mapped to M3 tokens; ready for `@theme` definition |
| 3 | **Font consolidation** (§1) | **DONE** | 10 distinct stacks, 4 Google Sans variants; Inter dead on redesigned pages; phantom Google Sans everywhere |
| 4 | **Design-spec drift** (§4) | **DONE** | 14 color/typography/radius divergences + massive Tailwind palette leakage in 13+ files |
| 5 | **Cross-page consistency** (§5) | **DONE** | 4 discrepancies found (corner radius, card radius, tab padding, content padding); everything else consistent |
| 6 | **Legacy CSS disposition** (§3) | **DONE** | 2,837 lines safe to delete immediately; `courses.css` needs 3 pages migrated first |
