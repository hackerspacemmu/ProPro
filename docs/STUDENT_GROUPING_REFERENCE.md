# Student Grouping CRUD - Quick Reference & Dependency Map

## Context Gathering Complete ✅

All related files have been identified and analyzed. This document serves as a **handoff guide** for the implementation agent.

---

## Current State Summary

### Already Implemented ✅
- Coordinator CRUD actions (create, delete, confirm, revert, lock, unlock)
- Course-level grouping settings (min/max, window dates, modes)
- Group confirmation algorithm with `can_confirm?` method
- Group size distribution for fixed list mode
- Basic database schema with `confirmed`, `locked`, `leader_id`
- Coordinator UI in project groups index
- Policy authorization framework

### Missing (Needs Implementation) ❌
- Student ability to **create** groups (route exists, partially implemented)
- Student ability to **join** draft groups (unlocked only)
- Student ability to **leave** groups with warnings
- Student ability to **send join requests** (if locked)
- Student ability to **send/receive invites**
- Student ability to **confirm** groups (with race condition guards)
- **Leader succession** when current leader leaves
- **Group dissolution** when last member leaves
- **ProjectGroupInvite** model and controller
- Race condition protection in `confirm!` using `with_lock`
- Student-facing views and components
- Comprehensive tests before implementation

---

## Dependency Chain (Implementation Order)

```
1. MODELS (Create/Enhance)
   └─ ProjectGroupInvite model ✨
   └─ ProjectGroup enhancements ⚡
   └─ Policies (ProjectGroupPolicy, ProjectGroupInvitePolicy) ⚡

2. DATABASE
   └─ Migration for project_group_invites table ✨

3. BUSINESS LOGIC (Core)
   └─ Confirm with lock (race condition guard) ⚡
   └─ Leader succession logic ⚡
   └─ Dissolution handling ⚡
   └─ Conflict clearing (invites/requests) ⚡

4. CONTROLLERS
   └─ ProjectGroupInvitesController ✨
   └─ ProjectGroupMembersController enhancements ⚡
   └─ ProjectGroupsController refinements ⚡

5. TESTS (CRITICAL - BEFORE EACH IMPLEMENTATION)
   └─ Unit tests for all business logic
   └─ Controller tests
   └─ Integration tests

6. VIEWS
   └─ Complete _my_group_panel.html.erb
   └─ Browse groups component
   └─ Pending invites component

7. NOTIFICATIONS
   └─ Notification service ✨
   └─ Warning messages (data loss prevention)
```

---

## Key Business Rules to Enforce

### Join/Leave Rules
- Student can only **join** draft, unlocked groups
- Student can only **join** within grouping window
- Student can only join if **ungrouped**
- Student can **leave** at any time within grouping window
- **Last member leaving** requires confirmation (warn about orphaned proposals)

### Confirm Rules
- **MUST use `with_lock`** to prevent race conditions
- **Re-check `can_confirm?` inside lock** before updating
- Default mode: member count within min/max
- Fixed list mode: member count in legal distribution

### Leader Rules
- Creator of group becomes leader
- Leader can: confirm, revert, lock/unlock, kick members, promote successor
- Leader can send invites to students
- **If leader leaves:** earliest-joined member becomes leader
- **If no members remain:** group is dissolved

### Dissolution Rules
- Automatic when last member leaves
- **WARN user if proposals will become inaccessible**
- Clear all pending invites/requests
- Delete group record

---

## Critical Implementation Notes

### Race Condition in Confirm
**Problem:** Member added/removed between `can_confirm?` check and `update!`  
**Solution:** Use database-level lock
```ruby
transaction do
  with_lock do
    return false unless can_confirm?  # Re-check inside lock
    update!(confirmed: true)
  end
end
```

### Leader Succession
**Problem:** Who becomes leader when current leader leaves?  
**Solution:** Track by creation timestamp (earliest member)
```ruby
earliest_member = project_group_members
  .order(created_at: :asc)
  .first
update!(leader_id: earliest_member.user_id)
```

### Conflict Clearing
**Problem:** User can be in only one group per course  
**Solution:** When user joins, clear all pending invites/requests
```ruby
ProjectGroupInvite
  .where(user_id: user.id, project_group: course.project_groups)
  .destroy_all
```

### Data Loss Warning
**Problem:** Removing member from group can orphan proposals  
**Solution:** Check before allowing leave/dissolution
```ruby
if @group.project&.present?
  warn_user_about_project_becoming_inaccessible
end
```

---

## File Status Matrix

| File | Type | Status | Priority | Notes |
|------|------|--------|----------|-------|
| `app/models/project_group.rb` | Model | ⚠️ Partial | 🔴 HIGH | Add: lock-based confirm, succession, dissolution |
| `app/models/project_group_invite.rb` | Model | ❌ Missing | 🔴 HIGH | Create with types: invite, request |
| `app/controllers/project_group_invites_controller.rb` | Controller | ❌ Missing | 🔴 HIGH | Create: accept, decline, create |
| `app/controllers/project_group_members_controller.rb` | Controller | ⚠️ Partial | 🔴 HIGH | Add student join/leave actions |
| `app/controllers/project_groups_controller.rb` | Controller | ⚠️ Partial | 🟡 MEDIUM | Refine with locks, authorization |
| `app/policies/project_group_policy.rb` | Policy | ⚠️ Partial | 🔴 HIGH | Add: join?, leave?, request?, etc |
| `app/policies/project_group_invite_policy.rb` | Policy | ❌ Missing | 🔴 HIGH | Create for invite actions |
| `app/views/project_groups/_my_group_panel.html.erb` | View | ⚠️ Partial | 🟡 MEDIUM | Complete ungrouped & grouped states |
| `app/views/project_groups/_browse_groups.html.erb` | View | ❌ Missing | 🟡 MEDIUM | Create for browsing available groups |
| `app/views/project_groups/_pending_invites.html.erb` | View | ❌ Missing | 🟡 MEDIUM | Create for invite management |
| `test/models/project_group_student_actions_test.rb` | Test | ❌ Missing | 🔴 HIGH | Create BEFORE implementing features |
| `test/models/project_group_invite_test.rb` | Test | ❌ Missing | 🔴 HIGH | Create BEFORE implementing features |
| `test/controllers/project_group_students_test.rb` | Test | ❌ Missing | 🔴 HIGH | Create BEFORE implementing features |
| `test/system/student_grouping_test.rb` | Test | ❌ Missing | 🟡 MEDIUM | Create for integration testing |

---

## Existing Codebase Reference

### Key Models & Methods Already Available
- `Course#group_size_distribution` - deterministic algorithm for fixed list mode
- `Course#grouping_window_open?` - check if grouping is currently open
- `ProjectGroup#can_confirm?` - business logic for confirmation validation
- `ProjectGroup#add_member!` - add with validation
- `ProjectGroup#remove_member!` - remove with cascade handling
- `ProjectGroup#revert_to_draft!` - revert confirmed → draft

### Key Policies Already Defined
- `ProjectGroupPolicy#coordinator?`
- `ProjectGroupPolicy#grouping_window_open?`
- Authorization framework for all actions

### Existing Routes
```ruby
resources :project_groups, only: %i[index create destroy] do
  member do
    patch :confirm
    patch :revert
    patch :lock
    patch :unlock
    patch :promote_leader
  end
  
  resources :project_group_invites, only: %i[create] do  # ← exists but not implemented
    member do
      patch :accept
      patch :decline
    end
  end
  
  resources :members, only: %i[create destroy], controller: 'project_group_members'
end
```

---

## Views Currently Rendered

**Project Groups Index:** `app/views/project_groups/index.html.erb`
- Shows: coordinator settings panel, groups list, ungrouped students list
- Renders: `_my_group_panel.html.erb` (student perspective)

**My Group Panel:** `app/views/project_groups/_my_group_panel.html.erb`
- **STATE A (Ungrouped):** ✅ Created (empty state with create/browse options)
- **STATE B (In Group - Member):** ⚠️ Partial (header, basic settings done)
- **STATE B (In Group - Leader):** ⚠️ Partial (needs expand)

---

## Database Tables Involved

### `courses`
- `grouping_enabled`, `student_list_finalised`
- `group_min`, `group_max`
- `grouping_open`, `grouping_opens_at`, `grouping_closes_at`

### `project_groups`
- `course_id`, `leader_id`
- `confirmed` (boolean), `locked` (boolean)
- `group_name`, `course_group_sequence`

### `project_group_members`
- `user_id`, `project_group_id`
- `created_at` (used for leader succession ordering)

### `project_group_invites` ✨ TO CREATE
- `user_id`, `project_group_id`
- `invitation_type` (enum: 'invite', 'request')
- `status` (enum: 'pending', 'accepted', 'declined')
- `created_at`, `updated_at`
- Unique constraint: (user_id, project_group_id, invitation_type)

---

## Testing Strategy

### Phase 1: Unit Tests (Must Come First)
Write tests for each business logic method before implementation:
- `confirm!` with lock behavior
- `remove_member!` with succession
- Conflict clearing on join
- Dissolution on last member leave

### Phase 2: Controller Tests
Test authorization and action flow

### Phase 3: Integration Tests
Full workflows: create → invite → accept → confirm → leave

### Phase 4: System Tests (Optional)
End-to-end UI testing if using Capybara

---

## Success Checklist for Handoff

- [x] All related files identified
- [x] Current state documented
- [x] Missing pieces listed
- [x] Business logic requirements captured
- [x] Technical decisions documented
- [x] Implementation order defined
- [x] Critical paths identified
- [x] Existing code referenced
- [x] File status matrix created
- [x] Race condition solutions documented
- [ ] Ready for implementation agent

---

## Questions for Implementation Agent

Before starting, clarify:

1. **Notifications:** What's the existing notification system? (ActionMailer, ActionCable, custom?)
2. **Soft Deletes:** Should invites be soft-deleted or hard-deleted?
3. **Test Framework:** Using Minitest or RSpec?
4. **Factory Syntax:** Existing factories use `create()` - continue with that?
5. **Turbo Streams:** Should actions use Turbo streams or traditional redirects?
6. **Timestamps:** Use `updated_at` for leader succession or `created_at` only?

---

**This document is ready for handoff to the implementation agent. All context has been gathered.**