# Student Grouping CRUD - Architecture & Flow Diagrams

## 1. Database Schema Diagram

```
┌──────────────────────┐
│      courses         │
├──────────────────────┤
│ id                   │
│ grouping_enabled     │
│ student_list_final   │
│ group_min/max        │
│ grouping_open        │
│ grouping_opens_at    │
│ grouping_closes_at   │
└──────────┬───────────┘
           │ 1:N
           ▼
┌──────────────────────┐         ┌─────────────────────────┐
│  project_groups      │         │  project_group_members  │
├──────────────────────┤    1:N  ├─────────────────────────┤
│ id                   ├────────►│ id                      │
│ course_id (FK)       │         │ project_group_id (FK)   │
│ leader_id (FK)       │         │ user_id (FK)            │
│ group_name           │         │ created_at (for suc.)   │
│ confirmed            │         │ updated_at              │
│ locked               │         └─────────────────────────┘
│ created_at           │
└──────────┬───────────┘
           │ 1:N
           ▼
      ✨ NEW
┌──────────────────────────────┐
│  project_group_invites       │
├──────────────────────────────┤
│ id                           │
│ project_group_id (FK)        │
│ user_id (FK)                 │
│ invitation_type (enum)       │
│   - 'invite' (leader sends)  │
│   - 'request' (student sends)│
│ status (enum)                │
│   - 'pending'                │
│   - 'accepted'               │
│   - 'declined'               │
│ created_at                   │
│ updated_at                   │
│ Unique: (user, group, type)  │
└──────────────────────────────┘
```

---

## 2. State Machine: Group Lifecycle

```
                    ┌─────────────────────────────┐
                    │  DRAFT (confirmed=false)    │
                    │  locked=false (unlocked)    │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
         ┌──────────▼────┐  ┌──────▼──────┐  ┌───▼─────────┐
         │ DRAFT LOCKED  │  │ CONFIRMED   │  │ DISSOLVED   │
         │ locked=true   │  │ confirmed   │  │ (deleted)   │
         └──────────┬────┘  │ =true       │  └──────▲──────┘
                    │       └──────┬──────┘         │
                    └──────────────┼────────────────┘
                                   │
                    ┌──────────────┴─────────────┐
                    │    Manual triggers:        │
                    │  - unlock() (leader)       │
                    │  - lock() (leader)         │
                    │  - confirm() (leader)      │
                    │  - revert() (leader)       │
                    │  - dissolve (auto)         │
                    └────────────────────────────┘

DISSOLUTION happens when:
  - Last member leaves group
  - Coordinator removes last member
  - Student leader dissolves their draft group
```

---

## 3. Student Action Flow: Join → Confirm → Leave

```
STUDENT 1: Create Group
═════════════════════════════════════════════════════════════
1. Student clicks "New group"
2. POST /courses/:course_id/project_groups (create action)
3. Validates: ungrouped + window_open
4. Creates ProjectGroup (confirmed=false, locked=false)
5. Creates ProjectGroupMember (user=student, as leader)
6. Redirect with "Group created"

                          ▼

STUDENT 2: Join Unlocked Group
═════════════════════════════════════════════════════════════
1. Student views _my_group_panel.erb (STATE A)
2. Clicks "Browse groups"
3. Sees list of draft, unlocked groups
4. Clicks "Join" on Group1
5. POST /courses/:course_id/project_groups/:id/members (create)
6. Validates: ungrouped + window_open + group.unlocked? + member_count < max
7. Calls group.add_member!(student)
   └─ Creates ProjectGroupMember
   └─ Clears all ProjectGroupInvites for this student
8. Redirect with "Joined Group1"
9. Now in GROUP STATE (STATE B)

                          ▼

STUDENT 2: Send Join Request (Locked Group)
═════════════════════════════════════════════════════════════
1. Student views locked group
2. Clicks "Send join request"
3. POST /courses/:course_id/project_groups/:id/project_group_invites
4. Creates ProjectGroupInvite(type: 'request', status: 'pending')
5. Notifies group leader
6. Group leader sees pending requests in _my_group_panel
7. Leader clicks "Accept"
8. PATCH /courses/.../project_group_invites/:id/accept
9. Validates: student ungrouped + window_open + within limits
10. Creates ProjectGroupMember
11. Clears conflicting invites/requests
12. Updates ProjectGroupInvite to 'accepted'
13. Notifies student "Request accepted"

                          ▼

STUDENT 1 (LEADER): Send Invite
═════════════════════════════════════════════════════════════
1. Leader in _my_group_panel (STATE B - Leader)
2. Sees invite form or student list
3. Clicks "Invite Student X"
4. POST /courses/.../project_group_invites
5. Creates ProjectGroupInvite(type: 'invite', status: 'pending')
6. Notifies Student X: "You're invited to Group1"
7. Student X sees in _pending_invites.html.erb
8. Student X clicks "Accept"
9. PATCH /courses/.../project_group_invites/:id/accept
10. Same as request acceptance flow

                          ▼

STUDENTS 1 & 2: Confirm Group
═════════════════════════════════════════════════════════════
1. Both in group (2 members)
2. Group shown in _my_group_panel (STATE B)
3. Leader sees "Confirm Group" button
4. Checks: within min/max (if default) OR in distribution (if fixed)
5. Leader clicks "Confirm Group"
6. PATCH /courses/:course_id/project_groups/:id/confirm
7. ⚡ CRITICAL: Use with_lock
   ┌─────────────────────────────────┐
   │ ActiveRecord::Base.transaction   │
   │  @group.with_lock do             │
   │    return false unless           │
   │      @group.can_confirm?  ◄──────┼─ RE-CHECK inside lock
   │    @group.update!(               │
   │      confirmed: true             │
   │    )                             │
   │  end                             │
   └─────────────────────────────────┘
8. Prevents race condition where member added/removed during confirm
9. Now confirmed group can create projects
10. Notifies members: "Group confirmed"

                          ▼

STUDENT 2: Leave Group (Normal)
═════════════════════════════════════════════════════════════
1. Student 2 in confirmed group
2. Clicks "Leave" in _my_group_panel (STATE B)
3. DELETE /courses/:course_id/project_groups/:id/members/:user_id
4. Validates: member + window_open (or allows confirmed leave?)
5. Calls group.remove_member!(student_2)
   ├─ Removes ProjectGroupMember
   ├─ Checks: if confirmed? and !can_confirm? → revert_to_draft!
   ├─ Checks: if no members remain → dissolve!
   └─ Checks: if leader left → promote successor
6. If NOT last member: just remove and redirect
7. If last member: warn user about orphaned data before confirm

                          ▼

STUDENT 1 (LAST): Leave Group (With Warning)
═════════════════════════════════════════════════════════════
1. Student 1 is last member in group
2. Group has active Project (proposal)
3. Clicks "Leave"
4. ⚠️ WARNING MODAL shows:
   ┌───────────────────────────────────────┐
   │ "Dissolving this group?"              │
   │                                       │
   │ The following project will become     │
   │ inaccessible to your group:           │
   │ • "Web App Proposal" (in progress)    │
   │                                       │
   │ [Cancel] [Yes, I'm sure]              │
   └───────────────────────────────────────┘
5. Confirms
6. DELETE /courses/.../project_groups/:id/members/:id
7. Calls group.remove_member!(student_1)
   ├─ Last member check: no members remain
   ├─ Finds active project
   ├─ Calls group.dissolve!
   │  ├─ Deletes all ProjectGroupInvites
   │  ├─ Deletes ProjectGroupMembers
   │  ├─ Deletes ProjectGroup
   │  └─ Note: Project stays (becomes orphaned)
8. Redirect: "Group dissolved"
9. Back to _my_group_panel STATE A (ungrouped)
```

---

## 4. Leader Succession Flow

```
SCENARIO: Leader leaves group, 3 members remain
═════════════════════════════════════════════════════════════

Initial State:
  Group: Group1 (leader_id = Alice)
  Members:
    - Alice     (created_at: 2026-05-01 10:00) ← LEADER
    - Bob       (created_at: 2026-05-02 11:00)
    - Carol     (created_at: 2026-05-03 12:00)

Alice clicks "Leave":
  1. DELETE /courses/.../members/alice_id
  2. Calls group.remove_member!(alice)
  3. In remove_member!:
     ├─ Deletes Alice from ProjectGroupMembers
     ├─ Reloads members: [Bob, Carol]
     ├─ Checks: was Alice the leader?
     │  └─ YES (leader_id == alice.id)
     ├─ Are there remaining members?
     │  └─ YES (2 remain)
     ├─ Call promote_successor!
     │  ├─ Query: ProjectGroupMembers
     │  │        .order(created_at: :asc)
     │  │        .first
     │  └─ Returns: Bob (earliest created_at)
     ├─ Update group: leader_id = Bob.id
     └─ Notify members: "Bob is now leader"

Final State:
  Group: Group1 (leader_id = Bob)
  Members:
    - Bob       (created_at: 2026-05-02 11:00) ← NEW LEADER
    - Carol     (created_at: 2026-05-03 12:00)

Result: Bob automatically becomes leader, inherits all leader powers
```

---

## 5. Invite/Request Conflict Clearing

```
SCENARIO: Student has pending requests/invites, then joins a group
═════════════════════════════════════════════════════════════

Initial State:
  Student: Charlie
  ProjectGroupInvites for Charlie:
    - Group1: type='request', status='pending'
    - Group2: type='invite', status='pending'
    - Group3: type='request', status='pending'

Charlie joins Group4 (unlocked, accepted by system):
  1. POST /courses/.../project_groups/group4/members
  2. Calls group.add_member!(charlie)
  3. In add_member!:
     ├─ Create ProjectGroupMember (charlie → Group4)
     └─ Call clear_conflicting_invites!(charlie)
        ├─ Query:
        │  ProjectGroupInvite.where(
        │    user_id: charlie.id,
        │    project_group: course.project_groups
        │  )
        │  .where.not(id: newly_created_invite.id)
        └─ Destroy all: [Group1 request, Group2 invite, Group3 request]

Result:
  - Charlie now in Group4 only
  - All pending requests/invites cleared
  - Charlie won't receive notifications about Group1, 2, 3
  - Leaders of those groups see: "Charlie withdrew request/declined invite"
```

---

## 6. Confirmation with Race Condition Prevention

```
CRITICAL PROBLEM:
═════════════════════════════════════════════════════════════
Between checking can_confirm? and update!(confirmed: true),
another member could be added/removed, invalidating confirmation.

TIMELINE OF RACE CONDITION:

Thread A: Student 1               Thread B: Student 2
─────────────────────             ─────────────────────
Group has 2 members (min=2, max=4)

                                  1. [Request join]
                                     POST /members
                                     group.add_member!(student_2)
                                     ✓ Member added
                                     Group now has 3 members

2. [Confirm group]
   PATCH /confirm
   can_confirm? checks:
     members.count == 2 ✓
     Returns: TRUE
   But now group has 3 members!
   This could violate rules in fixed list mode!


SOLUTION: Use with_lock
═════════════════════════════════════════════════════════════

def confirm!
  transaction do
    with_lock do  # ◄── LOCK acquired here
      return false unless can_confirm?  # RE-CHECK with lock held
      update!(confirmed: true)
    end
  end
end

Now:
Thread A: Student 1               Thread B: Student 2
─────────────────────             ─────────────────────
1. POST /confirm
   with_lock acquired
   ✓ Lock held on project_groups row

                                  2. POST /members
                                     Tries to acquire lock
                                     ⏳ BLOCKED - Thread A has lock

   can_confirm? checks:
     members.count == 2 ✓
     Returns: TRUE
   update!(confirmed: true)
   ✓ Confirmed
   
   with_lock released

                                  3. Lock released
                                     ✓ Lock acquired
                                     group.add_member!(student_2)
                                     But now confirmed=true
                                     Validation can check this

Result: Confirmation is atomic, safe from race conditions
```

---

## 7. Authorization Matrix

```
ACTION                  | COORDINATOR | LEADER | MEMBER | OTHER
──────────────────────────────────────────────────────────────────
Create group            |  ✓ any      |   -    |  ✓     |  ✗
View group              |  ✓          |  ✓     |  ✓     |  ✗
Join (unlocked)         |  ✗          |  -     |  ✓*    |  ✗
Join (locked/request)   |  ✗          |  -     |  ✓*    |  ✗
Send invite             |  ✓ any      |  ✓     |  ✗     |  ✗
Accept invite           |  ✓ any      |   -    |  ✓*    |  ✗
Decline invite          |  ✓ any      |   -    |  ✓*    |  ✗
Leave group             |  ✓ any      |  ✓     |  ✓     |  ✗
Kick member             |  ✓ any      |  ✓     |  ✗     |  ✗
Lock/unlock             |  ✓ any      |  ✓     |  ✗     |  ✗
Confirm                 |  ✓ any      |  ✓     |  ✗     |  ✗
Revert to draft         |  ✓ any      |  ✓     |  ✗     |  ✗
Dissolve (draft)        |  ✓ any      |  ✓     |  ✗     |  ✗
Remove member (as coord)|  ✓          |   -    |   -    |  ✗
Add member (as coord)   |  ✓          |   -    |   -    |  ✗
Move member (as coord)  |  ✓          |   -    |   -    |  ✗

* = Must be ungrouped (except if accepting invite into a group)
✓ = Allowed
✓ any = Can apply to any group in course
✗ = Not allowed
- = N/A (role not applicable)
```

---

## 8. View Component Hierarchy

```
app/views/project_groups/index.html.erb
└── Coordinator Settings Panel
    └── Grouping system toggle
    └── Mode selection (default/fixed)
    └── Min/max inputs
    └── Window date picker
    └── Preview distribution

└── Results Pane (Two-column layout)
    ├── Left: Groups Column
    │   └── _group_card.html.erb (partial, repeated)
    │       ├── Group info (name, status, locked)
    │       ├── Member count
    │       └── Actions (confirm, lock, etc.)
    │
    └── Right: My Group Panel ← STUDENT FOCUS
        └── _my_group_panel.html.erb
            ├── STATE A: Ungrouped
            │   ├── Create section
            │   │   └── "New group" button
            │   ├── Join section
            │   │   └── "Browse groups" button
            │   └── Pending requests section
            │
            ├── STATE B: In Group (Member)
            │   ├── Header (group name, status badge)
            │   ├── Settings column
            │   │   ├── Confirm button (if legal)
            │   │   └── Leave button
            │   ├── Members column
            │   │   └── List of members
            │   └── Invites column (if leader)
            │       └── Pending invites/requests
            │
            └── STATE B: In Group (Leader)
                ├── Additional controls
                │   ├── Lock/unlock button
                │   ├── Kick member buttons
                │   └── Promote to leader options
                └── Manage pending section
                    ├── Accept/decline requests
                    └── Accept/decline invites

Standalone Partials (Mounted in states):
├── _browse_groups.html.erb
│   ├── Search input
│   ├── Group list
│   │   └── Group card (clickable row)
│   │       ├── Group name
│   │       ├── Member count
│   │       ├── Lock status
│   │       └── "Send request" button
│   └── Empty state
│
├── _pending_invites.html.erb
│   ├── Invite list
│   │   └── Per-invite row
│   │       ├── Group name
│   │       ├── From/To (depends on direction)
│   │       ├── Status badge
│   │       └── Accept/Decline buttons
│   └── Empty state
│
└── _warning_dialogs.html.erb
    ├── Last member leaving warning
    │   ├── Project title(s) that will be orphaned
    │   └── Confirm/Cancel buttons
    └── Group deletion warning
        ├── What data is affected
        └── Confirm/Cancel buttons
```

---

## 9. Testing Pyramid

```
                    /\
                   /  \
                  /SYSTEM\        End-to-end workflows
                 /        \       - Full join → confirm → leave
                /──────────\      - Leader succession
               /  CONTROLLER\     - Invite/request flows
              /    TESTS    \     - Error handling
             /────────────────\
            /  UNIT TESTS     \   Business logic
           /    (Models &     \  - can_confirm? with lock
          /     Logic)        \   - Leader succession
         /──────────────────────\ - Member limits
        / ────────────────────── \ - Dissolution
       /_________________________\

MUST WRITE TESTS FIRST:
1. Unit test: confirm! with lock
2. Unit test: leader succession (earliest member)
3. Unit test: group dissolution (last member leaves)
4. Unit test: conflict clearing (join removes pending)
5. Controller test: student join/leave
6. Controller test: student create group
7. Controller test: authorization checks
8. Integration test: full workflows

DO NOT implement without tests first!
```

---

## 10. Error Scenarios & Handling

```
Join Fails When:
├─ Student already in a group
│  └─ Error: "You're already in a group"
├─ Group is at max capacity
│  └─ Error: "Group is full"
├─ Group is locked
│  └─ Error: "Group is locked. Send a join request instead"
├─ Grouping window is closed
│  └─ Error: "Grouping window is closed"
└─ Student not enrolled in course
   └─ Error: "You're not enrolled in this course"

Confirm Fails When:
├─ Group size not within min/max (default mode)
│  └─ Error: "Group needs X-Y members"
├─ Group size not in legal distribution (fixed mode)
│  └─ Error: "This group size is not legal for current enrollment"
├─ Race condition: member count changed during confirmation
│  └─ Return false silently, don't update
└─ Group already confirmed
   └─ Error: "Group is already confirmed"

Leave Fails When:
├─ User not a member
│  └─ Error: "You're not in this group"
├─ Grouping window closed AND group confirmed
│  └─ Error: "Confirmed groups cannot be changed outside window"
└─ User not in course
   └─ Error: "You're not enrolled in this course"

Leader Succession Fails When:
├─ No members remain
│  └─ Result: Group is dissolved
└─ Multiple members (picks earliest by created_at)
   └─ Result: Successor promoted, others notified
```

---

This comprehensive architecture guide provides the implementation agent with a complete understanding of the system before coding begins.