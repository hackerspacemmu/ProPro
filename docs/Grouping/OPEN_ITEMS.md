Backend pass to-do (single list). Tags: [R] left alone by the routes brief, [F] from the frontend plan, [C] found in the code.

Delete / cleanup

[x] [F] Delete stale promote-to-leader: group_leaders#update, resource :leader, promote_leader?, and their routing-test rows.
[F] Drop lecturers_can_manage_groups. manage_groups? becomes coordinator || lecturer.
[R] Remove the two legacy GET redirects after one release (/courses/:id/project_groups, /project_group_invite_links/:token). Keep join/:token.
[F] Remove @my_group_can_confirm from group_formations#show, since Confirm is now always enabled.
[C] dynamic_form_action_controller.js is unused app-wide, so delete it separately.

Policies
6. [R] destroy?, update? (was lock?/unlock?) and promote_leader? still check coordinator? instead of manage_groups?. Decide the intended matrix, e.g. coordinators deleting draft groups, and lecturers.
7. [F] The leader of a confirmed group can’t open Manage, because edit? needs a draft. Revisit if that read-only view is wanted.
8. [R] One ProjectGroupInvitePolicy serves both invite kinds. Consider one policy per kind.

Missing backend for UI
9. [F] Cancel join request: join_requests#destroy, a sender-only policy query, and a service. The UI shows “Request sent” with no cancel link until then.
10. [F] flash[:warning] and info variants. The shared flash only has alert and notice.
11. [F] Richer GroupConfirmer messages (“Needs 1 more member”, “would leave 1 student without a group”). Today it returns only window_closed, already_confirmed and size_illegal.
12. [F] Expose leader succession. promote_next_leader! picks the oldest membership, so the UI uses generic copy.
13. [F] Expose “self-leave reverts a confirmed group” in the Result. The Leave dialog copy is generic until then.
14. [F] Nullable or unlimited group max. The mockup’s “No size limit” variant isn’t built.
15. [F] Closed-state copy says “closed by your coordinator”, but grouping_window_open? is also false before the open date. Optionally split the copy by cause.
16. [F] @my_group_invite_token ignores expires_at, so an expired token still renders as copyable.

Refactors (no behaviour change)
17. [F] group_formations#show and groups#edit duplicate four queries (ungrouped students, pending requests, invite token, invited ids). Extract scopes.
18. [R/C] Eight controllers repeat set_course/set_group and the result.x? → notice else alert branch. Extract a concern or helper.
19. [C] group_members#create merges self-join and staff-add on params[:user_id].blank?. Consider splitting it.
20. [C] GroupsController mixes the Groups tab (htmx) with the write actions, and rescue StandardError is broad in update, destroy and leaders.
21. [F] N+1 on group.project and invites if the eager-load tweaks are skipped.
22. [F] Server-side picker search, only if the ungrouped list gets too big for a lazy frame. Turbo Stream “keep Manage open” is no longer needed.
23. [F] Live updates for requests and invites. The bell is only fresh on page load.

Shared UI debt
24. [F] courses/_tab_shell uses vh, not dvh. courses/_group_row and courses/_flash still use raw colours and the old dot pill. The Groups tab member detail is a single truncated column, while formation uses the 2-column grid.