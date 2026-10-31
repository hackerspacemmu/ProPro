# ADR 0025 — Group formation is a singular page with resourceful group writes

Date: 2026-10-31
Status: Accepted

## Context

The grouping workspace was a single `project_groups` resource carrying
member-style actions for everything that could happen to a group:
`confirm`, `revert`, `lock`, `unlock`, `promote_leader`, `join`,
`generate_invite_link`, plus nested `project_group_invites` and
`members`. Its URLs said "project group" while the course tab that
monitors the same records says "groups", and each write invented a verb
URL rather than naming the thing being changed.

The workspace page itself is not a collection: it is one page per
course, showing the viewer's group alongside the groups they may join.
The writes are about one group and its memberships, invitations and
link.

## Decision

- **The page is singular.** `resource :group_formation, only: :show`
  serves `/courses/:course_id/group_formation` through
  `GroupFormationsController#show`. It keeps
  `authorize @course, :grouping?`.
- **Group writes are resourceful and flat.** `resources :groups`
  provides `index`, `show`, `create`, `edit`, `update` and `destroy`
  through `GroupsController`. `index` and `show` remain the course
  Groups tab and a group's participant profile (ADR 0019, ADR 0022);
  writes use the same controller.
  - `update` owns the former lock/unlock actions through
    `project_group[locked]`.
  - `edit` is a lazy Turbo frame for the future Manage dialog; this ADR
    adds only the route and `ProjectGroupPolicy#update?`.
  - `destroy` owns dissolving a group.
- **The sub-resources are named after what they change.** Confirmation
  is a singular nested `confirmation` (`create`/`destroy`), leadership
  is `leader#update`, invite-link generation is `invite_link#create`,
  memberships are `members`, and invitations are split into
  `join_requests` (student asks to join) and `invitations` (leader asks
  a student). Each action passes an explicit policy query; invites use
  one `ProjectGroupInvitePolicy` with `:accept?` / `:decline?` chosen
  from a whitelisted `status`.
- **Invite links are top-level.** `/invite_links/:token` shows the join
  page and its nested `redemption#create` redeems it. `/join/:token` is
  a named GET redirect to that page, so shared links have a short form.
- **Legacy GETs redirect for one release.** `/courses/:course_id/
  project_groups` and `/project_group_invite_links/:token` redirect to
  the new pages. They are deliberately unnamed (`as: nil`) so they do
  not recreate the old route helpers.
- **Authorization is explicit at every call site.** Pundit infers
  `"#{action}?"`, so every new action passes the query it means:
  `update?`, `confirm?`, `revert?`, `promote_leader?`,
  `generate_invite_link?`, `join?`, `request_to_join?`, `direct_invite?`,
  `accept?`, `decline?`, `redeem?`.
- **Student and staff creation share one endpoint.** `ProjectGroupPolicy#
  create?` allows staff who manage groups or an enrolled student. Staff
  name the leader with `user_id`; a student's `user_id` is ignored and
  they lead their own group.

The course Groups tab and the grouping workspace remain separate
surfaces (ADR 0024); this ADR only makes the workspace's address and
writes canonical.

## Consequences

- The workspace URL is linkable as `course_group_formation_path`; group
  writes are `POST/PATCH/DELETE` on `course_group_path` and its named
  sub-resources.
- Join, invite-link generation and redemption move from `PATCH` to
  `POST`, matching their create semantics.
- The old `project_groups`, `project_group_invites`,
  `project_group_members` and `project_group_invite_links` controllers
  and helpers are gone; mailers, breadcrumbs, views and tests use the
  new paths.
- `project_groups#update_settings` is deleted. Grouping settings live
  only in Course Settings (ADR 0023).
- The Manage dialog is still future work: `groups#edit` renders only a
  minimal frame so the route and policy are ready.

## References

- ADR 0019 — course tabs are routes
- ADR 0022 — participant profiles are routes
- ADR 0023 — grouping settings live in Course Settings
- ADR 0024 — the Groups tab and grouping workspace stay separate
