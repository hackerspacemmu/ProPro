# Student Grouping CRUD Implementation Tasks

**Status:** Ready for Implementation  
**Branch:** `feat/student-grouping-crud`  
**PR:** #327 (Feat/grouping settings)  
**Sprint:** Student Grouping CRUD Actions

---

## Phase 1: Data Models & Policies

### 1.1 Create ProjectGroupInvite Model
**File:** `app/models/project_group_invite.rb`  
**Status:** Not Started  
**Description:**  
- Create model to track group join invitations and requests
- Associations: `belongs_to :project_group`, `belongs_to :user`
- Attributes: `invitation_type` (enum: 'invite', 'request'), `status` (enum: 'pending', 'accepted', 'declined'), `created_at`, `updated_at`
- Add validations: uniqueness of (user_id, project_group_id, invitation_type)
- **Related Files:** 
  - Model needs to be created
  - Factory: `test/factories/project_group_invites.rb`

### 1.2 Migrate ProjectGroup Model
**File:** `app/models/project_group.rb`  
**Status:** Partially Complete  
**Description:**  
- Add associations to `ProjectGroupInvite`
- Add methods:
  - `leader_successor` - find earliest-joined member when leader leaves
  - `pending_requests` - return requests awaiting acceptance
  - `pending_invites` - return pending invites
  - `eligible_to_join_by?(user)` - check if user can join this group
  - **Add/Update Methods with Proper Locking:**
    - Update `confirm!` to use `with_lock` and re-check `can_confirm?` inside lock
    - Update `remove_member!` to handle leader succession
    - Update `remove_member!` to handle group dissolution
    - Add `dissolve!` method for explicit dissolution
- **Related Files:**
  - [app/models/project_group.rb](app/models/project_group.rb)

### 1.3 Update ProjectGroupPolicy
**File:** `app/policies/project_group_policy.rb`  
**Status:** Needs Expansion  
**Description:**  
- Add student action policies:
  - `join?` - check if user can join (ungrouped, window open, group is draft/unlocked)
  - `leave?` - check if user can leave (member of group, window open)
  - `request_to_join?` - check if user can send join request (ungrouped, window open)
  - `send_invite?` - check if user can send invite (is leader, window open, group is draft)
  - `accept_invite?` - check if user can accept invite (invite recipient, window open)
  - `decline_invite?` - check if user can decline invite (invite recipient)
  - `kick_member?` - check if user can kick member (is leader, grouping_open, not confirmed) 
- **Related Files:**
  - [app/policies/project_group_policy.rb](app/policies/project_group_policy.rb)
  - [app/policies/project_group_invite_policy.rb](app/policies/project_group_invite_policy.rb) - new file

---

## Phase 2: Backend Functionality

### 2.1 Create ProjectGroupInvitesController
**File:** `app/controllers/project_group_invites_controller.rb`  
**Status:** Not Started  
**Description:**  
- Implement actions:
  - `create` - send invite or join request
    - Determine type (invite if leader, request if member)
    - Validate user is not already in a group
    - Create `ProjectGroupInvite` record
    - Return success/error
  - `accept` - accept an invite (turbo_stream response)
    - Add user to group (clearing conflicting requests/invites)
    - Update invite status to 'accepted'
    - Send notification
  - `decline` - decline an invite
    - Update invite status to 'declined'
    - Send notification
- **Key Behaviors:**
  - Upon accepting: clear all other pending requests/invites for that user
  - Validate member count doesn't exceed max
- **Related Files:**
  - Routes already defined in `config/routes.rb`

### 2.2 Enhance ProjectGroupMembersController
**File:** `app/controllers/project_group_members_controller.rb`  
**Status:** Partial (coordinator actions only)  
**Description:**  
- Add student `create` action (join group directly if unlocked):
  - Authenticate student can join
  - Call `add_member!` 
  - Clear pending requests for this user
  - Redirect with notice
- Add student `destroy` action (leave group):
  - Authenticate student is member
  - Check if this is last member leaving (show warning)
  - Handle leader succession if leader is leaving
  - Call `remove_member!`
  - Redirect with notice/warning
  - **IMPORTANT:** Warn about projects that will become inaccessible
- **Key Validations:**
  - Student window must be open to join/leave
  - Cannot leave if it dissolves the group and there are active proposals
- **Related Files:**
  - [app/controllers/project_group_members_controller.rb](app/controllers/project_group_members_controller.rb)

### 2.3 Update ProjectGroupsController
**File:** `app/controllers/project_groups_controller.rb`  
**Status:** Needs Refinement  
**Description:**  
- Update `create` action for students:
  - Only allow if ungrouped + window open + not coordinator
  - Current user becomes leader (already done)
  - Set `confirmed: false` (already done)
- Update `confirm` action:
  - **CRITICAL:** Wrap in `with_lock` block
  - Re-check `can_confirm?` inside lock before updating
  - Handle race conditions where member count changed
- Update `destroy` action:
  - Students can only dissolve draft groups they lead (already restricted)
  - Prevent dissolution if group would orphan active proposals
- Add authorization checks for all student actions
- **Related Files:**
  - [app/controllers/project_groups_controller.rb](app/controllers/project_groups_controller.rb)

---

## Phase 3: Views & UI

### 3.1 Complete Student My Group Panel
**File:** `app/views/project_groups/_my_group_panel.html.erb`  
**Status:** Started (empty state and some grouped state)  
**Description:**  
- **STATE A - Ungrouped:**
  - ✅ Create group button (already done)
  - Browse groups / request to join section
  - Pending requests sent by student section
- **STATE B - In a Group (Member):**
  - Group header with name, member count, status badges
  - Settings column (lock/unlock, confirm, dissolve)
  - Members column with list
  - Actions column: leave, invite (if leader)
  - Pending requests/invites management (if leader)
  - **Show min/max member requirements**
- **STATE B - In a Group (Leader):**
  - Additional controls: kick members, promote new leader
  - Manage pending invites/requests
  - Confirm group button (with tooltip showing why disabled if applicable)
- **Warnings:**
  - Show when last member would leave (with project data warning)
  - Show when group would dissolve
- **Related Files:**
  - [app/views/project_groups/_my_group_panel.html.erb](app/views/project_groups/_my_group_panel.html.erb)

### 3.2 Create Group Browse/Request Component
**File:** `app/views/project_groups/_browse_groups.html.erb`  
**Status:** Not Started  
**Description:**  
- Display list of draft, unlocked groups
- Show: group name, member count, locked status
- Action: "Send join request" button per group
- Filter/search by group name
- Empty state: no groups available
- **Related Files:**
  - Partial new file

### 3.3 Create Pending Invites Component
**File:** `app/views/project_groups/_pending_invites.html.erb`  
**Status:** Not Started  
**Description:**  
- Show invites where current user is recipient
- Show: group name, sender (leader), date sent
- Actions: Accept, Decline
- Empty state: no pending invites
- **Related Files:**
  - Partial new file

### 3.4 Update Group Card (Coordinator View)
**File:** `app/views/project_groups/_group_card.html.erb`  
**Status:** Needs Update  
**Description:**  
- Add members count display
- Add "Manage requests/invites" section (if applicable)
- Show pending join requests (if coordinator viewing coordinator groups)
- **Related Files:**
  - Partial may need creation if it doesn't exist

---

## Phase 4: Business Logic & Race Condition Safety

### 4.1 Implement Lock-Based Confirm
**File:** `app/models/project_group.rb`  
**Status:** Not Started  
**Description:**  
- Update `confirm!` method:
  ```ruby
  def confirm!
    transaction do
      with_lock do
        # Re-check can_confirm? inside lock
        return false unless can_confirm?
        update!(confirmed: true)
      end
    end
  end
  ```
- Reason: Prevent race condition where members added/removed during confirmation
- **Related Files:**
  - [app/models/project_group.rb](app/models/project_group.rb)

### 4.2 Implement Leader Succession
**File:** `app/models/project_group.rb`  
**Status:** Not Started  
**Description:**  
- Add `promote_successor!` method:
  - Find earliest-joined member by `project_group_members.created_at`
  - Update group `leader_id` to new member
  - Return new leader
- Call in `remove_member!` when leader leaves:
  - Check if removed member was the leader
  - If leader and members remain: promote successor
  - If leader and no members: dissolve group
- **Related Files:**
  - [app/models/project_group.rb](app/models/project_group.rb)

### 4.3 Implement Group Dissolution Logic
**File:** `app/models/project_group.rb`  
**Status:** Partially Started  
**Description:**  
- `dissolve!` method:
  - Delete all pending invites/requests
  - Delete group (cascade destroys members)
  - Send notification to remaining members
  - **Check:** Will projects become inaccessible?
- Call when:
  - Last member leaves
  - Coordinator removes last member
  - Student dissolves their own draft group
- **Related Files:**
  - [app/models/project_group.rb](app/models/project_group.rb)

### 4.4 Handle Conflicting Requests/Invites
**File:** `app/controllers/project_group_invites_controller.rb` and `project_group_members_controller.rb`  
**Status:** Not Started  
**Description:**  
- When user accepts invite OR joins group:
  - Clear all other pending invites for that user
  - Clear all pending requests from that user
  - Reason: User can only be in one group per course
- Database query: `ProjectGroupInvite.where(user_id: user.id, project_group: course.project_groups)`
- **Related Files:**
  - [app/controllers/project_group_invites_controller.rb](app/controllers/project_group_invites_controller.rb) - new file
  - [app/controllers/project_group_members_controller.rb](app/controllers/project_group_members_controller.rb)

---

## Phase 5: Tests

### 5.1 Unit Tests - ProjectGroup Model
**File:** `test/models/project_group_student_actions_test.rb`  
**Status:** Not Started  
**Description:**  
- **CRITICAL:** Write before implementation of each feature
- Test `confirm!` with lock:
  - ✅ Confirms when can_confirm? is true
  - ✅ Returns false when can_confirm? is false
  - ✅ Prevents race condition (member added during confirm)
- Test leader succession:
  - ✅ Earliest member becomes leader when current leader leaves
  - ✅ Group dissolves when last member leaves
  - ✅ New leader inherits leadership responsibilities
- Test `remove_member!`:
  - ✅ Removes member correctly
  - ✅ Reverts group to draft if no longer meets min/max
  - ✅ Dissolves group if empty
  - ✅ Promotes successor when leader leaves
- Test `add_member!`:
  - ✅ Adds member when legal
  - ✅ Prevents adding if group at max (non-coordinator)
  - ✅ Prevents adding if already in another group
- **Related Files:**
  - [test/models/project_group_grouping_test.rb](test/models/project_group_grouping_test.rb) - existing
  - New file: `test/models/project_group_student_actions_test.rb`

### 5.2 Unit Tests - ProjectGroupInvite Model
**File:** `test/models/project_group_invite_test.rb`  
**Status:** Not Started  
**Description:**  
- Test creation and validation
- Test uniqueness constraint
- Test associations
- **Related Files:**
  - New file: `test/models/project_group_invite_test.rb`

### 5.3 Controller Tests - Student Actions
**File:** `test/controllers/project_group_students_test.rb`  
**Status:** Not Started  
**Description:**  
- Test student join/leave/create/confirm actions
- Test authorization (policy checks)
- Test turbo_stream responses
- Test notifications sent
- Test with/without grouping window open
- **Related Files:**
  - New file: `test/controllers/project_group_students_test.rb`

### 5.4 System/Integration Tests
**File:** `test/system/student_grouping_test.rb`  
**Status:** Not Started  
**Description:**  
- End-to-end student grouping workflow
- Test full flow: create → invite → accept → confirm → leave
- Test leader succession
- Test group dissolution
- **Related Files:**
  - New file: `test/system/student_grouping_test.rb`

---

## Phase 6: Notifications & Messaging

### 6.1 Create Notification Service
**File:** `app/services/group_notification_service.rb`  
**Status:** Not Started  
**Description:**  
- Send notifications for:
  - Invite sent (to invited student)
  - Join request received (to group leader)
  - Invite accepted (to student who sent invite)
  - Join request accepted (to student who sent request)
  - Member kicked (to kicked member)
  - Leader changed (to new leader)
  - Group dissolved (to all members)
- **Related Files:**
  - New file: `app/services/group_notification_service.rb`
  - Possibly: `app/mailers/group_mailer.rb`

### 6.2 Add Warning Messages
**File:** `app/controllers/project_group_members_controller.rb` and views  
**Status:** Not Started  
**Description:**  
- Last member leaving warning:
  - Show ONLY if there are proposals that will become inaccessible
  - Display project title(s) that will be affected
  - Require confirmation before allowing leave
- Group deletion warning:
  - When last member leaves or group is dissolved
  - Show what data will be affected
- **Related Files:**
  - Controller: [app/controllers/project_group_members_controller.rb](app/controllers/project_group_members_controller.rb)
  - Views: [app/views/project_groups/_my_group_panel.html.erb](app/views/project_groups/_my_group_panel.html.erb)

---

## Phase 7: Documentation & Cleanup

### 7.1 Update Database Schema Documentation
**File:** `doc/database.md` or `SCHEMA.md`  
**Status:** Not Started  
**Description:**  
- Document `project_group_invites` table
- Document changes to `project_groups` table
- Document relationship between models

### 7.2 Code Comments & Inline Documentation
**Status:** Not Started  
**Description:**  
- Add comments to complex logic (lock handling, succession, etc.)
- Document race conditions and their solutions
- Document business rules in code

---

## Implementation Sequence (Recommended Order)

1. **Models First:**
   - Create `ProjectGroupInvite` model + factory
   - Add associations to `ProjectGroup`
   - Update `ProjectGroupPolicy`
   - Create `ProjectGroupInvitePolicy`

2. **Database & Migrations:**
   - Create `project_group_invites` table migration
   - Run migrations

3. **Core Business Logic:**
   - Implement lock-based `confirm!`
   - Implement leader succession
   - Implement `remove_member!` enhancements
   - Implement invite/request clearing logic

4. **Controllers:**
   - Create `ProjectGroupInvitesController`
   - Enhance `ProjectGroupMembersController`
   - Update `ProjectGroupsController` with locks

5. **Tests:**
   - Write comprehensive unit tests for all business logic
   - Write controller tests
   - Write integration tests

6. **Views:**
   - Complete `_my_group_panel.html.erb`
   - Create supporting partials
   - Add warning components

7. **Notifications:**
   - Implement notification service
   - Add mailers if needed

8. **Polish:**
   - Handle edge cases
   - Test error scenarios
   - Documentation

---

## File Reference Summary

### Models to Create/Modify
- `app/models/project_group.rb` ⚡ CRITICAL
- `app/models/project_group_invite.rb` ✨ NEW
- `app/models/project_group_member.rb` (may need updates)

### Controllers to Create/Modify
- `app/controllers/project_group_invites_controller.rb` ✨ NEW
- `app/controllers/project_group_members_controller.rb` ⚡ CRITICAL
- `app/controllers/project_groups_controller.rb` ⚡ CRITICAL

### Policies to Create/Modify
- `app/policies/project_group_policy.rb` ⚡ CRITICAL
- `app/policies/project_group_invite_policy.rb` ✨ NEW

### Views to Create/Modify
- `app/views/project_groups/_my_group_panel.html.erb` ⚡ CRITICAL
- `app/views/project_groups/_browse_groups.html.erb` ✨ NEW
- `app/views/project_groups/_pending_invites.html.erb` ✨ NEW
- `app/views/project_groups/_group_card.html.erb` (may need update)

### Tests to Create
- `test/models/project_group_student_actions_test.rb` ✨ NEW
- `test/models/project_group_invite_test.rb` ✨ NEW
- `test/controllers/project_group_students_test.rb` ✨ NEW
- `test/system/student_grouping_test.rb` ✨ NEW

### Migrations to Create
- `db/migrate/[timestamp]_create_project_group_invites.rb` ✨ NEW

### Services to Create
- `app/services/group_notification_service.rb` ✨ NEW

---

## Key Technical Decisions

1. **Race Condition Prevention:** Use `with_lock` in `confirm!` method
2. **Leader Succession:** Track by `project_group_members.created_at` (earliest = successor)
3. **Invite/Request System:** Use single `ProjectGroupInvite` model with `invitation_type` enum
4. **Group Dissolution:** Automatic when last member leaves; check for data loss warnings
5. **Notifications:** Use existing notification system (if available) or create service
6. **Member Limits:** Enforce at model level + controller level for race safety

---

## Success Criteria

- ✅ All student can create groups (becomes leader automatically)
- ✅ All student grouping CRUD actions authorized properly
- ✅ Leader succession works correctly
- ✅ Race conditions in confirm handled with locks
- ✅ Join/leave with proper warnings
- ✅ Invite/request system fully functional
- ✅ Comprehensive tests before each PR
- ✅ No data loss on group dissolution
- ✅ All business rules enforced

---

**Legend:**  
- ⚡ CRITICAL - Core to implementation
- ✨ NEW - Create from scratch
- No symbol = Enhancement to existing file