# Group formation route refactor (agent brief)

Branch `feat/student-grouping-crud` @ `ab09fa6`. Routes and controllers only. Do NOT touch models, schema, services, Result handling, Stimulus controllers.

## Decisions (do not reopen)

- D1 `resource :group_formation` (page) + `resources :groups` (writes); flat controllers via `controller:`; no namespaces.
- D2 GET-only legacy redirects with `as: nil`; remove after one release.
- D3 Manage dialog = lazy frame on `groups#edit`; this PR adds only the route + `update?`. Dialog built later; must reload frame on every open.
- D4 `create?` = staff (`manage_groups?`) OR enrolled student. Staff name the leader; a student's `user_id` is ignored.
- D5 Leave other `coordinator?` checks (`destroy?`, `lock?`, `unlock?`, `promote_leader?`) as is.
- D6 Keep one `ProjectGroupInvitePolicy`; controllers pass explicit `:accept?` / `:decline?` from whitelisted `status`.
- D7 Keep all policy method names. Every new action passes an explicit query to `authorize`.
- D8 Page gate stays `authorize @course, :grouping?`.
- D9 Scope lookups: `@course.students.find`, kind-scoped invite finds, group-scoped member finds.
- D10 `get 'join/:token'` named `as: :join`; render `join_url(token)` at `_my_group_panel.html.erb:202`.
- D11 Tests: route-level only.

## Traps

1. **Pundit infers `"#{action}?"`.** Undefined query = deny all. Add `update?`; pass explicit queries:
   - `groups#edit/update` -> `update?` (new)
   - `group_confirmations#create/#destroy` -> `:confirm?` / `:revert?`
   - `group_leaders#update` -> `:promote_leader?`
   - `group_invite_links#create` -> `:generate_invite_link?`
   - `group_join_requests#create` -> `:request_to_join?`; `group_invitations#create` -> `:direct_invite?`
   - `group_join_requests#update` / `group_invitations#update` -> `:accept?` / `:decline?` from `status`
   - `invite_link_redemptions#create` -> `:redeem?`
2. **`GroupsController` lines 11-12** (`authorize_course`, `ensure_grouped`) must become `only: %i[index show]`, or writes get gated by `show?`.
3. **Never infer URLs from the model** (`redirect_to @group`, `form_with model:` without `url:`); `ProjectGroup` would resolve to `project_group_path`. Forms scope params under `project_group`.
4. **`groups#update`**: `params.expect(project_group: [:locked])` only. Refuse lock when `@group.leader_id.blank?` (port old `lock`, lines 101-104).
5. **Invites**: finds `.direct_request.find` / `.direct_invite.find`; `status` must be `accepted` or `declined`, else reject. Never `update(status: params[:status])`.
6. **`group_members#create`**: `params[:user_id].blank?` -> `authorize @group, :join?` + `GroupJoiner`; present -> `authorize @course, :manage_groups?` + `GroupMemberAdder`. A student sending `user_id` must be denied.
7. **`group_members#destroy`**: `@course.project_groups.find(params[:group_id]).project_group_members.find(params[:id])`. Rescue `RecordNotFound` around the member lookup only. Change both `redirect_back fallback_location: root_path` to `course_group_formation_path(@course)`. Update explicit partial paths (old lines 42, 57) to `group_members/dissolve_warning_modal` and `group_formations/ungrouped_student`. Keep the Turbo Stream branches.
8. **Invite-link nesting param** is `params[:invite_link_token]`; `show` reads `params[:token]`. `resources :invite_links` defaults to `InviteLinksController`.
9. **Legacy redirect without `as: nil`** recreates `course_project_groups_path`.
10. **Verb changes PATCH -> POST**: join, generate invite link, redeem.

## `create` (F7)

```ruby
# project_group_policy.rb
def create? = staff? || student?
# private
def staff?   = manage_groups_policy.manage_groups?
def student? = enrolment&.student?
```

```ruby
# groups_controller.rb
authorize @group
leader = policy(@course).manage_groups? ? @course.students.find(params.expect(:user_id)) : current_user
result = GroupCreator.new(@course, leader: leader, current_user: current_user).create!
```

Delete the unused hidden field `coordinator_create` (`index.html.erb:153`).

## `config/routes.rb`

DELETE 36-40, 100-125. REPLACE 76-79 (comment) and 81. Inside `resources :courses`:

```ruby
resource :group_formation, only: :show
resources :groups, only: %i[index show create edit update destroy] do
  resource  :confirmation,  only: %i[create destroy], controller: 'group_confirmations'
  resource  :leader,        only: :update,            controller: 'group_leaders'
  resource  :invite_link,   only: :create,            controller: 'group_invite_links'
  resources :members,       only: %i[create destroy], controller: 'group_members'
  resources :join_requests, only: %i[create update],  controller: 'group_join_requests'
  resources :invitations,   only: %i[create update],  controller: 'group_invitations'
end
```

Top level (where 36-40 was):

```ruby
resources :invite_links, only: :show, param: :token do
  resource :redemption, only: :create, controller: 'invite_link_redemptions'
end
get 'join/:token', to: redirect('/invite_links/%{token}'), as: :join
```

After line 132, before the error routes:

```ruby
# Legacy GET redirects. Remove after one release.
get '/courses/:course_id/project_groups', to: redirect('/courses/%{course_id}/group_formation'), as: nil
get '/project_group_invite_links/:token', to: redirect('/invite_links/%{token}'), as: nil
```

## Route map (c = course, g = group)

| Old | New | Controller#action |
| --- | --- | --- |
| GET project_groups | GET `course_group_formation_path(c)` | `group_formations#show` |
| POST project_groups | POST `course_groups_path(c)` (`user_id` for staff) | `groups#create` |
| DELETE project_group | DELETE `course_group_path(c, g)` | `groups#destroy` |
| PATCH lock / unlock | PATCH `course_group_path(c, g)` `project_group[locked]` | `groups#update` |
| none | GET `edit_course_group_path(c, g)` | `groups#edit` |
| PATCH confirm | POST `course_group_confirmation_path(c, g)` | `group_confirmations#create` |
| PATCH revert | DELETE `course_group_confirmation_path(c, g)` | `group_confirmations#destroy` |
| PATCH promote_leader | PATCH `course_group_leader_path(c, g)` `user_id` | `group_leaders#update` |
| PATCH generate_invite_link | POST `course_group_invite_link_path(c, g)` | `group_invite_links#create` |
| PATCH join / POST members | POST `course_group_members_path(c, g)` | `group_members#create` |
| DELETE members/:id | DELETE `course_group_member_path(c, g, m)` | `group_members#destroy` |
| POST invites (request) | POST `course_group_join_requests_path(c, g)` | `group_join_requests#create` |
| PATCH accept/decline (request) | PATCH `course_group_join_request_path(c, g, r)` `status` | `group_join_requests#update` |
| POST direct_invite | POST `course_group_invitations_path(c, g)` `user_id` | `group_invitations#create` |
| PATCH accept/decline (invite) | PATCH `course_group_invitation_path(c, g, i)` `status` | `group_invitations#update` |
| GET invite link | GET `invite_link_path(token)` | `invite_links#show` |
| PATCH redeem | POST `invite_link_redemption_path(token)` | `invite_link_redemptions#create` |
| PATCH update_settings | deleted | none |

## Per-file edits

| File | Action | Lines | What |
| --- | --- | --- | --- |
| `config/breadcrumbs.rb` | REPLACE | 125-128 | `crumb :group_formation`, label 'Group formation', `course_group_formation_path(course)` |
| `groups_controller.rb` | REPLACE | 11-12 | add `only: %i[index show]` |
| `groups_controller.rb` | ADD | after 65; private after 76 | `create`, `edit`, `update`, `destroy`, private `set_group`; `show` (line 59) uses `set_group` |
| `project_groups_controller.rb` | MOVE then DELETE | 5-30 | `GroupFormationsController#show` (keep `authorize @course, :grouping?`) |
| | | 32-45, 47-60 | `groups#create`, `groups#destroy` |
| | | 62-72 | `group_members#create` (self-join branch) |
| | | 74-84, 86-96 | `group_confirmations#create` / `#destroy` |
| | | 98-124 | merge into `groups#update` |
| | | 126-136 | `group_leaders#update` |
| | | 138-171 | delete (`update_settings`) |
| | | 173-183 | `group_invite_links#create` |
| `project_group_invites_controller.rb` | MOVE then DELETE | 6-16; 18-29; 31-53 | `group_join_requests#create`; `group_invitations#create` (line 20 `User.find` -> `@course.students.find`); accept/decline -> two `#update` actions |
| `project_group_members_controller.rb` | MOVE then DELETE | 10-24; 26-68 | `group_members#create` (staff branch, line 15 `User.find` -> `@course.students.find`); `#destroy` |
| `project_group_invite_links_controller.rb` | MOVE then DELETE | 4; 6-21 | `invite_links#show`; `invite_link_redemptions#create` (failure -> `invite_link_path(token)`, success -> `course_group_formation_path`) |
| `project_group_policy.rb` | REPLACE | 14-18 | `create?` per above |
| | REPLACE | 38-50 | `lock?` + `unlock?` -> one `update?` (same body); `edit?` inherits |
| | ADD | private, after 75 | `staff?`, `student?` |
| `course_policy.rb` | DELETE | 82-84 | `grouping_coordinator?` |
| `courses_controller.rb` | REPLACE | 746 | comment: `ProjectGroupsController#index` -> `GroupFormationsController#show` |

No change: `project_group_invite_policy.rb`, `project_group_invite_link_policy.rb`, `project_group_member_policy.rb`. Every `redirect_to course_project_groups_path(@course)` (~40) -> `course_group_formation_path(@course)`.

## Views

MOVE `app/views/project_groups/` -> `group_formations/` (`index.html.erb` -> `show.html.erb`); `project_group_members/_dissolve_warning_modal.html.erb` -> `group_members/`; `project_group_invite_links/show.html.erb` -> `invite_links/show.html.erb`.

| File:line | Old | New |
| --- | --- | --- |
| `index.html.erb:3` | `breadcrumb :project_groups` | `breadcrumb :group_formation` |
| `index.html.erb:152` | `course_project_groups_path` | `course_groups_path(@course)`; delete hidden field line 153 |
| `_group_card:72` | `..._project_group_invites_path` | `course_group_join_requests_path(course, group)` POST |
| `_group_card:78` | `join_..._path` PATCH | `course_group_members_path(course, group)` POST, no `user_id` |
| `_group_card:87` / `93` | confirm / revert PATCH | `course_group_confirmation_path(course, group)` POST / DELETE |
| `_group_card:148` | member path | `course_group_member_path(course, group, membership)` |
| `_group_card:193` | members path | `course_group_members_path(course, group)` |
| `_my_group_panel:54` | `course_project_groups_path` | `course_groups_path(@course)` |
| `_my_group_panel:82,86` | accept/decline invite | `course_group_invitation_path(@course, invite.project_group, invite)` PATCH `status: 'accepted'` / `'declined'` |
| `_my_group_panel:145` | group path DELETE | `course_group_path(@course, @my_group)` |
| `_my_group_panel:163,172` | confirm / revert | `course_group_confirmation_path` POST / DELETE |
| `_my_group_panel:181,186` | unlock / lock PATCH | `course_group_path` PATCH `project_group: { locked: false / true }` |
| `_my_group_panel:194` | generate link PATCH | `course_group_invite_link_path(@course, @my_group)` POST |
| `_my_group_panel:202` | `project_group_invite_link_url` | `join_url(token)` |
| `_my_group_panel:221,270` | member path | `course_group_member_path` |
| `_my_group_panel:264` | promote_leader PATCH | `course_group_leader_path(@course, @my_group)` PATCH `user_id` |
| `_my_group_panel:308,312` | accept/decline request | `course_group_join_request_path(@course, @my_group, join_request)` PATCH `status` |
| `_my_group_panel:337` | direct_invite path | `course_group_invitations_path(@course, @my_group)` POST `user_id` |
| `_dissolve_warning_modal:13` | member path | `course_group_member_path(...)` |
| `invite_links/show:21` | redeem PATCH | `invite_link_redemption_path(@invite_link.token)` POST |
| `courses/_overview_tab:33` | `course_project_groups_path` | `course_group_formation_path(@course)` |

## Mailers (`app/views/general_mailer/`, 10 files)

`course_project_groups_url(@group.course)` -> `course_group_formation_url(@group.course)` in: `group_direct_invite_accepted`, `group_direct_invite_declined`, `group_direct_invite_notification`, `group_direct_request_notification` (each `.html.erb:29` and `.text.erb:3`); `group_direct_request_accepted.text.erb:3`; `group_direct_request_declined.text.erb:3`.

## Tests

Update: `test/integration/grouping_settings_surface_test.rb:14,34` and `test/system/courses/overview_tab_test.rb:83` -> `course_group_formation_path`.

Add:
1. `test/routing/group_routes_test.rb`: one `assert_routing` per route-map row; `update_settings` raises `ActionController::RoutingError`; both legacy GETs redirect; `url_helpers.respond_to?(:course_project_groups_path)` is false.
2. `test/integration/group_write_routes_test.rb`: per action in trap 1, one allowed request (redirects to `course_group_formation_path`) and one denied (redirects to dashboard).
3. Behavior: student sending `user_id` to `members#create` denied; invalid `status` rejected and wrong-kind id 404s; `groups#create` follows D4 (lecturer with flag creates for chosen student, student's `user_id` ignored).

## Docs

New ADR 0025 (formation = singular resource, `groups` = write resource, partly supersedes 0024). Notes in ADR 0022 (redirects added), 0023 (`update_settings` resolved), 0019 (frame addendum), 0024 (reference paths). `CONTEXT.md`: add "group formation".

## Done when

- `git grep -nE "project_group_(invite_link|invite|member)s?_(path|url)|course_project_group|project_groups_path|redeem_project"` is empty outside `docs/`.
- `bin/rails routes -g project_group` shows nothing; the legacy redirects are unnamed.
- Suite passes.
- Manual: student create/join/request/accept/leave; leader lock/confirm/kick/promote/generate+redeem link; staff create and add; old emailed link and old invite link redirect correctly after login.