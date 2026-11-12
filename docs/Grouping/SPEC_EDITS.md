# Grouping spec edits

One entry per item in the master plan's section 7. "Replace" quotes the stale
rule as described in the plan; the spec itself is an external document, so where
the plan does not record the old wording the entry says so instead of guessing.
"With" is the wording to paste in.

## D1: vocabulary

**Replace:** the spec's 1.x/3.0 wording that calls the Prevent leftover setting
"Auto-Confirmability", the ordinary setting "Default mode", and not-confirmed
groups "draft". Remove stale 1.x/3.0 passages outside the overview tab. (The
exact old passages are not recorded in the plan; old wording unknown, owner to
check.)

**With:** use the user-flow vocabulary throughout. The setting is **Prevent
leftover students**. Group status is **Not confirmed** or **Confirmed**.
Returning a confirmed group to not confirmed is **Reopen**. "Auto-Confirmability",
"Default mode" and "draft" are retired. Add **Tmp group** (a not-confirmed group
holding a Tmp number) and **group number** (the Tmp###/G### display name) to the
glossary.

## D2: the prevent-leftover rule is a feasibility check

**Replace:** "Prevent leftover students uses a strict quota model. For 10
students with a minimum of 2 and a maximum of 5, the legal distribution is two
groups of 5 (5+5); only that even split can be confirmed." (This is the stale
rule as described in the plan; exact spec wording unknown, owner to check.)

**With:** Prevent leftover students uses a feasibility check. A group size in
the minimum..maximum range is confirmable when the students still unconfirmed
after that group can themselves be split into groups within the range. For 10
students with a minimum of 2 and a maximum of 5, groups of 2, 3, 4 and 5 are all
confirmable (they leave 8, 7, 6 or 5 students, all splittable), not only 5+5.
The maximum group size still caps a confirmed group: a size above the maximum is
never confirmable, and confirming reads the unconfirmed count under the course
lock.

The **Distribution preview** on course settings still shows the even-split
breakdown from the calculator (for 10 students, minimum 2, maximum 5 it shows 2
groups of 5). That preview is illustrative only: confirmation follows the
feasibility rule, so the preview's split is not the only legal confirmation.

## D3: No limit is the default

**Replace:** "Group minimum and maximum are required whenever group formation is
enabled, and a course cannot run without limits." (Old wording unknown, owner to
check.)

**With:** No limit is the default. A blank minimum means 1; a blank maximum
means unlimited. A course may enable student self-grouping without setting
either limit. **Prevent leftover students** is the only setting that requires
both minimum and maximum, because it needs a legal distribution.

## D6: coordinators confirm and reopen

**Replace:** "Coordinators cannot change a group's status; there is no Confirm or
Reopen for coordinators." (The plan records this as stale; exact spec wording
unknown, owner to check.)

**With:** Coordinators can **Confirm** and **Reopen** groups. Coordinator Confirm
works with formation closed and confirms undersized or oversized groups.
Coordinator Reopen works with formation closed and is blocked when the group has
a proposal. Lecturers and students cannot use these actions. A coordinator add,
remove or delete never changes status. Not-confirmed groups left behind after
formation closes are flagged to the coordinator.

## D7: self-leave, leader kick and staff removal

**Replace:** "A member can be removed from a confirmed group, and a member
self-leaving a confirmed group reopens it." (The plan records both lines as
stale; exact spec wording unknown, owner to check.)

**With:** A student can leave only while the group is not confirmed and formation
is open. Nobody self-leaves a confirmed group, the leader included. A leader can
kick a member from a confirmed group when formation is open, the group has no
project and is not imported; that kick reopens the group. A coordinator can
remove a member from any group without changing its status and without reopening
it. A leader who wants out of a confirmed group must reopen it first, and cannot
do so while it has a project.

## D13: mode switches keep not-confirmed groups

**Replace:** "Turning off student self-grouping or Prevent leftover students
deletes every not-confirmed group." (Old wording unknown, owner to check.)

**With:** Turning either setting off keeps not-confirmed groups. They keep their
Tmp names, remain visible where the Groups tab and the coordinator banner show
them, and can still be confirmed later by a coordinator.

## D18: no Move a member

**Replace:** "Coordinators can move a member from one group to another."

**With:** There is no **Move a member** action. To move a student, a coordinator
removes them from the current group and adds them to the other group.

## D19: Prevent leftover students can be turned back on

**Replace:** "Prevent leftover students can only be turned on once."

**With:** Prevent leftover students can be switched off and on again. Switching
it off keeps existing groups; switching it on re-applies the minimum and maximum
limits to future confirmations.

## D26/D28: no promote-leader, no approval toggle

**Replace:** "Members can promote another member to leader, and a group has an
approval toggle that controls whether joining needs approval." (Old wording
unknown, owner to check.)

**With:** There is no promote-leader action. Leadership changes only by
succession: when the leader leaves, is kicked or is removed, the earliest
remaining member becomes leader. Staff choose the leader at group creation; an
imported group's leader is its first CSV member. There is no approval toggle.
Not-confirmed groups take direct joins; confirmed groups take requests,
invitations and invite links, and accepting one reopens the group.

## D27: Tmp and G numbers

**Replace:** "Not-confirmed groups are numbered from a per-course counter that
never repeats a number, and confirmed groups take a G number from the same
counter." (Old wording unknown, owner to check.)

**With:** Not-confirmed groups are named **Tmp###** and confirmed groups
**G###**. Each takes the lowest free number in its own series for the course, at
the moment the status changes, under the course lock. Confirming releases the
Tmp name and gives the lowest free G number; reopening releases the G name and
gives a new Tmp number. Imported groups keep their CSV name and take no number.
Names are display only: URLs, invitations, requests and invite links use the
group id.

## D29: reopening a confirmed group for a new member

**Replace:** the message members receive when a confirmed group takes a new
member (old wording unknown, owner to check).

**With:** Accepting a request, invitation or invite link into a confirmed group
reopens the group and sends every remaining member "Group reopened because X
joined.", where X is the student who joined. The leader who accepted sees the
same line as the confirmation. A group with a project accepts no new members.
Students cannot reopen an imported group.

## D33: invite links are deleted on confirm, reopen and project creation

**Replace:** wording that leaves an invite link valid after the group is
confirmed, reopened or has a project created on it (old wording unknown, owner
to check).

**With:** Confirming a group (student or coordinator), reopening it (student,
coordinator, or the reopen caused by accepting a request, invitation or invite
link), and creating a project on it delete every invite link for that group. On
a not-confirmed group a link stays multi-use until it expires after 24 hours, is
replaced by **Generate new link**, or is disabled with **Disable link**.

## D34: a leader can kick from a confirmed group

**Replace:** text saying a leader cannot remove a member from a confirmed group,
and the "Remove a member" wording that implies removal never reopens (old
wording unknown, owner to check).

**With:** A leader can kick a member from a confirmed group while formation is
open, the group has no project and is not imported. The kick reopens the group:
it takes a new Tmp number, clears pending requests and invite links, and notifies
every remaining member "Group reopened because X was removed.". Students still
cannot self-leave a confirmed group. A coordinator removal does not reopen the
group and does not change its status.

## D36: formation open and closed

**Replace:** wording that calls the period a "grouping window", has a stored
open/closed flag or a separate "open from" date, or treats "grouping enabled"
and "formation open" as different states (old wording unknown, owner to check).

**With:** The course has one **formation** state, derived from **Student
self-grouping** and the optional **End group formation** date. Formation is open
while self-grouping is enabled and the current time is at or before the end date;
no end date means open. Formation is closed otherwise. Enabling self-grouping
opens formation immediately; there is no scheduled-open state. Every formation
action checks this one state; there is no separate stored open flag.
