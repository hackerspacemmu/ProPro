# Grouping backend - raw search output

**Purpose:** the raw, unedited search output behind `docs/grouping_backend_audit.md`.
This file contains **no analysis** - every analytical claim lives in the audit.
Nothing here was filtered, summarised or re-ordered.

**Date of capture:** 2026-10-21 22:14:22 +0800
**HEAD commit date:** 2026-10-21 16:29:08 +0800
**Current branch:** `feat/student-grouping-crud`
**HEAD sha:** `8a35e745159b8af0ce07f36de2b22defa16d8ca2`
**Base branch:** `main` (= `origin/main`) at `98ca0a9b52d4551bc85265535b7e22acde01717a`
(this is also the merge base with HEAD - the branch is 89 commits ahead of main and 0 behind).
**Working tree:** no tracked file is modified; the only untracked files are the audit
documents in `docs/`.

## Table of contents

| Section | Lines |
|---|---|
| A.1.1 - `grep -rnE "ProjectGroup|ProjectGroupMember|project_group" app lib db/seeds test` | 463 |
| A.1.2 - `grep -rnE "confirmed|locked|leader_id|course_group_sequence" app lib` | 243 |
| A.1.3 - `grep -rnE "enrolments?\.(destroy|delete)|Enrolment.*(destroy|delete)|dependent:" app` | 37 |
| A.1.4 - `grep -rnE "group_min|group_max|student_list_finalised|grouping_open|grouping_opens_at|grouping_closes_at|grouping_enabled" app lib` | 130 |
| A.1.5 - `grep -rnE "transaction do|with_lock|\.lock\b|lock!" app` | 35 |
| A.1.6 - `grep -rnE "force_confirm|import|coursecode" app config/routes.rb` | 184 |
| A.1.7 - `grep -rnE "\.call\b|def call|def execute|\.execute\b|def self\." app/services app/controllers` | 32 |
| A.1.8 - `grep -rnE "TODO|FIXME|HACK|XXX" app test` | 14 |
| A.2 - branch commits touching grouping | 90 |
| A.3 - schema and migration state | 28 |

---

# A. Raw search output

Every block below is the exact stdout of the command in its heading, captured on the
machine that produced this file, with nothing removed. The `### END` marker at the end
of each block is part of the capture.

### A.1.1  `grep -rnE "ProjectGroup|ProjectGroupMember|project_group" app lib db/seeds test`

Every reference to the grouping models/tables across app, lib, seeds and tests.

~~~~
### CMD: grep -rnE "ProjectGroup|ProjectGroupMember|project_group" app lib db/seeds test

app/models/project_group.rb:1:class ProjectGroup < ApplicationRecord
app/models/project_group.rb:2:  has_many :project_group_members, dependent: :destroy
app/models/project_group.rb:5:  has_many :users, through: :project_group_members
app/models/project_group.rb:7:  has_many :project_group_invites, dependent: :destroy
app/models/project_group.rb:8:  has_many :project_group_invite_links, dependent: :destroy
app/models/project_group.rb:15:    project_group_invites.pending
app/models/project_group.rb:30:      .confirmable_size?(project_group_members.count)
app/models/ownership.rb:3:  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
app/models/course.rb:13:  has_many :project_groups, dependent: :destroy
app/models/course.rb:18:  has_many :project_group_members, through: :project_groups
app/models/course.rb:104:    confirmed_member_count = ProjectGroupMember
app/models/course.rb:105:                             .joins(:project_group)
app/models/course.rb:106:                             .where(project_groups: { course_id: id, confirmed: true })
app/models/course.rb:174:      existing_ids = projects.where(owner_type: 'ProjectGroup').pluck(:owner_id)
app/models/course.rb:178:        projects.find_by(owner_type: 'ProjectGroup', owner_id: g.id)&.current_status == status
app/models/course.rb:192:    project_groups.where(confirmed: false).find_each do |group|
app/models/project_group_invite.rb:1:class ProjectGroupInvite < ApplicationRecord
app/models/project_group_invite.rb:2:  belongs_to :project_group
app/models/project_group_invite.rb:12:              scope: %i[project_group_id kind],
app/models/project_group_invite.rb:21:              scope: %i[project_group_id kind],
app/models/project_group_invite.rb:30:  scope :pending_for_group, ->(group)   { where(project_group: group, status: :pending) }
app/models/project_group_invite.rb:31:  scope :for_course,        ->(course)  { joins(:project_group).where(project_groups: { course_id: course.id }) }
app/models/user.rb:19:  has_many :project_group_members, dependent: :destroy
app/models/user.rb:20:  has_many :project_groups, through: :project_group_members
app/models/user.rb:26:  has_many :group_projects, through: :project_groups, source: :project
app/models/project_group_member.rb:1:class ProjectGroupMember < ApplicationRecord
app/models/project_group_member.rb:3:  belongs_to :project_group
app/models/project.rb:2:  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
app/models/project.rb:3:  default_scope { where(ownership_type: %i[student project_group]) }
app/models/project.rb:32:  validate :project_group_must_be_confirmed, if: -> { owner_type == 'ProjectGroup' }
app/models/project.rb:41:    if ownership.owner.is_a?(ProjectGroup)
app/models/project.rb:88:  # The owning ProjectGroup, when this project belongs to one.
app/models/project.rb:90:    owner if owner_type == 'ProjectGroup'
app/models/project.rb:99:  def project_group_must_be_confirmed
app/models/project_group_invite_link.rb:1:class ProjectGroupInviteLink < ApplicationRecord
app/models/project_group_invite_link.rb:2:  belongs_to :project_group
app/models/topic.rb:4:  enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
app/models/topic.rb:36:    if ownership.owner.is_a?(ProjectGroup)
app/mailers/general_mailer.rb:20:      emails = @project.owner.project_group_members.joins(:user).pluck('user.email_address')
app/mailers/general_mailer.rb:66:    @group = @invite.project_group
app/mailers/general_mailer.rb:78:    @group = @invite.project_group
app/mailers/general_mailer.rb:85:    @group = @invite.project_group
app/mailers/general_mailer.rb:92:    @group = @invite.project_group
app/mailers/general_mailer.rb:99:    @group = @invite.project_group
app/mailers/general_mailer.rb:106:    @group = @invite.project_group
app/policies/project_policy.rb:18:      group_owned = scope.where(ownership_type: :project_group)
app/policies/project_policy.rb:25:      user_groups = user.project_groups.where(course: course)
app/policies/project_policy.rb:81:    record.owner == user || (record.owner.is_a?(ProjectGroup) && record.owner.users.include?(user))
app/policies/project_policy.rb:117:    user_groups = user.project_groups.where(course: course)
app/policies/project_group_invite_link_policy.rb:1:class ProjectGroupInviteLinkPolicy < ApplicationPolicy
app/policies/project_group_invite_link_policy.rb:9:    record.project_group.course.enrolments.find_by(user:)
app/policies/course_policy.rb:71:          .owned_by_user_or_groups(user, user.project_groups.where(course: record))
app/policies/course_policy.rb:105:    record.projects.owned_by_user_or_groups(user, user.project_groups.where(course: record)).exists?
app/policies/project_group_member_policy.rb:1:class ProjectGroupMemberPolicy < ApplicationPolicy
app/policies/project_group_member_policy.rb:4:    return true if record.project_group.leader?(user)
app/policies/project_group_member_policy.rb:6:    CoursePolicy.new(user, record.project_group.course).manage_groups?
app/policies/project_group_member_policy.rb:12:    @enrolment ||= record.project_group.course.enrolments.find_by(user:)
app/policies/project_group_policy.rb:1:class ProjectGroupPolicy < ApplicationPolicy
app/policies/project_group_policy.rb:78:    ProjectGroupMember.joins(:project_group)
app/policies/project_group_policy.rb:80:                               project_groups: { course_id: record.course_id })
app/policies/project_group_invite_policy.rb:1:class ProjectGroupInvitePolicy < ApplicationPolicy
app/policies/project_group_invite_policy.rb:14:      record.project_group.leader_id == user.id
app/policies/comment_policy.rb:29:      project.owner_type == 'ProjectGroup' ? project.owner.users : [project.owner]
app/helpers/courses_helper.rb:6:    projects_by_owner[['ProjectGroup', group.id]]
app/controllers/project_group_invites_controller.rb:1:class ProjectGroupInvitesController < ApplicationController
app/controllers/project_group_invites_controller.rb:12:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_group_invites_controller.rb:14:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_group_invites_controller.rb:25:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_group_invites_controller.rb:27:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_group_invites_controller.rb:37:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_group_invites_controller.rb:39:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_group_invites_controller.rb:49:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_group_invites_controller.rb:51:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_group_invites_controller.rb:62:    @group = @course.project_groups.find(params[:project_group_id])
app/controllers/project_group_invites_controller.rb:66:    @invite = @group.project_group_invites.find(params[:id])
app/controllers/lecturers_controller.rb:35:                 group = current_user.project_groups.find_by(course: @course)
app/controllers/people_controller.rb:21:    # One map lookup, computed once: user_id => project_group for the Students
app/controllers/people_controller.rb:26:      @course.project_groups.includes(project_group_members: :user).find_each do |group|
app/controllers/people_controller.rb:27:        group.project_group_members.each { |member| @student_group_map[member.user_id] = group }
app/controllers/topics_controller.rb:56:                 group = current_user.project_groups.find_by(course: @course)
app/controllers/topics_controller.rb:62:    @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]
app/controllers/groups_controller.rb:21:    @group_list = @course.project_groups.includes(project_group_members: :user).to_a
app/controllers/project_group_members_controller.rb:1:class ProjectGroupMembersController < ApplicationController
app/controllers/project_group_members_controller.rb:4:  before_action :set_project_group_member, only: %i[destroy]
app/controllers/project_group_members_controller.rb:12:    @group = @course.project_groups.find(params[:project_group_id])
app/controllers/project_group_members_controller.rb:23:    redirect_to course_project_groups_path(@course), status: :see_other
app/controllers/project_group_members_controller.rb:27:    authorize @project_group_member
app/controllers/project_group_members_controller.rb:29:    removed_student = @project_group_member.user
app/controllers/project_group_members_controller.rb:30:    member_dom_id = dom_id(@project_group_member)
app/controllers/project_group_members_controller.rb:31:    group_dom_id = dom_id(@project_group_member.project_group)
app/controllers/project_group_members_controller.rb:34:      @project_group_member,
app/controllers/project_group_members_controller.rb:42:        partial: 'project_group_members/dissolve_warning_modal',
app/controllers/project_group_members_controller.rb:43:        locals: { member: @project_group_member, result: result }
app/controllers/project_group_members_controller.rb:57:                                partial: 'project_groups/ungrouped_student',
app/controllers/project_group_members_controller.rb:72:  def set_project_group_member
app/controllers/project_group_members_controller.rb:73:    @project_group_member = ProjectGroupMember.find(params[:id])
app/controllers/enrolments_controller.rb:15:      group_member = ProjectGroupMember.joins(:project_group)
app/controllers/enrolments_controller.rb:16:                                       .find_by(project_groups: { course_id: current_course.id },
app/controllers/concerns/participant_browsing.rb:41:      project = participant_project(group, 'ProjectGroup')
app/controllers/concerns/participant_browsing.rb:44:      member_match = group.project_group_members.any? do |member|
app/controllers/concerns/participant_browsing.rb:76:    project = participant_project(group, 'ProjectGroup')
app/controllers/concerns/participant_browsing.rb:116:    if (ids = supervised_owner_ids('ProjectGroup'))
app/controllers/courses_controller.rb:21:      @group = current_user.project_groups.find_by(course: @course)
app/controllers/courses_controller.rb:22:      @project = @course.projects.find_by(owner_type: 'ProjectGroup', owner_id: @group.id) if @group
app/controllers/courses_controller.rb:284:      @group = @course.project_groups.find(@participant_id)
app/controllers/courses_controller.rb:285:      @members = @group.project_group_members.includes(:user)
app/controllers/courses_controller.rb:299:    @group_list = @course.grouped? ? @course.project_groups.includes(project_group_members: :user).to_a : []
app/controllers/courses_controller.rb:449:      new_group = ProjectGroup.find_or_create_by!(group_name: group, course: parent_course)
app/controllers/courses_controller.rb:486:        ProjectGroupMember.where(user: new_user).pluck(:project_group_id)
app/controllers/courses_controller.rb:487:        new_group_member = ProjectGroupMember.joins(:project_group).find_by(user: new_user, project_groups: { course: parent_course })
app/controllers/courses_controller.rb:490:          new_group_member.update!(project_group: new_group)
app/controllers/courses_controller.rb:492:          ProjectGroupMember.create!(
app/controllers/courses_controller.rb:494:            project_group: new_group
app/controllers/courses_controller.rb:620:    project = @course.projects.find_by(owner_type: 'ProjectGroup', owner_id: group.id)
app/controllers/courses_controller.rb:628:    group.project_group_members.each do |member|
app/controllers/courses_controller.rb:742:                        .find_by(owner_type: 'ProjectGroup', owner_id: group.id)
app/controllers/courses_controller.rb:748:                        .find_by(owner_type: 'ProjectGroup', owner_id: group.id)
app/controllers/courses_controller.rb:754:                        .find_by(owner_type: 'ProjectGroup', owner_id: group.id)
app/controllers/courses_controller.rb:767:  # page: ProjectGroupsController#index authorizes with CoursePolicy#grouping?,
app/controllers/project_group_invite_links_controller.rb:1:class ProjectGroupInviteLinksController < ApplicationController
app/controllers/project_group_invite_links_controller.rb:17:      redirect_to course_project_groups_path(result.group.course), notice: result.message
app/controllers/project_group_invite_links_controller.rb:19:      redirect_to project_group_invite_link_path(@invite_link.token), alert: result.message
app/controllers/project_group_invite_links_controller.rb:26:    @invite_link = ProjectGroupInviteLink.find_by(token: params[:token])
app/controllers/project_groups_controller.rb:1:class ProjectGroupsController < ApplicationController
app/controllers/project_groups_controller.rb:8:    @my_group = @course.project_groups
app/controllers/project_groups_controller.rb:9:                       .includes(project_group_members: :user)
app/controllers/project_groups_controller.rb:10:                       .joins(:project_group_members)
app/controllers/project_groups_controller.rb:11:                       .find_by(project_group_members: { user_id: current_user.id })
app/controllers/project_groups_controller.rb:15:    @my_group_invite_token = @my_group&.project_group_invite_links&.find_by(sender: current_user)&.token
app/controllers/project_groups_controller.rb:16:    @incoming_join_requests = @my_group.present? ? @my_group.project_group_invites.pending_for_group(@my_group).where(kind: :direct_request) : []
app/controllers/project_groups_controller.rb:17:    @incoming_direct_invites = ProjectGroupInvite.for_course(@course).sent_to(current_user).pending.where(kind: :direct_invite)
app/controllers/project_groups_controller.rb:18:    @my_requested_group_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_request).pluck(:project_group_id)
app/controllers/project_groups_controller.rb:19:    @my_invited_student_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_invite).pluck(:recipient_id)
app/controllers/project_groups_controller.rb:21:    @groups = @course.project_groups
app/controllers/project_groups_controller.rb:22:                     .includes(project_group_members: :user)
app/controllers/project_groups_controller.rb:25:    grouped_student_ids  = ProjectGroupMember.joins(:project_group)
app/controllers/project_groups_controller.rb:26:                                             .where(project_groups: { course_id: @course.id })
app/controllers/project_groups_controller.rb:33:    @group = @course.project_groups.build
app/controllers/project_groups_controller.rb:41:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_groups_controller.rb:43:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_groups_controller.rb:55:      redirect_to course_project_groups_path(@course), alert: e.message
app/controllers/project_groups_controller.rb:59:    redirect_to course_project_groups_path(@course), notice: 'Group dissolved.'
app/controllers/project_groups_controller.rb:68:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_groups_controller.rb:70:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_groups_controller.rb:80:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_groups_controller.rb:82:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_groups_controller.rb:92:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_groups_controller.rb:94:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_groups_controller.rb:102:      redirect_to course_project_groups_path(@course), alert: 'Assign a leader before locking this group.'
app/controllers/project_groups_controller.rb:109:      redirect_to course_project_groups_path(@course), alert: e.message
app/controllers/project_groups_controller.rb:112:    redirect_to course_project_groups_path(@course), notice: 'Group is now locked.'
app/controllers/project_groups_controller.rb:120:      redirect_to course_project_groups_path(@course), alert: e.message
app/controllers/project_groups_controller.rb:123:    redirect_to course_project_groups_path(@course), notice: 'Group is now open to join.'
app/controllers/project_groups_controller.rb:128:    target_member = @group.project_group_members.find_by!(user_id: params[:user_id])
app/controllers/project_groups_controller.rb:132:      redirect_to course_project_groups_path(@course), alert: e.message
app/controllers/project_groups_controller.rb:135:    redirect_to course_project_groups_path(@course), notice: "#{target_member.user.name} is now the group leader."
app/controllers/project_groups_controller.rb:167:      redirect_to course_project_groups_path(@course), notice: 'Settings updated.'
app/controllers/project_groups_controller.rb:169:      redirect_to course_project_groups_path(@course), alert: e.message
app/controllers/project_groups_controller.rb:179:      redirect_to course_project_groups_path(@course), notice: result.message
app/controllers/project_groups_controller.rb:181:      redirect_to course_project_groups_path(@course), alert: result.message
app/controllers/project_groups_controller.rb:192:    @group = @course.project_groups.find(params[:id])
app/controllers/projects_controller.rb:14:    @members = if @owner.is_a?(ProjectGroup)
app/controllers/projects_controller.rb:198:          group = current_user.project_groups.find_by(course: @course)
app/services/group_member_remover.rb:7:    @group = member.project_group
app/services/group_member_remover.rb:15:      remaining_count = @group.project_group_members.count - 1
app/services/group_member_remover.rb:61:    successor = @group.project_group_members.order(:created_at).first
app/services/group_member_remover.rb:66:    @group.project_group_invites.destroy_all
app/services/group_member_remover.rb:67:    @group.project_group_invite_links.destroy_all
app/services/group_direct_requester.rb:2:# Creates a pending ProjectGroupInvite (kind: direct_request)
app/services/group_direct_requester.rb:14:    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
app/services/group_direct_requester.rb:19:    invite = ProjectGroupInvite.create!(
app/services/group_direct_requester.rb:20:      project_group: @group,
app/services/group_joiner.rb:13:      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
app/services/group_joiner.rb:16:      return blocked(:group_full) if @group.project_group_members.count >= course.group_max.to_i
app/services/group_joiner.rb:18:      ProjectGroupMember.create!(user: @current_user, project_group: @group)
app/services/group_joiner.rb:28:    ProjectGroupInvite
app/services/group_joiner.rb:30:      .where(project_group_id: @group.course.project_groups.select(:id))
app/services/group_invite_link_generator.rb:17:      @group.project_group_invite_links.find_by(sender: @current_user)&.destroy!
app/services/group_invite_link_generator.rb:19:      link = @group.project_group_invite_links.create!(
app/services/queries/supervisor_capacity_calculator.rb:75:      total = @course.grouped? ? @course.project_groups.count : @course.projects.where(owner_type: 'User').count
app/services/group_creator.rb:27:    @course.project_group_members.exists?(user_id: @leader.id)
app/services/group_creator.rb:31:    next_seq = @course.project_groups.maximum(:course_group_sequence).to_i + 1
app/services/group_creator.rb:32:    group = @course.project_groups.create!(
app/services/group_creator.rb:37:    ProjectGroupMember.create!(user: @leader, project_group: group)
app/services/group_member_adder.rb:13:    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @user.id)
app/services/group_member_adder.rb:17:      ProjectGroupMember.create!(user: @user, project_group: @group)
app/services/group_member_adder.rb:25:    course.group_max.present? && @group.project_group_members.count >= course.group_max
app/services/group_direct_inviter.rb:2:# Creates a pending ProjectGroupInvite (kind: direct_invite)
app/services/group_direct_inviter.rb:19:    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @recipient.id)
app/services/group_direct_inviter.rb:21:    invite = ProjectGroupInvite.create!(
app/services/group_direct_inviter.rb:22:      project_group: @group,
app/services/group_direct_inviter.rb:39:    course.group_max.present? && @group.project_group_members.count >= course.group_max
app/services/group_invite_link_redeemer.rb:4:# ProjectGroupInviteLinkPolicy#redeem? (identity concern, not service).
app/services/group_invite_link_redeemer.rb:14:    group = @invite_link.project_group
app/services/group_invite_link_redeemer.rb:22:      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
app/services/group_invite_link_redeemer.rb:24:      ProjectGroupMember.create!(user: @current_user, project_group: group)
app/services/group_invite_link_redeemer.rb:34:    course.group_max.present? && group.project_group_members.count >= course.group_max
app/services/group_invite_link_redeemer.rb:38:    ProjectGroupInvite
app/services/group_invite_link_redeemer.rb:41:      .where(project_group_id: group.course.project_groups.select(:id))
app/services/group_invite_responder.rb:1:# Responds to a pending ProjectGroupInvite — either a direct_request
app/services/group_invite_responder.rb:11:    @group = invite.project_group
app/services/group_invite_responder.rb:23:      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: joining_user.id)
app/services/group_invite_responder.rb:27:      ProjectGroupMember.create!(user: joining_user, project_group: @group)
app/services/group_invite_responder.rb:49:    course.group_max.present? && @group.project_group_members.count >= course.group_max
app/services/group_invite_responder.rb:58:    ProjectGroupInvite
app/services/group_invite_responder.rb:61:      .where(project_group_id: @group.course.project_groups.select(:id))
app/views/project_group_members/_dissolve_warning_modal.html.erb:62:            course_project_group_member_path(member.project_group.course, member.project_group, member),
app/views/courses/_group_row.html.erb:24:      <% any_pending = group.project_group_members.any? { |m| !m.user.has_registered } %>
app/views/courses/_group_row.html.erb:26:        <% member_count = [group.project_group_members.count, 3].min %>
app/views/courses/_group_row.html.erb:27:        <% group.project_group_members.first(3).each_with_index do |member, idx| %>
app/views/courses/_group_row.html.erb:36:      <span class="text-sm text-gray-500 truncate"><%= pluralize(group.project_group_members.count, "member") %></span>
app/views/courses/_group_row.html.erb:66:        <% group.project_group_members.each do |member| %>
app/views/courses/_groups_table.html.erb:29:          <% group_project = projects_by_owner[['ProjectGroup', group.id]]
app/views/courses/_overview_tab.html.erb:33:            cta_path: course_project_groups_path(@course) %>  <%# E2 %>
app/views/general_mailer/group_direct_invite_declined.html.erb:29:                                            Visit <%= course_project_groups_url(@group.course) %> to manage your group.
app/views/general_mailer/group_direct_invite_accepted.text.erb:3:Visit <%= course_project_groups_url(@group.course) %> to view your group.
app/views/general_mailer/group_direct_request_declined.text.erb:3:You can browse other groups at <%= course_project_groups_url(@group.course) %>.
app/views/general_mailer/group_direct_invite_notification.html.erb:29:                                            Visit <%= course_project_groups_url(@group.course) %> to accept or decline.
app/views/general_mailer/group_direct_invite_accepted.html.erb:29:                                            Visit <%= course_project_groups_url(@group.course) %> to view your group.
app/views/general_mailer/group_direct_invite_declined.text.erb:3:Visit <%= course_project_groups_url(@group.course) %> to manage your group.
app/views/general_mailer/group_direct_request_notification.text.erb:3:Visit <%= course_project_groups_url(@group.course) %> to accept or decline.
app/views/general_mailer/group_direct_request_accepted.text.erb:3:Visit <%= course_project_groups_url(@group.course) %> to view your group.
app/views/general_mailer/group_direct_request_notification.html.erb:29:                                            Visit <%= course_project_groups_url(@group.course) %> to accept or decline.
app/views/general_mailer/group_direct_invite_notification.text.erb:3:Visit <%= course_project_groups_url(@group.course) %> to accept or decline.
app/views/project_group_invite_links/show.html.erb:3:  <% group = @invite_link.project_group %>
app/views/project_group_invite_links/show.html.erb:4:  <% member_count = group.project_group_members.count %>
app/views/project_group_invite_links/show.html.erb:21:            redeem_project_group_invite_link_path(@invite_link.token),
app/views/project_groups/_my_group_panel.html.erb:54:                course_project_groups_path(@course),
app/views/project_groups/_my_group_panel.html.erb:74:                <%= invite.project_group.group_name.first(2).upcase %>
app/views/project_groups/_my_group_panel.html.erb:77:                <b class="font-medium"><%= invite.project_group.group_name %></b> invited you to join their group
app/views/project_groups/_my_group_panel.html.erb:82:                    accept_course_project_group_project_group_invite_path(@course, invite.project_group, invite),
app/views/project_groups/_my_group_panel.html.erb:86:                    decline_course_project_group_project_group_invite_path(@course, invite.project_group, invite),
app/views/project_groups/_my_group_panel.html.erb:101:      member_count = @my_group.project_group_members.size
app/views/project_groups/_my_group_panel.html.erb:145:                course_project_group_path(@course, @my_group),
app/views/project_groups/_my_group_panel.html.erb:163:                      confirm_course_project_group_path(@course, @my_group),
app/views/project_groups/_my_group_panel.html.erb:172:                      revert_course_project_group_path(@course, @my_group),
app/views/project_groups/_my_group_panel.html.erb:181:                        unlock_course_project_group_path(@course, @my_group),
app/views/project_groups/_my_group_panel.html.erb:186:                        lock_course_project_group_path(@course, @my_group),
app/views/project_groups/_my_group_panel.html.erb:194:                      generate_invite_link_course_project_group_path(@course, @my_group),
app/views/project_groups/_my_group_panel.html.erb:202:                          value="<%= project_group_invite_link_url(@my_group_invite_token) %>"
app/views/project_groups/_my_group_panel.html.erb:216:            my_membership = @my_group.project_group_members.find { |m| m.user_id == current_user.id }
app/views/project_groups/_my_group_panel.html.erb:221:                    course_project_group_member_path(@course, @my_group, my_membership),
app/views/project_groups/_my_group_panel.html.erb:237:            <% @my_group.project_group_members.each do |membership| %>
app/views/project_groups/_my_group_panel.html.erb:264:                            promote_leader_course_project_group_path(@course, @my_group),
app/views/project_groups/_my_group_panel.html.erb:270:                            course_project_group_member_path(@course, @my_group, membership),
app/views/project_groups/_my_group_panel.html.erb:308:                            accept_course_project_group_project_group_invite_path(@course, @my_group, join_request),
app/views/project_groups/_my_group_panel.html.erb:312:                            decline_course_project_group_project_group_invite_path(@course, @my_group, join_request),
app/views/project_groups/_my_group_panel.html.erb:337:          <%= form_with url: direct_invite_course_project_group_project_group_invites_path(@course, @my_group), method: :post do %>
app/views/project_groups/_group_card.html.erb:8:<% member_count = group.project_group_members.size %>
app/views/project_groups/_group_card.html.erb:34:  data-search-text="<%= [group.group_name, *group.project_group_members.map { |m| m.user.name }].compact.join(" ").downcase %>"
app/views/project_groups/_group_card.html.erb:72:                  course_project_group_project_group_invites_path(course, group),
app/views/project_groups/_group_card.html.erb:78:                join_course_project_group_path(course, group),
app/views/project_groups/_group_card.html.erb:87:              confirm_course_project_group_path(course, group),
app/views/project_groups/_group_card.html.erb:93:              revert_course_project_group_path(course, group),
app/views/project_groups/_group_card.html.erb:104:        <% group.project_group_members.first(4).each_with_index do |membership, i| %>
app/views/project_groups/_group_card.html.erb:123:      <% group.project_group_members.each do |membership| %>
app/views/project_groups/_group_card.html.erb:148:              <%= button_to course_project_group_member_path(course, group, membership),
app/views/project_groups/_group_card.html.erb:193:            <%= form_with url: course_project_group_members_path(course, group), method: :post do %>
app/views/project_groups/_ungrouped_student.html.erb:6:  ProjectGroupMembersController#destroy.
app/views/project_groups/index.html.erb:3:<% breadcrumb :project_groups, @course %>
app/views/project_groups/index.html.erb:152:              <%= form_with url: course_project_groups_path(@course), method: :post, data: { turbo_stream: true } do %>
app/views/topics/_topic_overview.html.erb:68:    <% if topic.owner.is_a?(ProjectGroup) %>
app/views/projects/_project_overview.html.erb:33:    <% if project.owner.is_a?(ProjectGroup) %>
grep: db/seeds: No such file or directory
test/models/course_grouping_settings_test.rb:112:  test 'disable_grouping! destroys draft project_groups' do
test/models/course_grouping_settings_test.rb:114:    draft = create(:project_group, course: course, confirmed: false)
test/models/course_grouping_settings_test.rb:116:    assert_not ProjectGroup.exists?(draft.id)
test/models/course_grouping_settings_test.rb:119:  test 'disable_grouping! preserves confirmed project_groups' do
test/models/course_grouping_settings_test.rb:121:    confirmed = create(:project_group, course: course, confirmed: true)
test/models/course_grouping_settings_test.rb:123:    assert ProjectGroup.exists?(confirmed.id)
test/models/course_grouping_settings_test.rb:140:  test 'revert_to_default_mode! destroys draft project_groups' do
test/models/course_grouping_settings_test.rb:142:    draft = create(:project_group, course: course, confirmed: false)
test/models/course_grouping_settings_test.rb:144:    assert_not ProjectGroup.exists?(draft.id)
test/models/course_grouping_settings_test.rb:147:  test 'revert_to_default_mode! does not destroy confirmed project_groups' do
test/models/course_grouping_settings_test.rb:149:    confirmed = create(:project_group, course: course, confirmed: true)
test/models/course_grouping_settings_test.rb:151:    assert ProjectGroup.exists?(confirmed.id)
test/models/project_group_student_actions_test.rb:3:class ProjectGroupStudentActionsTest < ActiveSupport::TestCase
test/models/project_group_student_actions_test.rb:15:    @group = create(:project_group, course: @course, leader_id: @alice.id)
test/models/project_group_student_actions_test.rb:16:    create(:project_group_member, project_group: @group, user: @alice,
test/models/project_group_student_actions_test.rb:18:    create(:project_group_member, project_group: @group, user: @bob,
test/models/project_group_student_actions_test.rb:32:    solo = create(:project_group, course: @course, leader_id: @carol.id)
test/models/project_group_student_actions_test.rb:33:    create(:project_group_member, project_group: solo, user: @carol)
test/models/project_group_student_actions_test.rb:44:    pending  = create(:project_group_invite, project_group: @group, sender: @carol, status: :pending)
test/models/project_group_student_actions_test.rb:45:    declined = create(:project_group_invite, project_group: @group, sender: create(:user), status: :declined)
test/models/project_group_invite_test.rb:3:class ProjectGroupInviteTest < ActiveSupport::TestCase
test/models/project_group_invite_test.rb:7:    @group   = create(:project_group, course: @course)
test/models/project_group_invite_test.rb:9:    @invite  = build(:project_group_invite, project_group: @group, sender: @sender)
test/models/project_group_invite_test.rb:18:    duplicate = build(:project_group_invite, project_group: @group, sender: @sender, kind: :direct_request)
test/models/project_group_invite_test.rb:25:    new_request = build(:project_group_invite, project_group: @group, sender: @sender)
test/models/project_group_invite_test.rb:31:    other_group = create(:project_group, course: @course)
test/models/project_group_invite_test.rb:32:    other_request = build(:project_group_invite, project_group: other_group, sender: @sender)
test/models/project_group_invite_test.rb:38:    declined = create(:project_group_invite, project_group: @group,
test/models/project_group_invite_test.rb:41:    results = ProjectGroupInvite.pending_for_group(@group)
test/models/project_group_invite_test.rb:49:    other_group  = create(:project_group, course: other_course)
test/models/project_group_invite_test.rb:50:    other_invite = create(:project_group_invite, project_group: other_group, sender: create(:user))
test/models/project_group_invite_test.rb:52:    results = ProjectGroupInvite.for_course(@course)
test/system/courses/overview_tab_test.rb:83:    assert_current_path course_project_groups_path(@course)
test/system/courses/overview_tab_test.rb:98:    group = create(:project_group, course: @course, confirmed: true)
test/system/courses/overview_tab_test.rb:99:    create(:project_group_member, user: @student_user, project_group: group)
test/integration/grouping_settings_surface_test.rb:14:    get course_project_groups_path(@course)
test/integration/grouping_settings_surface_test.rb:34:    get course_project_groups_path(@course)
test/controllers/courses_controller_test.rb:186:    target_group = create(:project_group, course: course, confirmed: true, group_name: 'Target Group')
test/controllers/courses_controller_test.rb:187:    other_group = create(:project_group, course: course, confirmed: true, group_name: 'Other Group')
test/controllers/courses_controller_test.rb:188:    create(:project, course: course, owner: target_group, owner_type: 'ProjectGroup', supervisor_enrolment: target_enrolment)
test/controllers/courses_controller_test.rb:189:    create(:project, course: course, owner: other_group, owner_type: 'ProjectGroup', supervisor_enrolment: other_enrolment)
test/controllers/courses_controller_test.rb:204:    create(:project_group, course: course, confirmed: true, group_name: 'Visible Group')
test/controllers/courses_controller_test.rb:205:    create(:project_group, course: course, confirmed: false, group_name: 'Draft Group')
test/controllers/courses_controller_test.rb:226:    create(:project_group, course: course, confirmed: true, group_name: 'Visible Group')
test/controllers/courses_controller_test.rb:227:    create(:project_group, course: course, confirmed: false, group_name: 'Draft Group')
test/controllers/courses_controller_test.rb:241:    group = create(:project_group, course: course, confirmed: true, group_name: 'Link Me')
test/controllers/courses_controller_test.rb:254:    group = create(:project_group, course: course, confirmed: true, group_name: 'Student Group')
test/controllers/courses_controller_test.rb:255:    create(:project_group_member, user: @student_user, project_group: group)
test/controllers/courses_controller_test.rb:496:    group = create(:project_group, course: course, confirmed: true, group_name: 'Smoke Group')
test/controllers/courses_controller_test.rb:499:    create(:project_group_member, user: member, project_group: group)
test/controllers/courses_controller_test.rb:518:    group = create(:project_group, course: course, confirmed: true, group_name: 'Proposal Group')
test/controllers/courses_controller_test.rb:519:    project = create(:project, course: course, owner: group, owner_type: 'ProjectGroup',
test/controllers/courses_controller_test.rb:583:    create(:project_group, course: course, confirmed: true, group_name: 'Alpha Group')
test/controllers/courses_controller_test.rb:597:    create(:project_group, course: course, confirmed: true, group_name: 'Alpha Group')
test/controllers/courses_controller_test.rb:614:    create(:project_group, course: course, confirmed: true, group_name: 'Alpha Group')
test/services/group_confirmer_test.rb:6:    group  = create(:project_group, course: course, confirmed: false)
test/services/group_confirmer_test.rb:7:    create_list(:project_group_member, 3, project_group: group)
test/services/group_confirmer_test.rb:17:    group  = create(:project_group, course: course, confirmed: false)
test/services/group_confirmer_test.rb:18:    create_list(:project_group_member, 1, project_group: group)
test/services/group_confirmer_test.rb:30:    group = create(:project_group, course: course, confirmed: false)
test/services/group_confirmer_test.rb:31:    create_list(:project_group_member, 3, project_group: group)
test/services/group_confirmer_test.rb:41:    group = create(:project_group, course: course, confirmed: false)
test/services/group_confirmer_test.rb:42:    create_list(:project_group_member, 2, project_group: group)
test/services/group_confirmer_test.rb:52:    group  = create(:project_group, course: course, confirmed: false)
test/services/group_confirmer_test.rb:53:    create_list(:project_group_member, 3, project_group: group)
test/services/group_confirmer_test.rb:63:    group  = create(:project_group, course: course, confirmed: true)
test/services/group_confirmer_test.rb:64:    create_list(:project_group_member, 3, project_group: group)
test/services/group_direct_inviter_test.rb:10:    @group = create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_direct_inviter_test.rb:11:    create(:project_group_member, project_group: @group, user: @leader)
test/services/group_direct_inviter_test.rb:23:    invite = ProjectGroupInvite.find_by(project_group: @group, recipient: @recipient)
test/services/group_direct_inviter_test.rb:58:    create_list(:project_group_member, 1, project_group: @group) # bring size to 2 (min)
test/services/group_direct_inviter_test.rb:70:    create(:project_group_member, project_group: @group, user: filler)
test/services/group_direct_inviter_test.rb:73:    create(:project_group_member, project_group: @group, user: another)
test/services/group_direct_inviter_test.rb:83:    other_group = create(:project_group, course: @course, leader_id: @recipient.id)
test/services/group_direct_inviter_test.rb:84:    create(:project_group_member, project_group: other_group, user: @recipient)
test/services/group_direct_inviter_test.rb:99:    assert_equal 1, ProjectGroupInvite.where(project_group: @group, recipient: @recipient).count
test/services/group_direct_inviter_test.rb:126:    other_group = create(:project_group, course: @course, leader_id: other_leader.id)
test/services/group_direct_inviter_test.rb:127:    create(:project_group_member, project_group: other_group, user: other_leader)
test/services/group_direct_inviter_test.rb:134:    assert_equal 2, ProjectGroupInvite.where(recipient: @recipient, status: :pending).count
test/services/group_reverter_test.rb:6:    group  = create(:project_group, course: course, confirmed: true)
test/services/group_reverter_test.rb:16:    group  = create(:project_group, course: course, confirmed: true)
test/services/group_reverter_test.rb:26:    group  = create(:project_group, course: course, confirmed: false)
test/services/group_joiner_test.rb:14:    @group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_joiner_test.rb:15:    FactoryBot.create(:project_group_member, project_group: @group, user: @leader)
test/services/group_joiner_test.rb:22:    assert @group.project_group_members.exists?(user_id: @student.id)
test/services/group_joiner_test.rb:26:    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_joiner_test.rb:27:    invite = FactoryBot.create(:project_group_invite,
test/services/group_joiner_test.rb:28:                               project_group: other_group, sender: @student, recipient: @leader,
test/services/group_joiner_test.rb:39:    unrelated_invite = FactoryBot.create(:project_group_invite,
test/services/group_joiner_test.rb:40:                                         project_group: @group, sender: other_student, recipient: @leader,
test/services/group_joiner_test.rb:58:    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
test/services/group_joiner_test.rb:59:    FactoryBot.create(:project_group_member, project_group: other_group, user: @student)
test/services/group_joiner_test.rb:88:    FactoryBot.create(:project_group_member, project_group: @group, user: filler)
test/services/group_joiner_test.rb:91:    FactoryBot.create(:project_group_member, project_group: @group, user: another)
test/services/group_joiner_test.rb:103:    FactoryBot.create(:project_group_member, project_group: @group, user: filler)
test/services/group_joiner_test.rb:113:          GroupJoiner.new(ProjectGroup.find(@group.id), current_user: user).join!
test/services/group_invite_link_redeemer_test.rb:11:    @group = create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_invite_link_redeemer_test.rb:12:    create(:project_group_member, project_group: @group, user: @leader)
test/services/group_invite_link_redeemer_test.rb:16:    @link = create(:project_group_invite_link, project_group: @group, sender: @link_sender,
test/services/group_invite_link_redeemer_test.rb:28:    assert @group.project_group_members.exists?(user_id: @redeemer_user.id)
test/services/group_invite_link_redeemer_test.rb:50:    create(:project_group_member, project_group: @group)
test/services/group_invite_link_redeemer_test.rb:63:      create(:project_group_member, project_group: @group, user: filler)
test/services/group_invite_link_redeemer_test.rb:74:    other_group = create(:project_group, course: @course, leader_id: @redeemer_user.id)
test/services/group_invite_link_redeemer_test.rb:75:    create(:project_group_member, project_group: other_group, user: @redeemer_user)
test/services/group_invite_link_redeemer_test.rb:96:    other_group = create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_invite_link_redeemer_test.rb:97:    own_request = create(:project_group_invite, project_group: other_group, sender: @redeemer_user,
test/services/group_invite_link_redeemer_test.rb:102:    assert_not ProjectGroupInvite.exists?(own_request.id)
test/services/group_invite_link_redeemer_test.rb:106:    other_group = create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_invite_link_redeemer_test.rb:107:    incoming_invite = create(:project_group_invite, project_group: other_group, sender: @leader,
test/services/group_invite_link_redeemer_test.rb:112:    assert_not ProjectGroupInvite.exists?(incoming_invite.id)
test/services/group_invite_link_redeemer_test.rb:118:    unrelated = create(:project_group_invite, project_group: @group, sender: other_student,
test/services/group_invite_link_redeemer_test.rb:123:    assert ProjectGroupInvite.exists?(unrelated.id)
test/services/group_invite_responder_test.rb:9:    @group = create(:project_group, course: @course, leader_id: @leader.id, locked: true)
test/services/group_invite_responder_test.rb:10:    create(:project_group_member, project_group: @group, user: @leader)
test/services/group_invite_responder_test.rb:19:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:25:    assert @group.project_group_members.exists?(user_id: @student.id)
test/services/group_invite_responder_test.rb:32:    invite = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
test/services/group_invite_responder_test.rb:38:    assert @group.project_group_members.exists?(user_id: @student.id)
test/services/group_invite_responder_test.rb:43:    request = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:45:    invite  = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
test/services/group_invite_responder_test.rb:53:    assert_not @group.project_group_members.exists?(user_id: @student.id)
test/services/group_invite_responder_test.rb:57:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:67:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:78:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:80:    other_group = create(:project_group, course: @course, leader_id: @student.id)
test/services/group_invite_responder_test.rb:81:    create(:project_group_member, project_group: other_group, user: @student)
test/services/group_invite_responder_test.rb:90:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:92:    create(:project_group_member, project_group: @group)
test/services/group_invite_responder_test.rb:105:      create(:project_group_member, project_group: @group, user: filler)
test/services/group_invite_responder_test.rb:107:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:117:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:129:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:135:          GroupInviteResponder.new(ProjectGroupInvite.find(invite.id), current_user: @leader).accept!
test/services/group_invite_responder_test.rb:146:    assert_equal 1, @group.project_group_members.where(user_id: @student.id).count
test/services/group_invite_responder_test.rb:152:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:162:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:164:    create(:project_group_member, project_group: @group)
test/services/group_invite_responder_test.rb:175:    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
test/services/group_invite_responder_test.rb:177:    other_group = create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_invite_responder_test.rb:178:    stale_request = create(:project_group_invite, project_group: other_group, sender: @student,
test/services/group_invite_responder_test.rb:184:    assert_not ProjectGroupInvite.exists?(stale_request.id)
test/services/group_invite_link_generator_test.rb:9:    @group = create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_invite_link_generator_test.rb:10:    create(:project_group_member, project_group: @group, user: @leader)
test/services/group_invite_link_generator_test.rb:20:    link = @group.project_group_invite_links.find_by(sender: @leader)
test/services/group_invite_link_generator_test.rb:29:    assert_equal 1, @group.project_group_invite_links.where(sender: @leader).count
test/services/group_invite_link_generator_test.rb:30:    assert_not ProjectGroupInviteLink.exists?(token: first.token)
test/services/group_invite_link_generator_test.rb:36:    create(:project_group_member, project_group: @group, user: other_member)
test/services/group_invite_link_generator_test.rb:41:    assert ProjectGroupInviteLink.exists?(token: other_link.token)
test/services/group_invite_link_generator_test.rb:54:    create(:project_group_member, project_group: @group)
test/services/group_invite_link_generator_test.rb:70:    create(:project_group_member, project_group: @group, user: new_leader)
test/services/group_invite_link_generator_test.rb:73:    assert ProjectGroupInviteLink.exists?(token: old_leader_link.token)
test/services/group_invite_link_generator_test.rb:74:    link = ProjectGroupInviteLink.find_by(token: old_leader_link.token)
test/services/group_member_adder_test.rb:9:    @group = create(:project_group, course: @course, leader_id: @leader.id)
test/services/group_member_adder_test.rb:10:    create(:project_group_member, project_group: @group, user: @leader)
test/services/group_member_adder_test.rb:25:    assert @group.project_group_members.exists?(user_id: @student.id)
test/services/group_member_adder_test.rb:29:    other_group = create(:project_group, course: @course, leader_id: @student.id)
test/services/group_member_adder_test.rb:30:    create(:project_group_member, project_group: other_group, user: @student)
test/services/group_member_adder_test.rb:42:      create(:project_group_member, project_group: @group, user: filler)
test/services/group_member_adder_test.rb:64:      create(:project_group_member, project_group: @group, user: filler)
test/services/group_member_adder_test.rb:66:    assert_equal @course.group_max, @group.project_group_members.count, 'group starts exactly at capacity'
test/services/group_member_adder_test.rb:74:    assert_operator @group.project_group_members.reload.count, :>, @course.group_max
test/services/group_member_adder_test.rb:85:    assert @group.project_group_members.exists?(user_id: outsider.id)
test/services/group_direct_requester_test.rb:10:    @group = create(:project_group, course: @course, leader_id: @leader.id, locked: true)
test/services/group_direct_requester_test.rb:11:    create(:project_group_member, project_group: @group, user: @leader)
test/services/group_direct_requester_test.rb:23:    invite = ProjectGroupInvite.find_by(project_group: @group, sender: @student)
test/services/group_direct_requester_test.rb:39:    other_group = create(:project_group, course: @course, leader_id: @student.id)
test/services/group_direct_requester_test.rb:40:    create(:project_group_member, project_group: other_group, user: @student)
test/services/group_direct_requester_test.rb:49:    create(:project_group_member, project_group: @group)
test/services/group_direct_requester_test.rb:83:    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
test/services/group_direct_requester_test.rb:92:          GroupDirectRequester.new(ProjectGroup.find(@group.id), current_user: @student).request!
test/services/group_direct_requester_test.rb:103:    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
test/services/group_creator_test.rb:22:    assert_equal 1, group.project_group_members.count
test/services/group_creator_test.rb:23:    assert_equal @student.id, group.project_group_members.first.user_id
test/services/group_creator_test.rb:28:    existing = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
test/services/group_creator_test.rb:29:    FactoryBot.create(:project_group_member, project_group: existing, user: @student)
test/services/group_creator_test.rb:56:    existing = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
test/services/group_creator_test.rb:57:    FactoryBot.create(:project_group_member, project_group: existing, user: @student)
test/services/group_creator_test.rb:77:    assert_no_difference 'ProjectGroup.count' do
test/services/group_creator_test.rb:78:      ProjectGroupMember.stub :create!, ->(*) { raise ActiveRecord::RecordInvalid, ProjectGroupMember.new } do
test/services/group_creator_test.rb:96:    csv_group = FactoryBot.create(:project_group, course: @course, group_name: 'G001', course_group_sequence: nil)
test/services/group_creator_test.rb:103:    assert_equal 2, @course.project_groups.where(group_name: 'G001').count
test/factories/project_group_invite_links.rb:2:  factory :project_group_invite_link do
test/factories/project_group_invite_links.rb:3:    association :project_group
test/factories/project_group_members.rb:2:  factory :project_group_member do
test/factories/project_group_members.rb:4:    association :project_group
test/factories/project_group_invites.rb:2:  factory :project_group_invite do
test/factories/project_group_invites.rb:3:    association :project_group
test/factories/project_groups.rb:2:  factory :project_group do

### END
~~~~

### A.1.2  `grep -rnE "confirmed|locked|leader_id|course_group_sequence" app lib`

Every read/write of the group's confirmed / locked / leader / sequence columns.

~~~~
### CMD: grep -rnE "confirmed|locked|leader_id|course_group_sequence" app lib

app/models/project_group.rb:11:    update!(confirmed: false)
app/models/project_group.rb:23:    leader_id == user.id
app/models/project_group.rb:28:      .new(course, students_to_group: course.unconfirmed_students_count)
app/models/course.rb:103:  def unconfirmed_students_count
app/models/course.rb:104:    confirmed_member_count = ProjectGroupMember
app/models/course.rb:106:                             .where(project_groups: { course_id: id, confirmed: true })
app/models/course.rb:109:    students.count - confirmed_member_count
app/models/course.rb:192:    project_groups.where(confirmed: false).find_each do |group|
app/models/project.rb:32:  validate :project_group_must_be_confirmed, if: -> { owner_type == 'ProjectGroup' }
app/models/project.rb:99:  def project_group_must_be_confirmed
app/models/project.rb:102:    return if group&.confirmed?
app/mailers/general_mailer.rb:69:    raise ArgumentError, "Group_Direct_Request_Notification: group #{@group.id} has no leader_id" if @group.leader_id.blank?
app/mailers/general_mailer.rb:71:    @leader = User.find(@group.leader_id)
app/policies/project_group_policy.rb:23:    record.leader_id == user.id
app/policies/project_group_policy.rb:29:    record.leader_id == user.id
app/policies/project_group_policy.rb:33:    return coordinator? if record.confirmed?
app/policies/project_group_policy.rb:35:    grouping_window_open? && record.leader_id == user.id
app/policies/project_group_policy.rb:42:      record.leader_id == user.id && !record.confirmed?
app/policies/project_group_policy.rb:49:      record.leader_id == user.id && !record.confirmed?
app/policies/project_group_policy.rb:56:      record.leader_id == user.id && !record.confirmed?
app/policies/project_group_policy.rb:68:    record.leader_id == user.id
app/policies/project_group_policy.rb:72:    record.leader_id == user.id
app/policies/project_group_invite_policy.rb:14:      record.project_group.leader_id == user.id
app/controllers/groups_controller.rb:19:    # Groups tab lists every project group, confirmed or draft — drafts are
app/controllers/project_group_members_controller.rb:36:      dissolve_confirmed: params[:dissolve_confirmed] == 'true'
app/controllers/project_group_members_controller.rb:50:        if result.blocked?
app/controllers/project_group_members_controller.rb:65:                      **(result.blocked? ? { alert: result.message } : { notice: result.message })
app/controllers/enrolments_controller.rb:20:        result = GroupMemberRemover.new(group_member, current_user: current_user, dissolve_confirmed: true).remove!
app/controllers/enrolments_controller.rb:22:        if result.blocked?
app/controllers/project_groups_controller.rb:13:    @my_group_can_confirm = @my_group.present? && !@my_group.confirmed? && @my_group.confirmable?
app/controllers/project_groups_controller.rb:79:    if result.confirmed?
app/controllers/project_groups_controller.rb:101:    if @group.leader_id.blank?
app/controllers/project_groups_controller.rb:107:      @group.update!(locked: true)
app/controllers/project_groups_controller.rb:112:    redirect_to course_project_groups_path(@course), notice: 'Group is now locked.'
app/controllers/project_groups_controller.rb:118:      @group.update!(locked: false)
app/controllers/project_groups_controller.rb:130:      @group.update!(leader_id: target_member.user_id)
app/controllers/projects_controller.rb:286:        raise StandardError, 'This project is locked and cannot be edited.' unless @project.editable? || is_approved
app/services/group_member_remover.rb:3:  def initialize(member, current_user:, dissolve_confirmed: false)
app/services/group_member_remover.rb:6:    @dissolve_confirmed = dissolve_confirmed
app/services/group_member_remover.rb:12:      return blocked(:window_closed) if requires_window_check? && !window_open?
app/services/group_member_remover.rb:13:      return blocked(:group_confirmed) if leader_kick? && @group.confirmed?
app/services/group_member_remover.rb:17:      return needs_confirmation(@group.project.current_title) if remaining_count.zero? && @group.project.present? && !@dissolve_confirmed
app/services/group_member_remover.rb:24:        return Result.new(outcome: :dissolved, blocked_reason: nil)
app/services/group_member_remover.rb:29:      if @group.confirmed? && (self_leave? || !legal_at_current_size?)
app/services/group_member_remover.rb:30:        @group.update!(confirmed: false)
app/services/group_member_remover.rb:31:        return Result.new(outcome: :reverted, blocked_reason: nil)
app/services/group_member_remover.rb:34:      Result.new(outcome: :unchanged, blocked_reason: nil)
app/services/group_member_remover.rb:62:    @group.update!(leader_id: successor.user_id)
app/services/group_member_remover.rb:71:  def blocked(reason)
app/services/group_member_remover.rb:72:    Result.new(outcome: :blocked, blocked_reason: reason)
app/services/group_member_remover.rb:76:    Result.new(outcome: :needs_confirmation, blocked_reason: nil, project_title: project_title)
app/services/group_member_remover.rb:80:    attr_reader :outcome, :blocked_reason, :project_title
app/services/group_member_remover.rb:82:    def initialize(outcome:, blocked_reason:, project_title: nil)
app/services/group_member_remover.rb:84:      @blocked_reason = blocked_reason
app/services/group_member_remover.rb:91:    def blocked? = outcome == :blocked
app/services/group_member_remover.rb:94:      return blocked_message if blocked?
app/services/group_member_remover.rb:106:    def blocked_message
app/services/group_member_remover.rb:107:      case blocked_reason
app/services/group_member_remover.rb:109:      when :group_confirmed then 'The leader can only remove members while the group is still a draft.'
app/services/group_confirmer.rb:12:      return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_confirmer.rb:13:      return blocked(:already_confirmed) if @group.confirmed?
app/services/group_confirmer.rb:15:      return blocked(:size_illegal) unless @group.confirmable?
app/services/group_confirmer.rb:17:      @group.update!(confirmed: true)
app/services/group_confirmer.rb:18:      Result.new(confirmed: true, blocked_reason: nil)
app/services/group_confirmer.rb:24:  def blocked(reason)
app/services/group_confirmer.rb:25:    Result.new(confirmed: false, blocked_reason: reason)
app/services/group_confirmer.rb:29:    attr_reader :blocked_reason
app/services/group_confirmer.rb:31:    def initialize(confirmed:, blocked_reason:)
app/services/group_confirmer.rb:32:      @confirmed = confirmed
app/services/group_confirmer.rb:33:      @blocked_reason = blocked_reason
app/services/group_confirmer.rb:36:    def confirmed? = @confirmed
app/services/group_confirmer.rb:39:      case blocked_reason
app/services/group_confirmer.rb:41:      when :already_confirmed then 'This group has already been confirmed.'
app/services/group_confirmer.rb:42:      when :size_illegal then 'This group cannot be confirmed at its current size.'
app/services/group_confirmer.rb:43:      when nil then 'Group confirmed.'
app/services/group_direct_requester.rb:1:# Student requests to join a locked group.
app/services/group_direct_requester.rb:13:    return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_direct_requester.rb:14:    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
app/services/group_direct_requester.rb:15:    return blocked(:group_confirmed) if @group.confirmed?
app/services/group_direct_requester.rb:16:    return blocked(:group_unlocked) unless @group.locked?
app/services/group_direct_requester.rb:17:    return blocked(:no_leader_assigned) if @group.leader_id.blank?
app/services/group_direct_requester.rb:22:      recipient_id: @group.leader_id,
app/services/group_direct_requester.rb:29:    Result.new(requested: true, blocked_reason: nil)
app/services/group_direct_requester.rb:31:    blocked(:already_requested)
app/services/group_direct_requester.rb:36:  def blocked(reason)
app/services/group_direct_requester.rb:37:    Result.new(requested: false, blocked_reason: reason)
app/services/group_direct_requester.rb:41:    attr_reader :blocked_reason
app/services/group_direct_requester.rb:43:    def initialize(requested:, blocked_reason:)
app/services/group_direct_requester.rb:45:      @blocked_reason = blocked_reason
app/services/group_direct_requester.rb:49:    def blocked? = !requested?
app/services/group_direct_requester.rb:54:      case blocked_reason
app/services/group_direct_requester.rb:57:      when :group_confirmed then 'Group already confirmed, not accepting requests.'
app/services/group_direct_requester.rb:58:      when :group_unlocked then 'Group is unlocked — join it directly instead.'
app/services/group_joiner.rb:1:# Direct join to an unlocked draft group. Use GroupJoinRequester for locked groups.
app/services/group_joiner.rb:12:      return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_joiner.rb:13:      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
app/services/group_joiner.rb:14:      return blocked(:group_confirmed) if @group.confirmed?
app/services/group_joiner.rb:15:      return blocked(:group_locked) if @group.locked?
app/services/group_joiner.rb:16:      return blocked(:group_full) if @group.project_group_members.count >= course.group_max.to_i
app/services/group_joiner.rb:21:      Result.new(joined: true, blocked_reason: nil)
app/services/group_joiner.rb:34:  def blocked(reason)
app/services/group_joiner.rb:35:    Result.new(joined: false, blocked_reason: reason)
app/services/group_joiner.rb:39:    attr_reader :blocked_reason
app/services/group_joiner.rb:41:    def initialize(joined:, blocked_reason:)
app/services/group_joiner.rb:43:      @blocked_reason = blocked_reason
app/services/group_joiner.rb:47:    def blocked? = !joined?
app/services/group_joiner.rb:52:      case blocked_reason
app/services/group_joiner.rb:55:      when :group_confirmed then 'Group already confirmed, not accepting members.'
app/services/group_joiner.rb:56:      when :group_locked then 'Group is locked. Send a join request instead.'
app/services/group_invite_link_generator.rb:3:# draft groups, no email notifications, can join if locked
app/services/group_invite_link_generator.rb:13:    return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_invite_link_generator.rb:14:    return blocked(:group_confirmed) if @group.confirmed?
app/services/group_invite_link_generator.rb:25:      Result.new(generated: true, blocked_reason: nil,
app/services/group_invite_link_generator.rb:32:  def blocked(reason)
app/services/group_invite_link_generator.rb:33:    Result.new(generated: false, blocked_reason: reason, token: nil, expires_at: nil)
app/services/group_invite_link_generator.rb:37:    attr_reader :blocked_reason, :token, :expires_at
app/services/group_invite_link_generator.rb:39:    def initialize(generated:, blocked_reason:, token:, expires_at:)
app/services/group_invite_link_generator.rb:41:      @blocked_reason = blocked_reason
app/services/group_invite_link_generator.rb:47:    def blocked? = !generated?
app/services/group_invite_link_generator.rb:52:      case blocked_reason
app/services/group_invite_link_generator.rb:54:      when :group_confirmed then 'Group already confirmed.'
app/services/group_reverter.rb:6:  # Leader reverts a confirmed group back to draft if the grouping window is open.
app/services/group_reverter.rb:11:      return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_reverter.rb:12:      return blocked(:already_draft) unless @group.confirmed?
app/services/group_reverter.rb:14:      @group.update!(confirmed: false)
app/services/group_reverter.rb:15:      Result.new(reverted: true, blocked_reason: nil)
app/services/group_reverter.rb:21:  def blocked(reason)
app/services/group_reverter.rb:22:    Result.new(reverted: false, blocked_reason: reason)
app/services/group_reverter.rb:26:    attr_reader :blocked_reason
app/services/group_reverter.rb:28:    def initialize(reverted:, blocked_reason:)
app/services/group_reverter.rb:30:      @blocked_reason = blocked_reason
app/services/group_reverter.rb:36:      case blocked_reason
app/services/group_creator.rb:12:      return blocked(:already_grouped) if already_grouped?
app/services/group_creator.rb:13:      return blocked(:window_closed) if self_create? && !@course.grouping_window_open?
app/services/group_creator.rb:16:      Result.new(created: true, group: group, blocked_reason: nil)
app/services/group_creator.rb:31:    next_seq = @course.project_groups.maximum(:course_group_sequence).to_i + 1
app/services/group_creator.rb:33:      leader_id: @leader.id,
app/services/group_creator.rb:34:      course_group_sequence: next_seq,
app/services/group_creator.rb:41:  def blocked(reason)
app/services/group_creator.rb:42:    Result.new(created: false, group: nil, blocked_reason: reason)
app/services/group_creator.rb:46:    attr_reader :group, :blocked_reason
app/services/group_creator.rb:48:    def initialize(created:, group:, blocked_reason:)
app/services/group_creator.rb:51:      @blocked_reason = blocked_reason
app/services/group_creator.rb:55:    def blocked? = !created?
app/services/group_creator.rb:60:      case blocked_reason
app/services/group_member_adder.rb:13:    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @user.id)
app/services/group_member_adder.rb:14:    return blocked(:group_full) if group_full?(course)
app/services/group_member_adder.rb:18:      Result.new(added: true, blocked_reason: nil)
app/services/group_member_adder.rb:28:  def blocked(reason)
app/services/group_member_adder.rb:29:    Result.new(added: false, blocked_reason: reason)
app/services/group_member_adder.rb:33:    attr_reader :blocked_reason
app/services/group_member_adder.rb:35:    def initialize(added:, blocked_reason:)
app/services/group_member_adder.rb:37:      @blocked_reason = blocked_reason
app/services/group_member_adder.rb:41:    def blocked? = !added?
app/services/group_member_adder.rb:46:      case blocked_reason
app/services/group_direct_inviter.rb:15:    return blocked(:invalid_recipient) unless recipient_enrolment&.student?
app/services/group_direct_inviter.rb:16:    return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_direct_inviter.rb:17:    return blocked(:group_confirmed) if @group.confirmed?
app/services/group_direct_inviter.rb:18:    return blocked(:group_full) if group_full?(course)
app/services/group_direct_inviter.rb:19:    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @recipient.id)
app/services/group_direct_inviter.rb:31:    Result.new(invited: true, blocked_reason: nil)
app/services/group_direct_inviter.rb:33:    blocked(:already_invited)
app/services/group_direct_inviter.rb:42:  def blocked(reason)
app/services/group_direct_inviter.rb:43:    Result.new(invited: false, blocked_reason: reason)
app/services/group_direct_inviter.rb:47:    attr_reader :blocked_reason
app/services/group_direct_inviter.rb:49:    def initialize(invited:, blocked_reason:)
app/services/group_direct_inviter.rb:51:      @blocked_reason = blocked_reason
app/services/group_direct_inviter.rb:55:    def blocked? = !invited?
app/services/group_direct_inviter.rb:60:      case blocked_reason
app/services/group_direct_inviter.rb:63:      when :group_confirmed then 'Group already confirmed, not accepting members.'
app/services/group_invite_link_redeemer.rb:12:    return blocked(:expired) if @invite_link.expires_at.past?
app/services/group_invite_link_redeemer.rb:19:      return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_invite_link_redeemer.rb:20:      return blocked(:group_confirmed) if group.confirmed?
app/services/group_invite_link_redeemer.rb:21:      return blocked(:group_full) if group_full?(group, course)
app/services/group_invite_link_redeemer.rb:22:      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @current_user.id)
app/services/group_invite_link_redeemer.rb:27:      Result.new(redeemed: true, blocked_reason: nil, group: group)
app/services/group_invite_link_redeemer.rb:45:  def blocked(reason)
app/services/group_invite_link_redeemer.rb:46:    Result.new(redeemed: false, blocked_reason: reason, group: nil)
app/services/group_invite_link_redeemer.rb:50:    attr_reader :blocked_reason, :group
app/services/group_invite_link_redeemer.rb:52:    def initialize(redeemed:, blocked_reason:, group:)
app/services/group_invite_link_redeemer.rb:54:      @blocked_reason = blocked_reason
app/services/group_invite_link_redeemer.rb:59:    def blocked? = !redeemed?
app/services/group_invite_link_redeemer.rb:64:      case blocked_reason
app/services/group_invite_link_redeemer.rb:67:      when :group_confirmed then 'This group is already confirmed.'
app/services/group_invite_responder.rb:17:      return blocked(:already_responded) unless @invite.pending?
app/services/group_invite_responder.rb:22:      return blocked(:window_closed) unless course.grouping_window_open?
app/services/group_invite_responder.rb:23:      return blocked(:already_grouped) if course.project_group_members.exists?(user_id: joining_user.id)
app/services/group_invite_responder.rb:24:      return blocked(:group_confirmed) if @group.confirmed?
app/services/group_invite_responder.rb:25:      return blocked(:group_full) if group_full?(course)
app/services/group_invite_responder.rb:33:      Result.new(outcome: :accepted, blocked_reason: nil)
app/services/group_invite_responder.rb:38:    return blocked(:already_responded) unless @invite.pending?
app/services/group_invite_responder.rb:43:    Result.new(outcome: :declined, blocked_reason: nil)
app/services/group_invite_responder.rb:76:  def blocked(reason)
app/services/group_invite_responder.rb:77:    Result.new(outcome: :blocked, blocked_reason: reason)
app/services/group_invite_responder.rb:81:    attr_reader :outcome, :blocked_reason
app/services/group_invite_responder.rb:83:    def initialize(outcome:, blocked_reason:)
app/services/group_invite_responder.rb:85:      @blocked_reason = blocked_reason
app/services/group_invite_responder.rb:90:    def blocked? = outcome == :blocked
app/services/group_invite_responder.rb:93:      return blocked_message if blocked?
app/services/group_invite_responder.rb:103:    def blocked_message
app/services/group_invite_responder.rb:104:      case blocked_reason
app/services/group_invite_responder.rb:107:      when :group_confirmed then 'Group already confirmed, not accepting members.'
app/views/project_group_members/_dissolve_warning_modal.html.erb:64:            params: { dissolve_confirmed: true },
app/views/project_groups/_my_group_panel.html.erb:98:      am_leader    = @my_group.leader_id == current_user.id
app/views/project_groups/_my_group_panel.html.erb:99:      is_confirmed = @my_group.confirmed?
app/views/project_groups/_my_group_panel.html.erb:100:      is_locked    = @my_group.locked?
app/views/project_groups/_my_group_panel.html.erb:113:          <%= is_confirmed ? "border-l-emerald-600" : "border-l-gray-400" %>
app/views/project_groups/_my_group_panel.html.erb:125:            <% if is_confirmed %>
app/views/project_groups/_my_group_panel.html.erb:131:            <% if is_locked %>
app/views/project_groups/_my_group_panel.html.erb:143:        <% if am_leader && !is_confirmed && window_open %>
app/views/project_groups/_my_group_panel.html.erb:161:              <% if !is_confirmed && window_open %>
app/views/project_groups/_my_group_panel.html.erb:170:              <% if is_confirmed && window_open %>
app/views/project_groups/_my_group_panel.html.erb:175:                      form: { data: { confirm: "Revert to draft? You will lose confirmed status." } } %>
app/views/project_groups/_my_group_panel.html.erb:178:              <% if !is_confirmed && window_open %>
app/views/project_groups/_my_group_panel.html.erb:179:                <% if is_locked %>
app/views/project_groups/_my_group_panel.html.erb:192:              <% if !is_confirmed && window_open %>
app/views/project_groups/_my_group_panel.html.erb:239:              <% is_this_leader = member.id == @my_group.leader_id %>
app/views/project_groups/_my_group_panel.html.erb:254:                <% if am_leader && !is_this_leader && !is_confirmed && window_open %>
app/views/project_groups/_my_group_panel.html.erb:287:              <% if !is_confirmed && window_open %>
app/views/project_groups/_group_card.html.erb:18:  elsif group.confirmed?
app/views/project_groups/_group_card.html.erb:33:  data-status="<%= group.confirmed? ? "confirmed" : "draft" %>"
app/views/project_groups/_group_card.html.erb:43:      <% if group.confirmed? %>
app/views/project_groups/_group_card.html.erb:49:      <% if group.locked? %>
app/views/project_groups/_group_card.html.erb:69:        <% elsif group.locked? %>
app/views/project_groups/_group_card.html.erb:85:      <% if policy(group).confirm? && !group.confirmed? %>
app/views/project_groups/_group_card.html.erb:90:              form: { data: { turbo_confirm: "Confirm #{group.group_name.presence || 'this group'}? Members can no longer be kicked once confirmed." } } %>
app/views/project_groups/_group_card.html.erb:91:      <% elsif policy(group).revert? && group.confirmed? %>
app/views/project_groups/_group_card.html.erb:139:            <% if membership.user_id == group.leader_id %>
app/views/project_groups/index.html.erb:49:          confirmed_count = @groups.count(&:confirmed?)
app/views/project_groups/index.html.erb:50:          draft_count     = @groups.size - confirmed_count
app/views/project_groups/index.html.erb:69:                    data-status="confirmed"
app/views/project_groups/index.html.erb:73:              Confirmed <span class="text-gray-400"><%= confirmed_count %></span>

### END
~~~~

### A.1.3  `grep -rnE "enrolments?\.(destroy|delete)|Enrolment.*(destroy|delete)|dependent:" app`

Every enrolment deletion and every `dependent:` destroy declaration.

~~~~
### CMD: grep -rnE "enrolments?\.(destroy|delete)|Enrolment.*(destroy|delete)|dependent:" app

app/models/project_group.rb:2:  has_many :project_group_members, dependent: :destroy
app/models/project_group.rb:6:  has_one :project, dependent: :destroy, as: :owner
app/models/project_group.rb:7:  has_many :project_group_invites, dependent: :destroy
app/models/project_group.rb:8:  has_many :project_group_invite_links, dependent: :destroy
app/models/ownership.rb:4:  has_one :project, dependent: :destroy
app/models/enrolment.rb:5:  has_many :projects, dependent: :destroy
app/models/course.rb:5:  has_many :enrolments, dependent: :destroy
app/models/course.rb:12:  has_many :projects, dependent: :destroy
app/models/course.rb:13:  has_many :project_groups, dependent: :destroy
app/models/course.rb:15:  has_one :project_template, dependent: :destroy
app/models/course.rb:17:  has_many :topics, dependent: :destroy
app/models/project_instance.rb:9:  has_many :comments, as: :location, dependent: :destroy
app/models/project_instance.rb:17:  has_many :project_instance_fields, dependent: :destroy, as: :instance
app/models/user.rb:3:  has_many :sessions, dependent: :destroy
app/models/user.rb:8:  has_many :enrolments, dependent: :destroy
app/models/user.rb:19:  has_many :project_group_members, dependent: :destroy
app/models/user.rb:22:  has_many :comments, dependent: :destroy
app/models/user.rb:23:  has_one :otp, dependent: :destroy
app/models/project_template.rb:3:  has_many :project_template_fields, -> { order(position: :asc) }, dependent: :destroy
app/models/project.rb:9:  has_many :project_instances, dependent: :destroy
app/models/project.rb:10:  has_many :progress_updates, dependent: :destroy
app/models/topic_instance.rb:9:  has_many :comments, as: :location, dependent: :destroy
app/models/topic_instance.rb:17:  has_many :project_instance_fields, dependent: :destroy, as: :instance
app/models/topic.rb:11:  has_many :topic_instances, dependent: :destroy, foreign_key: 'project_id'
app/models/project_template_field.rb:8:  has_many   :project_instance_fields, dependent: :destroy
app/controllers/enrolments_controller.rb:29:    enrolment.destroy!

### END
~~~~

### A.1.4  `grep -rnE "group_min|group_max|student_list_finalised|grouping_open|grouping_opens_at|grouping_closes_at|grouping_enabled" app lib`

Every read/write of the grouping configuration attributes.

~~~~
### CMD: grep -rnE "group_min|group_max|student_list_finalised|grouping_open|grouping_opens_at|grouping_closes_at|grouping_enabled" app lib

app/models/course.rb:49:  # group_min and group_max are required whenever grouping is enabled
app/models/course.rb:50:  validates :group_min, presence: { message: 'is required when self-grouping is enabled' }, if: :grouping_enabled?
app/models/course.rb:51:  validates :group_max, presence: { message: 'is required when self-grouping is enabled' }, if: :grouping_enabled?
app/models/course.rb:52:  validates :group_min, numericality: { only_integer: true, greater_than: 0, message: 'must be a positive whole number' }, allow_nil: true
app/models/course.rb:54:  validates :group_max,
app/models/course.rb:55:            numericality: { only_integer: true, greater_than_or_equal_to: :group_min_for_validation, message: 'must be greater than or equal to minimum' },
app/models/course.rb:57:            if: -> { group_min.present? && group_max.present? }
app/models/course.rb:59:  # student_list_finalised cannot be true if grouping_enabled is false.
app/models/course.rb:60:  validates :student_list_finalised, inclusion: { in: [false], message: 'cannot be set without self-grouping enabled' }, unless: :grouping_enabled?
app/models/course.rb:61:  validate :grouping_window_dates_valid, if: -> { grouping_opens_at.present? && grouping_closes_at.present? }
app/models/course.rb:75:    return false unless grouping_enabled?
app/models/course.rb:76:    return false unless grouping_open?
app/models/course.rb:78:    opens_ok = grouping_opens_at.nil? || Time.current >= grouping_opens_at
app/models/course.rb:79:    closes_ok = grouping_closes_at.nil? || Time.current <= grouping_closes_at
app/models/course.rb:86:      update!(grouping_enabled: false, grouping_open: false, student_list_finalised: false)
app/models/course.rb:90:  # NOTE: Called when coordinator switches from student_list_finalised mode back to default mode.
app/models/course.rb:95:      update!(student_list_finalised: false)
app/models/course.rb:100:    update!(student_list_finalised: true)
app/models/course.rb:204:    return if grouping_enabled?
app/models/course.rb:206:    self.grouping_open          = false
app/models/course.rb:207:    self.student_list_finalised = false
app/models/course.rb:208:    self.group_min              = nil
app/models/course.rb:209:    self.group_max              = nil
app/models/course.rb:210:    self.grouping_opens_at      = nil
app/models/course.rb:211:    self.grouping_closes_at     = nil
app/models/course.rb:215:    return unless grouping_closes_at <= grouping_opens_at
app/models/course.rb:217:    errors.add(:grouping_closes_at, 'must be after the grouping open time')
app/models/course.rb:220:  def group_min_for_validation
app/models/course.rb:221:    group_min || 0
app/policies/course_policy.rb:79:    enrolment.present? && record.grouping_enabled?
app/controllers/courses_controller.rb:211:    grouping_enabled_param = params[:course][:grouping_enabled] == 'true'
app/controllers/courses_controller.rb:212:    student_list_param     = params[:course][:student_list_finalised] == 'true'
app/controllers/courses_controller.rb:241:        if @course.grouping_enabled? && !grouping_enabled_param
app/controllers/courses_controller.rb:243:        elsif @course.grouping_enabled? && @course.student_list_finalised? && !student_list_param
app/controllers/courses_controller.rb:247:            grouping_enabled: grouping_enabled_param,
app/controllers/courses_controller.rb:248:            student_list_finalised: student_list_param,
app/controllers/courses_controller.rb:249:            group_min: params[:course][:group_min].presence,
app/controllers/courses_controller.rb:250:            group_max: params[:course][:group_max].presence,
app/controllers/courses_controller.rb:251:            grouping_open: params[:course][:grouping_open] == 'true',
app/controllers/courses_controller.rb:252:            grouping_opens_at: params[:course][:grouping_opens_at].presence,
app/controllers/courses_controller.rb:253:            grouping_closes_at: params[:course][:grouping_closes_at].presence
app/controllers/courses_controller.rb:763:  # (@course.grouped? && @course.grouping_enabled?) — in an ungrouped course a
app/controllers/courses_controller.rb:765:  # expected, not an empty state. The grouping_enabled? guard also keeps the
app/controllers/courses_controller.rb:768:  # which requires grouping_enabled? == true for a non-coordinator. A grouped
app/controllers/courses_controller.rb:776:    if @course.grouped? && @course.grouping_enabled? && @group.nil?
app/controllers/project_groups_controller.rb:144:        grouping_enabled_param = %w[1 true].include?(params[:grouping_enabled])
app/controllers/project_groups_controller.rb:145:        student_list_param     = %w[1 true].include?(params[:student_list_finalised])
app/controllers/project_groups_controller.rb:147:        if @course.grouping_enabled? && !grouping_enabled_param
app/controllers/project_groups_controller.rb:150:        elsif @course.grouping_enabled? && @course.student_list_finalised? && !student_list_param
app/controllers/project_groups_controller.rb:156:            grouping_enabled: grouping_enabled_param,
app/controllers/project_groups_controller.rb:157:            student_list_finalised: student_list_param,
app/controllers/project_groups_controller.rb:158:            group_min: params[:group_min].presence,
app/controllers/project_groups_controller.rb:159:            group_max: params[:group_max].presence,
app/controllers/project_groups_controller.rb:160:            grouping_open: %w[1 true].include?(params[:grouping_open]),
app/controllers/project_groups_controller.rb:161:            grouping_opens_at: params[:grouping_opens_at].presence,
app/controllers/project_groups_controller.rb:162:            grouping_closes_at: params[:grouping_closes_at].presence
app/services/group_joiner.rb:16:      return blocked(:group_full) if @group.project_group_members.count >= course.group_max.to_i
app/services/queries/group_size_confirmability_calculator.rb:12:      group_min = @course.group_min
app/services/queries/group_size_confirmability_calculator.rb:13:      group_max = @course.group_max
app/services/queries/group_size_confirmability_calculator.rb:15:      return blank_result(:group_size_limits_not_configured) if group_min.blank? || group_max.blank?
app/services/queries/group_size_confirmability_calculator.rb:17:      if @course.student_list_finalised?
app/services/queries/group_size_confirmability_calculator.rb:20:        execute_quota(group_min, group_max)
app/services/queries/group_size_confirmability_calculator.rb:22:        execute_min_max(group_min, group_max)
app/services/queries/group_size_confirmability_calculator.rb:26:    def self.feasible_count?(count, group_min, group_max)
app/services/queries/group_size_confirmability_calculator.rb:30:      k = (count.to_f / group_max).ceil
app/services/queries/group_size_confirmability_calculator.rb:31:      (count / k) >= group_min
app/services/queries/group_size_confirmability_calculator.rb:41:    def execute_quota(group_min, group_max)
app/services/queries/group_size_confirmability_calculator.rb:42:      k = (@students_to_group.to_f / group_max).ceil
app/services/queries/group_size_confirmability_calculator.rb:46:      return blank_result(:no_legal_combination_exists) if base < group_min
app/services/queries/group_size_confirmability_calculator.rb:54:                 group_min: group_min, group_max: group_max,
app/services/queries/group_size_confirmability_calculator.rb:59:    def execute_min_max(group_min, group_max)
app/services/queries/group_size_confirmability_calculator.rb:60:      breakdown = (group_min..group_max).map { |size| { group_size: size, number_of_groups: nil } }
app/services/queries/group_size_confirmability_calculator.rb:62:                 group_min: group_min, group_max: group_max,
app/services/queries/group_size_confirmability_calculator.rb:70:                     group_min: nil, group_max: nil, students_to_group: nil, finalised: nil)
app/services/queries/group_size_confirmability_calculator.rb:75:        @group_min = group_min
app/services/queries/group_size_confirmability_calculator.rb:76:        @group_max = group_max
app/services/queries/group_size_confirmability_calculator.rb:87:        return false unless (@group_min..@group_max).cover?(size)
app/services/queries/group_size_confirmability_calculator.rb:91:        GroupSizeConfirmabilityCalculator.feasible_count?(remainder, @group_min, @group_max)
app/services/group_member_adder.rb:2:# group_max is still checked.
app/services/group_member_adder.rb:25:    course.group_max.present? && @group.project_group_members.count >= course.group_max
app/services/group_direct_inviter.rb:39:    course.group_max.present? && @group.project_group_members.count >= course.group_max
app/services/group_invite_link_redeemer.rb:34:    course.group_max.present? && group.project_group_members.count >= course.group_max
app/services/group_invite_responder.rb:49:    course.group_max.present? && @group.project_group_members.count >= course.group_max
app/javascript/controllers/grouping_settings_controller.js:5:    "groupingOptions", // the block shown when grouping_enabled = true
app/javascript/controllers/grouping_settings_controller.js:6:    "previewSection", // the preview block shown in student_list_finalised mode
app/javascript/controllers/grouping_settings_controller.js:10:    "minMax", // group_min and group_max inputs
app/javascript/controllers/grouping_settings_controller.js:28:  // Called when the grouping_enabled radio buttons change.
app/javascript/controllers/grouping_settings_controller.js:68:  // Called when the student_list_finalised radio buttons change.
app/javascript/controllers/grouping_settings_controller.js:95:  // Called when group_min or group_max changes — clears the preview result so
app/views/courses/settings.html.erb:208:               data-grouping-settings-enabled-value="<%= @course.grouping_enabled? %>"
app/views/courses/settings.html.erb:209:               data-grouping-settings-finalised-value="<%= @course.student_list_finalised? %>">
app/views/courses/settings.html.erb:222:                  <%= form.radio_button :grouping_enabled, true,
app/views/courses/settings.html.erb:227:                  <%= form.radio_button :grouping_enabled, false,
app/views/courses/settings.html.erb:252:                    <label class="flex items-start gap-3 p-4 rounded-lg cursor-pointer transition-colors <%= @course.student_list_finalised? ? 'border border-outline-variant bg-white hover:border-primary' : 'border border-primary bg-primary-container/40' %>">
app/views/courses/settings.html.erb:253:                      <%= form.radio_button :student_list_finalised, false,
app/views/courses/settings.html.erb:265:                    <% if @course.persisted? && @course.grouping_enabled? && !@course.student_list_finalised? %>
app/views/courses/settings.html.erb:276:                      <label class="flex items-start gap-3 p-4 rounded-lg cursor-pointer transition-colors <%= @course.student_list_finalised? ? 'border border-primary bg-primary-container/40' : 'border border-outline-variant bg-white hover:border-primary' %>">
app/views/courses/settings.html.erb:277:                        <%= form.radio_button :student_list_finalised, true,
app/views/courses/settings.html.erb:294:                    <%= form.label :group_min, "Minimum group size", class: "absolute top-2 left-4 text-xs font-medium text-on-surface-variant" %>
app/views/courses/settings.html.erb:295:                    <%= form.number_field :group_min, min: 1, placeholder: "e.g. 3",
app/views/courses/settings.html.erb:301:                    <%= form.label :group_max, "Maximum group size", class: "absolute top-2 left-4 text-xs font-medium text-on-surface-variant" %>
app/views/courses/settings.html.erb:302:                    <%= form.number_field :group_max, min: 1, placeholder: "e.g. 4",
app/views/courses/settings.html.erb:321:                             hx-include="[name='student_count'], [name='course[group_min]'], [name='course[group_max]']"
app/views/courses/settings.html.erb:322:                             hx-params="student_count,course[group_min],course[group_max]"
app/views/courses/settings.html.erb:349:                      <%= form.radio_button :grouping_open, true, class: "text-primary border-outline mr-2" %> Open
app/views/courses/settings.html.erb:352:                      <%= form.radio_button :grouping_open, false, class: "text-primary border-outline mr-2" %> Closed
app/views/courses/settings.html.erb:369:                      <%= (@course.grouping_opens_at.present? || @course.grouping_closes_at.present?) ? 'Remove window' : 'Set a window' %>
app/views/courses/settings.html.erb:375:                      <%= form.label :grouping_opens_at, "Open from", class: "absolute top-2 left-4 text-xs font-medium text-on-surface-variant" %>
app/views/courses/settings.html.erb:376:                      <%= form.datetime_local_field :grouping_opens_at,
app/views/courses/settings.html.erb:378:                            value: @course.grouping_opens_at&.strftime('%Y-%m-%dT%H:%M') %>
app/views/courses/settings.html.erb:381:                      <%= form.label :grouping_closes_at, "Close at", class: "absolute top-2 left-4 text-xs font-medium text-on-surface-variant" %>
app/views/courses/settings.html.erb:382:                      <%= form.datetime_local_field :grouping_closes_at,
app/views/courses/settings.html.erb:384:                            value: @course.grouping_closes_at&.strftime('%Y-%m-%dT%H:%M') %>
app/views/project_groups/_my_group_panel.html.erb:139:          <p class="text-xs text-gray-400 mt-1"><%= member_count %> / <%= @course.group_max %> members</p>
app/views/project_groups/_my_group_panel.html.erb:167:                      title: @my_group_can_confirm ? nil : "Group needs #{@course.group_min}–#{@course.group_max} members to confirm" %>
app/views/project_groups/_group_card.html.erb:10:  course.group_max.present? && member_count > course.group_max.to_i %>
app/views/project_groups/_group_card.html.erb:62:        <%= "⚠️ " if is_over_limit %><%= member_count %>/<%= course.group_max.presence || "?" %>
app/views/project_groups/index.html.erb:23:    <span><%= @course.student_list_finalised? ? "Auto-Confirmability mode" : "Default mode" %></span>
app/views/project_groups/index.html.erb:25:    <span>Min: <%= @course.group_min %> Max: <%= @course.group_max %></span>

### END
~~~~

### A.1.5  `grep -rnE "transaction do|with_lock|\.lock\b|lock!" app`

Every transaction and every row lock in the app.

~~~~
### CMD: grep -rnE "transaction do|with_lock|\.lock\b|lock!" app

app/models/course.rb:84:    transaction do
app/models/course.rb:93:    transaction do
app/controllers/user_controller.rb:137:      ActiveRecord::Base.transaction do
app/controllers/topics_controller.rb:142:      ActiveRecord::Base.transaction do
app/controllers/topics_controller.rb:197:      ActiveRecord::Base.transaction do
app/controllers/courses_controller.rb:92:      ActiveRecord::Base.transaction do
app/controllers/courses_controller.rb:133:      ActiveRecord::Base.transaction do
app/controllers/courses_controller.rb:169:      ActiveRecord::Base.transaction do
app/controllers/courses_controller.rb:216:      ActiveRecord::Base.transaction do
app/controllers/courses_controller.rb:321:    ActiveRecord::Base.transaction do
app/controllers/project_groups_controller.rb:51:      ActiveRecord::Base.transaction do
app/controllers/project_groups_controller.rb:142:      ActiveRecord::Base.transaction do
app/controllers/projects_controller.rb:196:      ActiveRecord::Base.transaction do
app/controllers/projects_controller.rb:285:      ActiveRecord::Base.transaction do
app/services/group_member_remover.rb:11:    @group.with_lock do
app/services/group_confirmer.rb:9:    @group.with_lock do
app/services/group_joiner.rb:9:    @group.with_lock do
app/services/group_invite_link_generator.rb:16:    @group.with_lock do
app/services/group_reverter.rb:8:    @group.with_lock do
app/services/group_creator.rb:11:    @course.with_lock do
app/services/group_member_adder.rb:16:    @group.with_lock do
app/services/group_invite_link_redeemer.rb:16:    group.with_lock do
app/services/user_creator.rb:16:      ActiveRecord::Base.transaction do
app/services/group_invite_responder.rb:15:    @group.with_lock do

### END
~~~~

### A.1.6  `grep -rnE "force_confirm|import|coursecode" app config/routes.rb`

The removed `force_confirm`, the CSV import path and the coursecode enrolment path.

~~~~
### CMD: grep -rnE "force_confirm|import|coursecode" app config/routes.rb

app/models/enrolment.rb:12:  def self.enroll_via_coursecode(user, code)
app/models/enrolment.rb:13:    course = Course.by_coursecode(code).first
app/models/enrolment.rb:16:    raise 'Joining via course code is disabled for this course' unless course.coursecode_enabled
app/models/course.rb:33:  scope :by_coursecode, ->(code) { where(coursecode: code) }
app/models/course.rb:46:  validates :coursecode, uniqueness: { message: 'has already been taken' }, allow_nil: true
app/models/course.rb:66:  def generate_coursecode!
app/models/course.rb:70:    self.coursecode = sqids.encode([id, SecureRandom.random_number(1_000_000_000)])
app/assets/builds/tailwind.css:2:@layer properties{@supports (((-webkit-hyphens:none)) and (not (margin-trim:inline))) or ((-moz-orient:inline) and (not (color:rgb(from red r g b)))){*,:before,:after,::backdrop{--tw-translate-x:0;--tw-translate-y:0;--tw-translate-z:0;--tw-rotate-x:initial;--tw-rotate-y:initial;--tw-rotate-z:initial;--tw-skew-x:initial;--tw-skew-y:initial;--tw-space-y-reverse:0;--tw-space-x-reverse:0;--tw-divide-y-reverse:0;--tw-border-style:solid;--tw-gradient-position:initial;--tw-gradient-from:#0000;--tw-gradient-via:#0000;--tw-gradient-to:#0000;--tw-gradient-stops:initial;--tw-gradient-via-stops:initial;--tw-gradient-from-position:0%;--tw-gradient-via-position:50%;--tw-gradient-to-position:100%;--tw-leading:initial;--tw-font-weight:initial;--tw-tracking:initial;--tw-shadow:0 0 #0000;--tw-shadow-color:initial;--tw-shadow-alpha:100%;--tw-inset-shadow:0 0 #0000;--tw-inset-shadow-color:initial;--tw-inset-shadow-alpha:100%;--tw-ring-color:initial;--tw-ring-shadow:0 0 #0000;--tw-inset-ring-color:initial;--tw-inset-ring-shadow:0 0 #0000;--tw-ring-inset:initial;--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-offset-shadow:0 0 #0000;--tw-outline-style:solid;--tw-blur:initial;--tw-brightness:initial;--tw-contrast:initial;--tw-grayscale:initial;--tw-hue-rotate:initial;--tw-invert:initial;--tw-opacity:initial;--tw-saturate:initial;--tw-sepia:initial;--tw-drop-shadow:initial;--tw-drop-shadow-color:initial;--tw-drop-shadow-alpha:100%;--tw-drop-shadow-size:initial;--tw-backdrop-blur:initial;--tw-backdrop-brightness:initial;--tw-backdrop-contrast:initial;--tw-backdrop-grayscale:initial;--tw-backdrop-hue-rotate:initial;--tw-backdrop-invert:initial;--tw-backdrop-opacity:initial;--tw-backdrop-saturate:initial;--tw-backdrop-sepia:initial;--tw-duration:initial;--tw-ease:initial;--tw-content:"";--tw-scale-x:1;--tw-scale-y:1;--tw-scale-z:1;--tw-divide-x-reverse:0;--tw-pan-x:initial;--tw-pan-y:initial;--tw-pinch-zoom:initial}}}@layer theme{:root,:host{--font-sans:ui-sans-serif,system-ui,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol","Noto Color Emoji";--font-mono:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace;--color-red-50:oklch(97.1% .013 17.38);--color-red-100:oklch(93.6% .032 17.717);--color-red-200:oklch(88.5% .062 18.334);--color-red-400:oklch(70.4% .191 22.216);--color-red-500:oklch(63.7% .237 25.331);--color-red-600:oklch(57.7% .245 27.325);--color-red-700:oklch(50.5% .213 27.518);--color-red-800:oklch(44.4% .177 26.899);--color-amber-50:oklch(98.7% .022 95.277);--color-amber-100:oklch(96.2% .059 95.617);--color-amber-200:oklch(92.4% .12 95.746);--color-amber-600:oklch(66.6% .179 58.318);--color-amber-700:oklch(55.5% .163 48.998);--color-amber-800:oklch(47.3% .137 46.201);--color-amber-900:oklch(41.4% .112 45.904);--color-yellow-100:oklch(97.3% .071 103.193);--color-yellow-200:oklch(94.5% .129 101.54);--color-yellow-400:oklch(85.2% .199 91.936);--color-yellow-800:oklch(47.6% .114 61.907);--color-green-50:oklch(98.2% .018 155.826);--color-green-200:oklch(92.5% .084 155.995);--color-green-300:oklch(87.1% .15 154.449);--color-green-400:oklch(79.2% .209 151.711);--color-green-500:oklch(72.3% .219 149.579);--color-green-600:oklch(62.7% .194 149.214);--color-green-700:oklch(52.7% .154 150.069);--color-green-800:oklch(44.8% .119 151.328);--color-emerald-50:oklch(97.9% .021 166.113);--color-emerald-100:oklch(95% .052 163.051);--color-emerald-200:oklch(90.5% .093 164.15);--color-emerald-300:oklch(84.5% .143 164.978);--color-emerald-600:oklch(59.6% .145 163.225);--color-emerald-700:oklch(50.8% .118 165.612);--color-emerald-800:oklch(43.2% .095 166.913);--color-sky-500:oklch(68.5% .169 237.323);--color-sky-700:oklch(50% .134 242.749);--color-blue-50:oklch(97% .014 254.604);--color-blue-100:oklch(93.2% .032 255.585);--color-blue-500:oklch(62.3% .214 259.815);--color-blue-600:oklch(54.6% .245 262.881);--color-blue-800:oklch(42.4% .199 265.638);--color-blue-900:oklch(37.9% .146 265.522);--color-indigo-50:oklch(96.2% .018 272.314);--color-indigo-500:oklch(58.5% .233 277.117);--color-indigo-600:oklch(51.1% .262 276.966);--color-indigo-700:oklch(45.7% .24 277.023);--color-slate-500:oklch(55.4% .046 257.417);--color-slate-600:oklch(44.6% .043 257.281);--color-slate-700:oklch(37.2% .044 257.287);--color-gray-50:oklch(98.5% .002 247.839);--color-gray-100:oklch(96.7% .003 264.542);--color-gray-200:oklch(92.8% .006 264.531);--color-gray-300:oklch(87.2% .01 258.338);--color-gray-400:oklch(70.7% .022 261.325);--color-gray-500:oklch(55.1% .027 264.364);--color-gray-600:oklch(44.6% .03 256.802);--color-gray-700:oklch(37.3% .034 259.733);--color-gray-800:oklch(27.8% .033 256.848);--color-gray-900:oklch(21% .034 264.665);--color-zinc-50:oklch(98.5% 0 0);--color-zinc-600:oklch(44.2% .017 285.786);--color-zinc-800:oklch(27.4% .006 286.033);--color-zinc-900:oklch(21% .006 285.885);--color-black:#000;--color-white:#fff;--spacing:.25rem;--container-sm:24rem;--container-md:28rem;--container-lg:32rem;--container-xl:36rem;--container-2xl:42rem;--container-3xl:48rem;--container-4xl:56rem;--container-5xl:64rem;--container-6xl:72rem;--text-xs:.75rem;--text-xs--line-height:calc(1/.75);--text-sm:.875rem;--text-sm--line-height:calc(1.25/.875);--text-base:1rem;--text-base--line-height:calc(1.5/1);--text-lg:1.125rem;--text-lg--line-height:calc(1.75/1.125);--text-xl:1.25rem;--text-xl--line-height:calc(1.75/1.25);--text-2xl:1.5rem;--text-2xl--line-height:calc(2/1.5);--text-3xl:1.875rem;--text-3xl--line-height:calc(2.25/1.875);--text-4xl:2.25rem;--text-4xl--line-height:calc(2.5/2.25);--text-5xl:3rem;--text-5xl--line-height:1;--text-8xl:6rem;--text-8xl--line-height:1;--text-9xl:8rem;--text-9xl--line-height:1;--font-weight-normal:400;--font-weight-medium:500;--font-weight-semibold:600;--font-weight-bold:700;--font-weight-extrabold:800;--tracking-tighter:-.05em;--tracking-tight:-.025em;--tracking-normal:0em;--tracking-wide:.025em;--tracking-wider:.05em;--tracking-widest:.1em;--leading-tight:1.25;--leading-snug:1.375;--leading-relaxed:1.625;--radius-sm:.25rem;--radius-md:.375rem;--radius-lg:.5rem;--radius-xl:.75rem;--radius-2xl:1rem;--ease-in:cubic-bezier(.4,0,1,1);--ease-out:cubic-bezier(0,0,.2,1);--ease-in-out:cubic-bezier(.4,0,.2,1);--animate-spin:spin 1s linear infinite;--animate-pulse:pulse 2s cubic-bezier(.4,0,.6,1)infinite;--default-transition-duration:.15s;--default-transition-timing-function:cubic-bezier(.4,0,.2,1);--default-font-family:var(--font-sans);--default-mono-font-family:var(--font-mono);--color-on-surface:#3c4043;--color-on-surface-strong:#1f1f1f;--color-on-surface-variant:#5f6368;--color-on-surface-disabled:#9aa0a6;--color-surface:#fff;--color-surface-tint:#f8fafd;--color-surface-variant:#f1f3f4;--color-outline:#dadce0;--color-outline-variant:#e0e0e0;--color-primary:#1a73e8;--color-primary-strong:#0b57d0;--color-primary-hover:#1b66c9;--color-primary-container:#e8f0fe;--color-primary-container-alt:#d3e3fd;--color-success:#137333;--color-success-hover:#0f5c29;--color-success-container:#e6f4ea;--color-error:#c5221f;--color-error-hover:#a50e0e;--color-error-container:#fce8e6;--color-warning:#f57f17;--color-warning-container:#fff8e1;--color-surface-hover:#f8f9fa;--color-surface-muted:#ebebeb;--color-surface-variant-hover:#e8eaed;--color-surface-variant-deep:#e1e3e1;--color-on-surface-muted:#747775;--color-on-surface-soft:#444746;--color-on-surface-muted-strong:#858585;--color-file-link:#313848;--color-outline-strong:#c4c4c4;--color-outline-soft:#c4c7c5;--color-primary-soft:#1967d2;--color-primary-container-hover:#e9eef6;--color-warning-strong:#e37400;--color-warning-container-alt:#fef7e0;--color-warning-border:#f2de8a;--color-warning-on-container:#b06000;--color-error-container-border:#f9d2ce;--color-shadow-soft:#b8b8b8;--radius-panel:28px;--radius-card:8px;--breakpoint-comments:1245px;--spacing-header:3.5rem}}@layer base{*,:after,:before,::backdrop{box-sizing:border-box;border:0 solid;margin:0;padding:0}::file-selector-button{box-sizing:border-box;border:0 solid;margin:0;padding:0}html,:host{-webkit-text-size-adjust:100%;tab-size:4;line-height:1.5;font-family:var(--default-font-family,ui-sans-serif,system-ui,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol","Noto Color Emoji");font-feature-settings:var(--default-font-feature-settings,normal);font-variation-settings:var(--default-font-variation-settings,normal);-webkit-tap-highlight-color:transparent}hr{height:0;color:inherit;border-top-width:1px}abbr:where([title]){-webkit-text-decoration:underline dotted;text-decoration:underline dotted}h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit}a{color:inherit;-webkit-text-decoration:inherit;-webkit-text-decoration:inherit;-webkit-text-decoration:inherit;text-decoration:inherit}b,strong{font-weight:bolder}code,kbd,samp,pre{font-family:var(--default-mono-font-family,ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace);font-feature-settings:var(--default-mono-font-feature-settings,normal);font-variation-settings:var(--default-mono-font-variation-settings,normal);font-size:1em}small{font-size:80%}sub,sup{vertical-align:baseline;font-size:75%;line-height:0;position:relative}sub{bottom:-.25em}sup{top:-.5em}table{text-indent:0;border-color:inherit;border-collapse:collapse}:-moz-focusring{outline:auto}progress{vertical-align:baseline}summary{display:list-item}ol,ul,menu{list-style:none}img,svg,video,canvas,audio,iframe,embed,object{vertical-align:middle;display:block}img,video{max-width:100%;height:auto}button,input,select,optgroup,textarea{font:inherit;font-feature-settings:inherit;font-variation-settings:inherit;letter-spacing:inherit;color:inherit;opacity:1;background-color:#0000;border-radius:0}::file-selector-button{font:inherit;font-feature-settings:inherit;font-variation-settings:inherit;letter-spacing:inherit;color:inherit;opacity:1;background-color:#0000;border-radius:0}:where(select:is([multiple],[size])) optgroup{font-weight:bolder}:where(select:is([multiple],[size])) optgroup option{padding-inline-start:20px}::file-selector-button{margin-inline-end:4px}::placeholder{opacity:1}@supports (not ((-webkit-appearance:-apple-pay-button))) or (contain-intrinsic-size:1px){::placeholder{color:currentColor}@supports (color:color-mix(in lab, red, red)){::placeholder{color:color-mix(in oklab,currentcolor 50%,transparent)}}}textarea{resize:vertical}::-webkit-search-decoration{-webkit-appearance:none}::-webkit-date-and-time-value{min-height:1lh;text-align:inherit}::-webkit-datetime-edit{display:inline-flex}::-webkit-datetime-edit-fields-wrapper{padding:0}::-webkit-datetime-edit{padding-block:0}::-webkit-datetime-edit-year-field{padding-block:0}::-webkit-datetime-edit-month-field{padding-block:0}::-webkit-datetime-edit-day-field{padding-block:0}::-webkit-datetime-edit-hour-field{padding-block:0}::-webkit-datetime-edit-minute-field{padding-block:0}::-webkit-datetime-edit-second-field{padding-block:0}::-webkit-datetime-edit-millisecond-field{padding-block:0}::-webkit-datetime-edit-meridiem-field{padding-block:0}::-webkit-calendar-picker-indicator{line-height:1}:-moz-ui-invalid{box-shadow:none}button,input:where([type=button],[type=reset],[type=submit]){appearance:button}::file-selector-button{appearance:button}::-webkit-inner-spin-button{height:auto}::-webkit-outer-spin-button{height:auto}[hidden]:where(:not([hidden=until-found])){display:none!important}}@layer components;@layer utilities{.pointer-events-none{pointer-events:none}.collapse{visibility:collapse}.visible{visibility:visible}.sr-only{clip:rect(0,0,0,0);white-space:nowrap;border-width:0;width:1px;height:1px;margin:-1px;padding:0;position:absolute;overflow:hidden}.absolute{position:absolute}.fixed{position:fixed}.relative{position:relative}.static{position:static}.sticky{position:sticky}.inset-0{inset:calc(var(--spacing)*0)}.inset-y-0{inset-block:calc(var(--spacing)*0)}.-top-0\.5{top:calc(var(--spacing)*-.5)}.-top-4{top:calc(var(--spacing)*-4)}.-top-\[9px\]{top:-9px}.top-0{top:calc(var(--spacing)*0)}.top-1\/2{top:50%}.top-2{top:calc(var(--spacing)*2)}.top-3{top:calc(var(--spacing)*3)}.top-7{top:calc(var(--spacing)*7)}.top-full{top:100%}.top-header{top:var(--spacing-header)}.-right-0\.5{right:calc(var(--spacing)*-.5)}.right-0{right:calc(var(--spacing)*0)}.right-2{right:calc(var(--spacing)*2)}.right-3{right:calc(var(--spacing)*3)}.right-\[-18px\]{right:-18px}.right-\[-70px\]{right:-70px}.-bottom-0\.5{bottom:calc(var(--spacing)*-.5)}.bottom-0{bottom:calc(var(--spacing)*0)}.bottom-1\.5{bottom:calc(var(--spacing)*1.5)}.bottom-\[-42px\]{bottom:-42px}.bottom-\[-70px\]{bottom:-70px}.bottom-full{bottom:100%}.-left-12{left:calc(var(--spacing)*-12)}.left-0{left:calc(var(--spacing)*0)}.left-1\/2{left:50%}.left-3{left:calc(var(--spacing)*3)}.left-4{left:calc(var(--spacing)*4)}.left-5{left:calc(var(--spacing)*5)}.left-full{left:100%}.isolate{isolation:isolate}.z-0{z-index:0}.z-10{z-index:10}.z-20{z-index:20}.z-30{z-index:30}.z-40{z-index:40}.z-50{z-index:50}.z-\[60\]{z-index:60}.col-span-1{grid-column:span 1/span 1}.container{width:100%}@media (min-width:1245px){.container{max-width:1245px}}@media (min-width:40rem){.container{max-width:40rem}}@media (min-width:48rem){.container{max-width:48rem}}@media (min-width:64rem){.container{max-width:64rem}}@media (min-width:80rem){.container{max-width:80rem}}@media (min-width:96rem){.container{max-width:96rem}}.m-0{margin:calc(var(--spacing)*0)}.m-auto{margin:auto}.mx-0{margin-inline:calc(var(--spacing)*0)}.mx-2{margin-inline:calc(var(--spacing)*2)}.mx-8{margin-inline:calc(var(--spacing)*8)}.mx-auto{margin-inline:auto}.my-1{margin-block:calc(var(--spacing)*1)}.prose{color:var(--tw-prose-body);max-width:65ch}.prose :where(p):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.25em;margin-bottom:1.25em}.prose :where([class~=lead]):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-lead);margin-top:1.2em;margin-bottom:1.2em;font-size:1.25em;line-height:1.6}.prose :where(a):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-links);font-weight:500;text-decoration:underline}.prose :where(strong):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-bold);font-weight:600}.prose :where(a strong):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(blockquote strong):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(thead th strong):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit}.prose :where(ol):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.25em;margin-bottom:1.25em;padding-inline-start:1.625em;list-style-type:decimal}.prose :where(ol[type=A]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:upper-alpha}.prose :where(ol[type=a]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:lower-alpha}.prose :where(ol[type=A s]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:upper-alpha}.prose :where(ol[type=a s]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:lower-alpha}.prose :where(ol[type=I]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:upper-roman}.prose :where(ol[type=i]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:lower-roman}.prose :where(ol[type=I s]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:upper-roman}.prose :where(ol[type=i s]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:lower-roman}.prose :where(ol[type="1"]):not(:where([class~=not-prose],[class~=not-prose] *)){list-style-type:decimal}.prose :where(ul):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.25em;margin-bottom:1.25em;padding-inline-start:1.625em;list-style-type:disc}.prose :where(ol>li):not(:where([class~=not-prose],[class~=not-prose] *))::marker{color:var(--tw-prose-counters);font-weight:400}.prose :where(ul>li):not(:where([class~=not-prose],[class~=not-prose] *))::marker{color:var(--tw-prose-bullets)}.prose :where(dt):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-headings);margin-top:1.25em;font-weight:600}.prose :where(hr):not(:where([class~=not-prose],[class~=not-prose] *)){border-color:var(--tw-prose-hr);border-top-width:1px;margin-top:3em;margin-bottom:3em}.prose :where(blockquote):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-quotes);border-inline-start-width:.25rem;border-inline-start-color:var(--tw-prose-quote-borders);quotes:"“""”""‘""’";margin-top:1.6em;margin-bottom:1.6em;padding-inline-start:1em;font-style:italic;font-weight:500}.prose :where(blockquote p:first-of-type):not(:where([class~=not-prose],[class~=not-prose] *)):before{content:open-quote}.prose :where(blockquote p:last-of-type):not(:where([class~=not-prose],[class~=not-prose] *)):after{content:close-quote}.prose :where(h1):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-headings);margin-top:0;margin-bottom:.888889em;font-size:2.25em;font-weight:800;line-height:1.11111}.prose :where(h1 strong):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit;font-weight:900}.prose :where(h2):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-headings);margin-top:2em;margin-bottom:1em;font-size:1.5em;font-weight:700;line-height:1.33333}.prose :where(h2 strong):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit;font-weight:800}.prose :where(h3):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-headings);margin-top:1.6em;margin-bottom:.6em;font-size:1.25em;font-weight:600;line-height:1.6}.prose :where(h3 strong):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit;font-weight:700}.prose :where(h4):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-headings);margin-top:1.5em;margin-bottom:.5em;font-weight:600;line-height:1.5}.prose :where(h4 strong):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit;font-weight:700}.prose :where(img):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:2em;margin-bottom:2em}.prose :where(picture):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:2em;margin-bottom:2em;display:block}.prose :where(video):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:2em;margin-bottom:2em}.prose :where(kbd):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-kbd);box-shadow:0 0 0 1px rgb(var(--tw-prose-kbd-shadows)/10%),0 3px 0 rgb(var(--tw-prose-kbd-shadows)/10%);padding-top:.1875em;padding-inline-end:.375em;padding-bottom:.1875em;border-radius:.3125rem;padding-inline-start:.375em;font-family:inherit;font-size:.875em;font-weight:500}.prose :where(code):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-code);font-size:.875em;font-weight:600}.prose :where(code):not(:where([class~=not-prose],[class~=not-prose] *)):before,.prose :where(code):not(:where([class~=not-prose],[class~=not-prose] *)):after{content:"`"}.prose :where(a code):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(h1 code):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit}.prose :where(h2 code):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit;font-size:.875em}.prose :where(h3 code):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit;font-size:.9em}.prose :where(h4 code):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(blockquote code):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(thead th code):not(:where([class~=not-prose],[class~=not-prose] *)){color:inherit}.prose :where(pre):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-pre-code);background-color:var(--tw-prose-pre-bg);padding-top:.857143em;padding-inline-end:1.14286em;padding-bottom:.857143em;border-radius:.375rem;margin-top:1.71429em;margin-bottom:1.71429em;padding-inline-start:1.14286em;font-size:.875em;font-weight:400;line-height:1.71429;overflow-x:auto}.prose :where(pre code):not(:where([class~=not-prose],[class~=not-prose] *)){font-weight:inherit;color:inherit;font-size:inherit;font-family:inherit;line-height:inherit;background-color:#0000;border-width:0;border-radius:0;padding:0}.prose :where(pre code):not(:where([class~=not-prose],[class~=not-prose] *)):before,.prose :where(pre code):not(:where([class~=not-prose],[class~=not-prose] *)):after{content:none}.prose :where(table):not(:where([class~=not-prose],[class~=not-prose] *)){table-layout:auto;width:100%;margin-top:2em;margin-bottom:2em;font-size:.875em;line-height:1.71429}.prose :where(thead):not(:where([class~=not-prose],[class~=not-prose] *)){border-bottom-width:1px;border-bottom-color:var(--tw-prose-th-borders)}.prose :where(thead th):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-headings);vertical-align:bottom;padding-inline-end:.571429em;padding-bottom:.571429em;padding-inline-start:.571429em;font-weight:600}.prose :where(tbody tr):not(:where([class~=not-prose],[class~=not-prose] *)){border-bottom-width:1px;border-bottom-color:var(--tw-prose-td-borders)}.prose :where(tbody tr:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){border-bottom-width:0}.prose :where(tbody td):not(:where([class~=not-prose],[class~=not-prose] *)){vertical-align:baseline}.prose :where(tfoot):not(:where([class~=not-prose],[class~=not-prose] *)){border-top-width:1px;border-top-color:var(--tw-prose-th-borders)}.prose :where(tfoot td):not(:where([class~=not-prose],[class~=not-prose] *)){vertical-align:top}.prose :where(th,td):not(:where([class~=not-prose],[class~=not-prose] *)){text-align:start}.prose :where(figure>*):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0;margin-bottom:0}.prose :where(figcaption):not(:where([class~=not-prose],[class~=not-prose] *)){color:var(--tw-prose-captions);margin-top:.857143em;font-size:.875em;line-height:1.42857}.prose{--tw-prose-body:oklch(37.3% .034 259.733);--tw-prose-headings:oklch(21% .034 264.665);--tw-prose-lead:oklch(44.6% .03 256.802);--tw-prose-links:oklch(21% .034 264.665);--tw-prose-bold:oklch(21% .034 264.665);--tw-prose-counters:oklch(55.1% .027 264.364);--tw-prose-bullets:oklch(87.2% .01 258.338);--tw-prose-hr:oklch(92.8% .006 264.531);--tw-prose-quotes:oklch(21% .034 264.665);--tw-prose-quote-borders:oklch(92.8% .006 264.531);--tw-prose-captions:oklch(55.1% .027 264.364);--tw-prose-kbd:oklch(21% .034 264.665);--tw-prose-kbd-shadows:NaN NaN NaN;--tw-prose-code:oklch(21% .034 264.665);--tw-prose-pre-code:oklch(92.8% .006 264.531);--tw-prose-pre-bg:oklch(27.8% .033 256.848);--tw-prose-th-borders:oklch(87.2% .01 258.338);--tw-prose-td-borders:oklch(92.8% .006 264.531);--tw-prose-invert-body:oklch(87.2% .01 258.338);--tw-prose-invert-headings:#fff;--tw-prose-invert-lead:oklch(70.7% .022 261.325);--tw-prose-invert-links:#fff;--tw-prose-invert-bold:#fff;--tw-prose-invert-counters:oklch(70.7% .022 261.325);--tw-prose-invert-bullets:oklch(44.6% .03 256.802);--tw-prose-invert-hr:oklch(37.3% .034 259.733);--tw-prose-invert-quotes:oklch(96.7% .003 264.542);--tw-prose-invert-quote-borders:oklch(37.3% .034 259.733);--tw-prose-invert-captions:oklch(70.7% .022 261.325);--tw-prose-invert-kbd:#fff;--tw-prose-invert-kbd-shadows:255 255 255;--tw-prose-invert-code:#fff;--tw-prose-invert-pre-code:oklch(87.2% .01 258.338);--tw-prose-invert-pre-bg:#00000080;--tw-prose-invert-th-borders:oklch(44.6% .03 256.802);--tw-prose-invert-td-borders:oklch(37.3% .034 259.733);font-size:1rem;line-height:1.75}.prose :where(picture>img):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0;margin-bottom:0}.prose :where(li):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.5em;margin-bottom:.5em}.prose :where(ol>li):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(ul>li):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-start:.375em}.prose :where(.prose>ul>li p):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.75em;margin-bottom:.75em}.prose :where(.prose>ul>li>p:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.25em}.prose :where(.prose>ul>li>p:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-bottom:1.25em}.prose :where(.prose>ol>li>p:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.25em}.prose :where(.prose>ol>li>p:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-bottom:1.25em}.prose :where(ul ul,ul ol,ol ul,ol ol):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.75em;margin-bottom:.75em}.prose :where(dl):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.25em;margin-bottom:1.25em}.prose :where(dd):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.5em;padding-inline-start:1.625em}.prose :where(hr+*):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(h2+*):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(h3+*):not(:where([class~=not-prose],[class~=not-prose] *)),.prose :where(h4+*):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0}.prose :where(thead th:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-start:0}.prose :where(thead th:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-end:0}.prose :where(tbody td,tfoot td):not(:where([class~=not-prose],[class~=not-prose] *)){padding-top:.571429em;padding-inline-end:.571429em;padding-bottom:.571429em;padding-inline-start:.571429em}.prose :where(tbody td:first-child,tfoot td:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-start:0}.prose :where(tbody td:last-child,tfoot td:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-end:0}.prose :where(figure):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:2em;margin-bottom:2em}.prose :where(.prose>:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0}.prose :where(.prose>:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-bottom:0}.prose-sm{font-size:.875rem;line-height:1.71429}.prose-sm :where(p):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.14286em;margin-bottom:1.14286em}.prose-sm :where([class~=lead]):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.888889em;margin-bottom:.888889em;font-size:1.28571em;line-height:1.55556}.prose-sm :where(blockquote):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.33333em;margin-bottom:1.33333em;padding-inline-start:1.11111em}.prose-sm :where(h1):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0;margin-bottom:.8em;font-size:2.14286em;line-height:1.2}.prose-sm :where(h2):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.6em;margin-bottom:.8em;font-size:1.42857em;line-height:1.4}.prose-sm :where(h3):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.55556em;margin-bottom:.444444em;font-size:1.28571em;line-height:1.55556}.prose-sm :where(h4):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.42857em;margin-bottom:.571429em;line-height:1.42857}.prose-sm :where(img):not(:where([class~=not-prose],[class~=not-prose] *)),.prose-sm :where(picture):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.71429em;margin-bottom:1.71429em}.prose-sm :where(picture>img):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0;margin-bottom:0}.prose-sm :where(video):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.71429em;margin-bottom:1.71429em}.prose-sm :where(kbd):not(:where([class~=not-prose],[class~=not-prose] *)){padding-top:.142857em;padding-inline-end:.357143em;padding-bottom:.142857em;border-radius:.3125rem;padding-inline-start:.357143em;font-size:.857143em}.prose-sm :where(code):not(:where([class~=not-prose],[class~=not-prose] *)){font-size:.857143em}.prose-sm :where(h2 code):not(:where([class~=not-prose],[class~=not-prose] *)){font-size:.9em}.prose-sm :where(h3 code):not(:where([class~=not-prose],[class~=not-prose] *)){font-size:.888889em}.prose-sm :where(pre):not(:where([class~=not-prose],[class~=not-prose] *)){padding-top:.666667em;padding-inline-end:1em;padding-bottom:.666667em;border-radius:.25rem;margin-top:1.66667em;margin-bottom:1.66667em;padding-inline-start:1em;font-size:.857143em;line-height:1.66667}.prose-sm :where(ol):not(:where([class~=not-prose],[class~=not-prose] *)),.prose-sm :where(ul):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.14286em;margin-bottom:1.14286em;padding-inline-start:1.57143em}.prose-sm :where(li):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.285714em;margin-bottom:.285714em}.prose-sm :where(ol>li):not(:where([class~=not-prose],[class~=not-prose] *)),.prose-sm :where(ul>li):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-start:.428571em}.prose-sm :where(.prose-sm>ul>li p):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.571429em;margin-bottom:.571429em}.prose-sm :where(.prose-sm>ul>li>p:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.14286em}.prose-sm :where(.prose-sm>ul>li>p:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-bottom:1.14286em}.prose-sm :where(.prose-sm>ol>li>p:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.14286em}.prose-sm :where(.prose-sm>ol>li>p:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-bottom:1.14286em}.prose-sm :where(ul ul,ul ol,ol ul,ol ol):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.571429em;margin-bottom:.571429em}.prose-sm :where(dl):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.14286em;margin-bottom:1.14286em}.prose-sm :where(dt):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.14286em}.prose-sm :where(dd):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.285714em;padding-inline-start:1.57143em}.prose-sm :where(hr):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:2.85714em;margin-bottom:2.85714em}.prose-sm :where(hr+*):not(:where([class~=not-prose],[class~=not-prose] *)),.prose-sm :where(h2+*):not(:where([class~=not-prose],[class~=not-prose] *)),.prose-sm :where(h3+*):not(:where([class~=not-prose],[class~=not-prose] *)),.prose-sm :where(h4+*):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0}.prose-sm :where(table):not(:where([class~=not-prose],[class~=not-prose] *)){font-size:.857143em;line-height:1.5}.prose-sm :where(thead th):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-end:1em;padding-bottom:.666667em;padding-inline-start:1em}.prose-sm :where(thead th:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-start:0}.prose-sm :where(thead th:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-end:0}.prose-sm :where(tbody td,tfoot td):not(:where([class~=not-prose],[class~=not-prose] *)){padding-top:.666667em;padding-inline-end:1em;padding-bottom:.666667em;padding-inline-start:1em}.prose-sm :where(tbody td:first-child,tfoot td:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-start:0}.prose-sm :where(tbody td:last-child,tfoot td:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){padding-inline-end:0}.prose-sm :where(figure):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:1.71429em;margin-bottom:1.71429em}.prose-sm :where(figure>*):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0;margin-bottom:0}.prose-sm :where(figcaption):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:.666667em;font-size:.857143em;line-height:1.33333}.prose-sm :where(.prose-sm>:first-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-top:0}.prose-sm :where(.prose-sm>:last-child):not(:where([class~=not-prose],[class~=not-prose] *)){margin-bottom:0}.-mt-12{margin-top:calc(var(--spacing)*-12)}.mt-0{margin-top:calc(var(--spacing)*0)}.mt-0\.5{margin-top:calc(var(--spacing)*.5)}.mt-1{margin-top:calc(var(--spacing)*1)}.mt-1\.5{margin-top:calc(var(--spacing)*1.5)}.mt-2{margin-top:calc(var(--spacing)*2)}.mt-2\.5{margin-top:calc(var(--spacing)*2.5)}.mt-3{margin-top:calc(var(--spacing)*3)}.mt-4{margin-top:calc(var(--spacing)*4)}.mt-5{margin-top:calc(var(--spacing)*5)}.mt-6{margin-top:calc(var(--spacing)*6)}.mt-8{margin-top:calc(var(--spacing)*8)}.mt-10{margin-top:calc(var(--spacing)*10)}.mt-auto{margin-top:auto}.mr-1\.5{margin-right:calc(var(--spacing)*1.5)}.mr-2{margin-right:calc(var(--spacing)*2)}.mr-3{margin-right:calc(var(--spacing)*3)}.mb-0{margin-bottom:calc(var(--spacing)*0)}.mb-0\.5{margin-bottom:calc(var(--spacing)*.5)}.mb-1{margin-bottom:calc(var(--spacing)*1)}.mb-1\.5{margin-bottom:calc(var(--spacing)*1.5)}.mb-2{margin-bottom:calc(var(--spacing)*2)}.mb-2\.5{margin-bottom:calc(var(--spacing)*2.5)}.mb-3{margin-bottom:calc(var(--spacing)*3)}.mb-4{margin-bottom:calc(var(--spacing)*4)}.mb-5{margin-bottom:calc(var(--spacing)*5)}.mb-6{margin-bottom:calc(var(--spacing)*6)}.mb-8{margin-bottom:calc(var(--spacing)*8)}.mb-10{margin-bottom:calc(var(--spacing)*10)}.mb-12{margin-bottom:calc(var(--spacing)*12)}.mb-14{margin-bottom:calc(var(--spacing)*14)}.mb-\[20px\]{margin-bottom:20px}.-ml-1\.5{margin-left:calc(var(--spacing)*-1.5)}.-ml-2{margin-left:calc(var(--spacing)*-2)}.ml-1{margin-left:calc(var(--spacing)*1)}.ml-2{margin-left:calc(var(--spacing)*2)}.ml-3{margin-left:calc(var(--spacing)*3)}.ml-4{margin-left:calc(var(--spacing)*4)}.ml-10{margin-left:calc(var(--spacing)*10)}.ml-14{margin-left:calc(var(--spacing)*14)}.ml-auto{margin-left:auto}.box-border{box-sizing:border-box}.line-clamp-3{-webkit-line-clamp:3;-webkit-box-orient:vertical;display:-webkit-box;overflow:hidden}.block{display:block}.flex{display:flex}.grid{display:grid}.hidden{display:none}.inline{display:inline}.inline-block{display:inline-block}.inline-flex{display:inline-flex}.table{display:table}.table-cell{display:table-cell}.\[field-sizing\:content\]{field-sizing:content}.h-1\.5{height:calc(var(--spacing)*1.5)}.h-2{height:calc(var(--spacing)*2)}.h-2\.5{height:calc(var(--spacing)*2.5)}.h-3{height:calc(var(--spacing)*3)}.h-4{height:calc(var(--spacing)*4)}.h-5{height:calc(var(--spacing)*5)}.h-6{height:calc(var(--spacing)*6)}.h-7{height:calc(var(--spacing)*7)}.h-8{height:calc(var(--spacing)*8)}.h-9{height:calc(var(--spacing)*9)}.h-10{height:calc(var(--spacing)*10)}.h-14{height:calc(var(--spacing)*14)}.h-16{height:calc(var(--spacing)*16)}.h-24{height:calc(var(--spacing)*24)}.h-32{height:calc(var(--spacing)*32)}.h-\[3px\]{height:3px}.h-\[3rem\]{height:3rem}.h-\[18px\]{height:18px}.h-\[22px\]{height:22px}.h-\[26px\]{height:26px}.h-\[36px\]{height:36px}.h-\[180px\]{height:180px}.h-\[260px\]{height:260px}.h-\[600px\]{height:600px}.h-\[calc\(100vh-var\(--spacing-header\)\)\]{height:calc(100vh - var(--spacing-header))}.h-auto{height:auto}.h-full{height:100%}.h-header{height:var(--spacing-header)}.max-h-64{max-height:calc(var(--spacing)*64)}.max-h-\[60vh\]{max-height:60vh}.max-h-\[75vh\]{max-height:75vh}.max-h-\[80vh\]{max-height:80vh}.max-h-\[85dvh\]{max-height:85dvh}.max-h-\[85vh\]{max-height:85vh}.max-h-\[320px\]{max-height:320px}.min-h-0{min-height:calc(var(--spacing)*0)}.min-h-8{min-height:calc(var(--spacing)*8)}.min-h-\[62px\]{min-height:62px}.min-h-\[80vh\]{min-height:80vh}.min-h-\[85vh\]{min-height:85vh}.min-h-\[240px\]{min-height:240px}.min-h-\[300px\]{min-height:300px}.min-h-\[calc\(100vh-70px\)\]{min-height:calc(100vh - 70px)}.min-h-full{min-height:100%}.min-h-header{min-height:var(--spacing-header)}.min-h-screen{min-height:100vh}.w-1\.5{width:calc(var(--spacing)*1.5)}.w-2{width:calc(var(--spacing)*2)}.w-2\.5{width:calc(var(--spacing)*2.5)}.w-3{width:calc(var(--spacing)*3)}.w-4{width:calc(var(--spacing)*4)}.w-5{width:calc(var(--spacing)*5)}.w-6{width:calc(var(--spacing)*6)}.w-7{width:calc(var(--spacing)*7)}.w-8{width:calc(var(--spacing)*8)}.w-9{width:calc(var(--spacing)*9)}.w-9\/12{width:75%}.w-10{width:calc(var(--spacing)*10)}.w-11{width:calc(var(--spacing)*11)}.w-16{width:calc(var(--spacing)*16)}.w-20{width:calc(var(--spacing)*20)}.w-24{width:calc(var(--spacing)*24)}.w-36{width:calc(var(--spacing)*36)}.w-40{width:calc(var(--spacing)*40)}.w-56{width:calc(var(--spacing)*56)}.w-72{width:calc(var(--spacing)*72)}.w-\[1px\]{width:1px}.w-\[2\.5rem\]{width:2.5rem}.w-\[3rem\]{width:3rem}.w-\[4\%\]{width:4%}.w-\[7\%\]{width:7%}.w-\[8\%\]{width:8%}.w-\[10em\]{width:10em}.w-\[13\%\]{width:13%}.w-\[15\%\]{width:15%}.w-\[17\%\]{width:17%}.w-\[18px\]{width:18px}.w-\[20\%\]{width:20%}.w-\[22px\]{width:22px}.w-\[26px\]{width:26px}.w-\[27\%\]{width:27%}.w-\[30\%\]{width:30%}.w-\[31\%\]{width:31%}.w-\[36px\]{width:36px}.w-\[38\%\]{width:38%}.w-\[95\%\]{width:95%}.w-\[230px\]{width:230px}.w-\[280px\]{width:280px}.w-\[360px\]{width:360px}.w-\[380px\]{width:380px}.w-\[420px\]{width:420px}.w-\[calc\(100\%-4rem\)\]{width:calc(100% - 4rem)}.w-auto{width:auto}.w-fit{width:fit-content}.w-full{width:100%}.w-px{width:1px}.max-w-3xl{max-width:var(--container-3xl)}.max-w-4xl{max-width:var(--container-4xl)}.max-w-5xl{max-width:var(--container-5xl)}.max-w-6xl{max-width:var(--container-6xl)}.max-w-\[62\%\]{max-width:62%}.max-w-\[78\%\]{max-width:78%}.max-w-\[90vw\]{max-width:90vw}.max-w-\[280px\]{max-width:280px}.max-w-\[360px\]{max-width:360px}.max-w-\[720px\]{max-width:720px}.max-w-\[800px\]{max-width:800px}.max-w-\[calc\(100vw-2rem\)\]{max-width:calc(100vw - 2rem)}.max-w-fit{max-width:fit-content}.max-w-full{max-width:100%}.max-w-lg{max-width:var(--container-lg)}.max-w-md{max-width:var(--container-md)}.max-w-none{max-width:none}.max-w-sm{max-width:var(--container-sm)}.max-w-xl{max-width:var(--container-xl)}.min-w-0{min-width:calc(var(--spacing)*0)}.min-w-4{min-width:calc(var(--spacing)*4)}.min-w-\[1\.25rem\]{min-width:1.25rem}.min-w-\[150px\]{min-width:150px}.min-w-\[180px\]{min-width:180px}.min-w-\[300px\]{min-width:300px}.min-w-\[480px\]{min-width:480px}.min-w-\[650px\]{min-width:650px}.min-w-\[1152px\]{min-width:1152px}.min-w-full{min-width:100%}.flex-1{flex:1}.flex-auto{flex:auto}.flex-none{flex:none}.flex-shrink-0,.shrink-0{flex-shrink:0}.flex-grow{flex-grow:1}.table-fixed{table-layout:fixed}.origin-bottom{transform-origin:bottom}.origin-top-right{transform-origin:100% 0}.-translate-x-1\/2{--tw-translate-x:calc(calc(1/2*100%)*-1);translate:var(--tw-translate-x)var(--tw-translate-y)}.-translate-x-full{--tw-translate-x:-100%;translate:var(--tw-translate-x)var(--tw-translate-y)}.translate-x-full{--tw-translate-x:100%;translate:var(--tw-translate-x)var(--tw-translate-y)}.-translate-y-1\/2{--tw-translate-y:calc(calc(1/2*100%)*-1);translate:var(--tw-translate-x)var(--tw-translate-y)}.translate-y-full{--tw-translate-y:100%;translate:var(--tw-translate-x)var(--tw-translate-y)}.rotate-180{rotate:180deg}.transform{transform:var(--tw-rotate-x,)var(--tw-rotate-y,)var(--tw-rotate-z,)var(--tw-skew-x,)var(--tw-skew-y,)}.animate-pulse{animation:var(--animate-pulse)}.animate-spin{animation:var(--animate-spin)}.cursor-default{cursor:default}.cursor-grab{cursor:grab}.cursor-not-allowed{cursor:not-allowed}.cursor-pointer{cursor:pointer}.resize{resize:both}.resize-none{resize:none}.list-inside{list-style-position:inside}.list-outside{list-style-position:outside}.list-decimal{list-style-type:decimal}.list-disc{list-style-type:disc}.list-none{list-style-type:none}.appearance-none{appearance:none}.grid-cols-1{grid-template-columns:repeat(1,minmax(0,1fr))}.grid-cols-2{grid-template-columns:repeat(2,minmax(0,1fr))}.flex-col{flex-direction:column}.flex-row{flex-direction:row}.flex-nowrap{flex-wrap:nowrap}.flex-wrap{flex-wrap:wrap}.items-baseline{align-items:baseline}.items-center{align-items:center}.items-end{align-items:flex-end}.items-start{align-items:flex-start}.justify-between{justify-content:space-between}.justify-center{justify-content:center}.justify-end{justify-content:flex-end}.justify-start{justify-content:flex-start}.gap-1{gap:calc(var(--spacing)*1)}.gap-1\.5{gap:calc(var(--spacing)*1.5)}.gap-2{gap:calc(var(--spacing)*2)}.gap-2\.5{gap:calc(var(--spacing)*2.5)}.gap-3{gap:calc(var(--spacing)*3)}.gap-4{gap:calc(var(--spacing)*4)}.gap-5{gap:calc(var(--spacing)*5)}.gap-6{gap:calc(var(--spacing)*6)}.gap-8{gap:calc(var(--spacing)*8)}:where(.space-y-0\.5>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*.5)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*.5)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-1>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*1)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*1)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-1\.5>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*1.5)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*1.5)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-3>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*3)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*3)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-4>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*4)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*4)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-5>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*5)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*5)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-6>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*6)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*6)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-8>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*8)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*8)*calc(1 - var(--tw-space-y-reverse)))}:where(.space-y-12>:not(:last-child)){--tw-space-y-reverse:0;margin-block-start:calc(calc(var(--spacing)*12)*var(--tw-space-y-reverse));margin-block-end:calc(calc(var(--spacing)*12)*calc(1 - var(--tw-space-y-reverse)))}.gap-x-2{column-gap:calc(var(--spacing)*2)}.gap-x-4{column-gap:calc(var(--spacing)*4)}.gap-x-6{column-gap:calc(var(--spacing)*6)}.gap-x-8{column-gap:calc(var(--spacing)*8)}.gap-x-12{column-gap:calc(var(--spacing)*12)}:where(.-space-x-1\.5>:not(:last-child)){--tw-space-x-reverse:0;margin-inline-start:calc(calc(var(--spacing)*-1.5)*var(--tw-space-x-reverse));margin-inline-end:calc(calc(var(--spacing)*-1.5)*calc(1 - var(--tw-space-x-reverse)))}.gap-y-2{row-gap:calc(var(--spacing)*2)}.gap-y-3{row-gap:calc(var(--spacing)*3)}.gap-y-8{row-gap:calc(var(--spacing)*8)}:where(.divide-y>:not(:last-child)){--tw-divide-y-reverse:0;border-bottom-style:var(--tw-border-style);border-top-style:var(--tw-border-style);border-top-width:calc(1px*var(--tw-divide-y-reverse));border-bottom-width:calc(1px*calc(1 - var(--tw-divide-y-reverse)))}:where(.divide-gray-100>:not(:last-child)){border-color:var(--color-gray-100)}:where(.divide-gray-200>:not(:last-child)){border-color:var(--color-gray-200)}:where(.divide-outline-variant>:not(:last-child)){border-color:var(--color-outline-variant)}.self-start{align-self:flex-start}.self-stretch{align-self:stretch}.truncate{text-overflow:ellipsis;white-space:nowrap;overflow:hidden}.overflow-hidden{overflow:hidden}.overflow-visible{overflow:visible}.overflow-x-auto{overflow-x:auto}.overflow-x-hidden{overflow-x:hidden}.overflow-y-auto{overflow-y:auto}.rounded{border-radius:.25rem}.rounded-2xl{border-radius:var(--radius-2xl)}.rounded-\[3px\]{border-radius:3px}.rounded-\[4px\]{border-radius:4px}.rounded-\[6px\]{border-radius:6px}.rounded-\[8px\]{border-radius:8px}.rounded-\[10px\]{border-radius:10px}.rounded-\[12px\]{border-radius:12px}.rounded-\[28px\]{border-radius:28px}.rounded-card{border-radius:var(--radius-card)}.rounded-full{border-radius:3.40282e38px}.rounded-lg{border-radius:var(--radius-lg)}.rounded-md{border-radius:var(--radius-md)}.rounded-panel{border-radius:var(--radius-panel)}.rounded-xl{border-radius:var(--radius-xl)}.rounded-t-\[3px\]{border-top-left-radius:3px;border-top-right-radius:3px}.rounded-t-\[4px\]{border-top-left-radius:4px;border-top-right-radius:4px}.rounded-t-xl{border-top-left-radius:var(--radius-xl);border-top-right-radius:var(--radius-xl)}.rounded-l-full{border-top-left-radius:3.40282e38px;border-bottom-left-radius:3.40282e38px}.rounded-l-sm{border-top-left-radius:var(--radius-sm);border-bottom-left-radius:var(--radius-sm)}.rounded-tl-panel{border-top-left-radius:var(--radius-panel)}.rounded-r-full{border-top-right-radius:3.40282e38px;border-bottom-right-radius:3.40282e38px}.rounded-r-lg{border-top-right-radius:var(--radius-lg);border-bottom-right-radius:var(--radius-lg)}.rounded-r-xl{border-top-right-radius:var(--radius-xl);border-bottom-right-radius:var(--radius-xl)}.rounded-b-\[8px\]{border-bottom-right-radius:8px;border-bottom-left-radius:8px}.rounded-b-lg{border-bottom-right-radius:var(--radius-lg);border-bottom-left-radius:var(--radius-lg)}.rounded-b-xl{border-bottom-right-radius:var(--radius-xl);border-bottom-left-radius:var(--radius-xl)}.border{border-style:var(--tw-border-style);border-width:1px}.border-0{border-style:var(--tw-border-style);border-width:0}.border-1{border-style:var(--tw-border-style);border-width:1px}.border-2{border-style:var(--tw-border-style);border-width:2px}.border-4{border-style:var(--tw-border-style);border-width:4px}.border-\[3px\]{border-style:var(--tw-border-style);border-width:3px}.border-t{border-top-style:var(--tw-border-style);border-top-width:1px}.border-r{border-right-style:var(--tw-border-style);border-right-width:1px}.border-b{border-bottom-style:var(--tw-border-style);border-bottom-width:1px}.border-b-2{border-bottom-style:var(--tw-border-style);border-bottom-width:2px}.border-l{border-left-style:var(--tw-border-style);border-left-width:1px}.border-l-4{border-left-style:var(--tw-border-style);border-left-width:4px}.border-dashed{--tw-border-style:dashed;border-style:dashed}.border-none{--tw-border-style:none;border-style:none}.border-\[\#1A73E8\]{border-color:#1a73e8}.border-\[\#DADCE0\]{border-color:#dadce0}.border-\[\#E0E0E0\]{border-color:#e0e0e0}.border-\[\#ccc\]{border-color:#ccc}.border-amber-200{border-color:var(--color-amber-200)}.border-blue-100{border-color:var(--color-blue-100)}.border-emerald-200{border-color:var(--color-emerald-200)}.border-emerald-300{border-color:var(--color-emerald-300)}.border-error-container-border{border-color:var(--color-error-container-border)}.border-gray-100{border-color:var(--color-gray-100)}.border-gray-200{border-color:var(--color-gray-200)}.border-gray-300{border-color:var(--color-gray-300)}.border-gray-400{border-color:var(--color-gray-400)}.border-green-200{border-color:var(--color-green-200)}.border-green-500{border-color:var(--color-green-500)}.border-on-surface-muted{border-color:var(--color-on-surface-muted)}.border-on-surface-variant{border-color:var(--color-on-surface-variant)}.border-outline{border-color:var(--color-outline)}.border-outline-soft{border-color:var(--color-outline-soft)}.border-outline-variant{border-color:var(--color-outline-variant)}.border-primary{border-color:var(--color-primary)}.border-red-100{border-color:var(--color-red-100)}.border-red-200{border-color:var(--color-red-200)}.border-red-500{border-color:var(--color-red-500)}.border-surface-tint{border-color:var(--color-surface-tint)}.border-transparent{border-color:#0000}.border-warning-border{border-color:var(--color-warning-border)}.border-white{border-color:var(--color-white)}.border-yellow-200{border-color:var(--color-yellow-200)}.border-l-emerald-600{border-left-color:var(--color-emerald-600)}.border-l-gray-400{border-left-color:var(--color-gray-400)}.border-l-red-400{border-left-color:var(--color-red-400)}.bg-\[\#1A73E8\]{background-color:#1a73e8}.bg-\[\#1F78D1\]{background-color:#1f78d1}.bg-\[\#d9d9d9\]{background-color:#d9d9d9}.bg-\[\#dfdfdf\]{background-color:#dfdfdf}.bg-\[\#efefef\]{background-color:#efefef}.bg-\[\#f8f9fa\]{background-color:#f8f9fa}.bg-amber-50{background-color:var(--color-amber-50)}.bg-amber-50\/60{background-color:#fffbeb99}@supports (color:color-mix(in lab, red, red)){.bg-amber-50\/60{background-color:color-mix(in oklab,var(--color-amber-50)60%,transparent)}}.bg-amber-100{background-color:var(--color-amber-100)}.bg-amber-600{background-color:var(--color-amber-600)}.bg-black{background-color:var(--color-black)}.bg-black\/30{background-color:#0000004d}@supports (color:color-mix(in lab, red, red)){.bg-black\/30{background-color:color-mix(in oklab,var(--color-black)30%,transparent)}}.bg-black\/40{background-color:#0006}@supports (color:color-mix(in lab, red, red)){.bg-black\/40{background-color:color-mix(in oklab,var(--color-black)40%,transparent)}}.bg-black\/50{background-color:#00000080}@supports (color:color-mix(in lab, red, red)){.bg-black\/50{background-color:color-mix(in oklab,var(--color-black)50%,transparent)}}.bg-blue-50\/50{background-color:#eff6ff80}@supports (color:color-mix(in lab, red, red)){.bg-blue-50\/50{background-color:color-mix(in oklab,var(--color-blue-50)50%,transparent)}}.bg-emerald-50{background-color:var(--color-emerald-50)}.bg-emerald-600{background-color:var(--color-emerald-600)}.bg-error{background-color:var(--color-error)}.bg-error-container{background-color:var(--color-error-container)}.bg-gray-50{background-color:var(--color-gray-50)}.bg-gray-50\/30{background-color:#f9fafb4d}@supports (color:color-mix(in lab, red, red)){.bg-gray-50\/30{background-color:color-mix(in oklab,var(--color-gray-50)30%,transparent)}}.bg-gray-100{background-color:var(--color-gray-100)}.bg-gray-200{background-color:var(--color-gray-200)}.bg-gray-400{background-color:var(--color-gray-400)}.bg-gray-500{background-color:var(--color-gray-500)}.bg-gray-600{background-color:var(--color-gray-600)}.bg-green-50{background-color:var(--color-green-50)}.bg-green-400{background-color:var(--color-green-400)}.bg-green-500{background-color:var(--color-green-500)}.bg-indigo-50{background-color:var(--color-indigo-50)}.bg-indigo-600{background-color:var(--color-indigo-600)}.bg-outline{background-color:var(--color-outline)}.bg-outline-variant{background-color:var(--color-outline-variant)}.bg-primary{background-color:var(--color-primary)}.bg-primary-container{background-color:var(--color-primary-container)}.bg-primary-container-alt{background-color:var(--color-primary-container-alt)}.bg-primary-container\/40{background-color:#e8f0fe66}@supports (color:color-mix(in lab, red, red)){.bg-primary-container\/40{background-color:color-mix(in oklab,var(--color-primary-container)40%,transparent)}}.bg-primary-soft{background-color:var(--color-primary-soft)}.bg-primary-strong{background-color:var(--color-primary-strong)}.bg-red-50{background-color:var(--color-red-50)}.bg-red-50\/40{background-color:#fef2f266}@supports (color:color-mix(in lab, red, red)){.bg-red-50\/40{background-color:color-mix(in oklab,var(--color-red-50)40%,transparent)}}.bg-red-50\/60{background-color:#fef2f299}@supports (color:color-mix(in lab, red, red)){.bg-red-50\/60{background-color:color-mix(in oklab,var(--color-red-50)60%,transparent)}}.bg-red-600{background-color:var(--color-red-600)}.bg-red-700{background-color:var(--color-red-700)}.bg-sky-700{background-color:var(--color-sky-700)}.bg-slate-600{background-color:var(--color-slate-600)}.bg-success{background-color:var(--color-success)}.bg-success-container{background-color:var(--color-success-container)}.bg-surface{background-color:var(--color-surface)}.bg-surface-hover{background-color:var(--color-surface-hover)}.bg-surface-hover\/50{background-color:#f8f9fa80}@supports (color:color-mix(in lab, red, red)){.bg-surface-hover\/50{background-color:color-mix(in oklab,var(--color-surface-hover)50%,transparent)}}.bg-surface-muted{background-color:var(--color-surface-muted)}.bg-surface-tint{background-color:var(--color-surface-tint)}.bg-surface-variant{background-color:var(--color-surface-variant)}.bg-surface-variant-deep{background-color:var(--color-surface-variant-deep)}.bg-surface\/95{background-color:#fffffff2}@supports (color:color-mix(in lab, red, red)){.bg-surface\/95{background-color:color-mix(in oklab,var(--color-surface)95%,transparent)}}.bg-transparent{background-color:#0000}.bg-warning{background-color:var(--color-warning)}.bg-warning-container{background-color:var(--color-warning-container)}.bg-warning-container-alt{background-color:var(--color-warning-container-alt)}.bg-warning-strong{background-color:var(--color-warning-strong)}.bg-white{background-color:var(--color-white)}.bg-white\/30{background-color:#ffffff4d}@supports (color:color-mix(in lab, red, red)){.bg-white\/30{background-color:color-mix(in oklab,var(--color-white)30%,transparent)}}.bg-white\/80{background-color:#fffc}@supports (color:color-mix(in lab, red, red)){.bg-white\/80{background-color:color-mix(in oklab,var(--color-white)80%,transparent)}}.bg-white\/95{background-color:#fffffff2}@supports (color:color-mix(in lab, red, red)){.bg-white\/95{background-color:color-mix(in oklab,var(--color-white)95%,transparent)}}.bg-yellow-100{background-color:var(--color-yellow-100)}.bg-yellow-400{background-color:var(--color-yellow-400)}.bg-zinc-50{background-color:var(--color-zinc-50)}.bg-zinc-900{background-color:var(--color-zinc-900)}.bg-gradient-to-l{--tw-gradient-position:to left in oklab;background-image:linear-gradient(var(--tw-gradient-stops))}.from-surface{--tw-gradient-from:var(--color-surface);--tw-gradient-stops:var(--tw-gradient-via-stops,var(--tw-gradient-position),var(--tw-gradient-from)var(--tw-gradient-from-position),var(--tw-gradient-to)var(--tw-gradient-to-position))}.to-transparent{--tw-gradient-to:transparent;--tw-gradient-stops:var(--tw-gradient-via-stops,var(--tw-gradient-position),var(--tw-gradient-from)var(--tw-gradient-from-position),var(--tw-gradient-to)var(--tw-gradient-to-position))}.p-0{padding:calc(var(--spacing)*0)}.p-1{padding:calc(var(--spacing)*1)}.p-1\.5{padding:calc(var(--spacing)*1.5)}.p-2{padding:calc(var(--spacing)*2)}.p-2\.5{padding:calc(var(--spacing)*2.5)}.p-3{padding:calc(var(--spacing)*3)}.p-3\.5{padding:calc(var(--spacing)*3.5)}.p-4{padding:calc(var(--spacing)*4)}.p-5{padding:calc(var(--spacing)*5)}.p-6{padding:calc(var(--spacing)*6)}.p-8{padding:calc(var(--spacing)*8)}.p-10{padding:calc(var(--spacing)*10)}.p-\[10px\]{padding:10px}.p-\[15px\]{padding:15px}.px-1{padding-inline:calc(var(--spacing)*1)}.px-1\.5{padding-inline:calc(var(--spacing)*1.5)}.px-2{padding-inline:calc(var(--spacing)*2)}.px-2\.5{padding-inline:calc(var(--spacing)*2.5)}.px-3{padding-inline:calc(var(--spacing)*3)}.px-3\.5{padding-inline:calc(var(--spacing)*3.5)}.px-4{padding-inline:calc(var(--spacing)*4)}.px-5{padding-inline:calc(var(--spacing)*5)}.px-6{padding-inline:calc(var(--spacing)*6)}.px-8{padding-inline:calc(var(--spacing)*8)}.px-\[5px\]{padding-inline:5px}.px-\[10px\]{padding-inline:10px}.px-\[15px\]{padding-inline:15px}.py-0{padding-block:calc(var(--spacing)*0)}.py-0\.5{padding-block:calc(var(--spacing)*.5)}.py-1{padding-block:calc(var(--spacing)*1)}.py-1\.5{padding-block:calc(var(--spacing)*1.5)}.py-2{padding-block:calc(var(--spacing)*2)}.py-2\.5{padding-block:calc(var(--spacing)*2.5)}.py-3{padding-block:calc(var(--spacing)*3)}.py-3\.5{padding-block:calc(var(--spacing)*3.5)}.py-4{padding-block:calc(var(--spacing)*4)}.py-5{padding-block:calc(var(--spacing)*5)}.py-6{padding-block:calc(var(--spacing)*6)}.py-8{padding-block:calc(var(--spacing)*8)}.py-9{padding-block:calc(var(--spacing)*9)}.py-10{padding-block:calc(var(--spacing)*10)}.py-12{padding-block:calc(var(--spacing)*12)}.py-14{padding-block:calc(var(--spacing)*14)}.py-16{padding-block:calc(var(--spacing)*16)}.py-\[8px\]{padding-block:8px}.py-\[10px\]{padding-block:10px}.py-\[15px\]{padding-block:15px}.pt-0{padding-top:calc(var(--spacing)*0)}.pt-0\.5{padding-top:calc(var(--spacing)*.5)}.pt-1{padding-top:calc(var(--spacing)*1)}.pt-2{padding-top:calc(var(--spacing)*2)}.pt-2\.5{padding-top:calc(var(--spacing)*2.5)}.pt-3{padding-top:calc(var(--spacing)*3)}.pt-4{padding-top:calc(var(--spacing)*4)}.pt-5{padding-top:calc(var(--spacing)*5)}.pt-6{padding-top:calc(var(--spacing)*6)}.pt-8{padding-top:calc(var(--spacing)*8)}.pt-10{padding-top:calc(var(--spacing)*10)}.pt-20{padding-top:calc(var(--spacing)*20)}.pt-\[0\.125rem\]{padding-top:.125rem}.pr-1{padding-right:calc(var(--spacing)*1)}.pr-2{padding-right:calc(var(--spacing)*2)}.pr-3{padding-right:calc(var(--spacing)*3)}.pr-4{padding-right:calc(var(--spacing)*4)}.pr-5{padding-right:calc(var(--spacing)*5)}.pr-6{padding-right:calc(var(--spacing)*6)}.pr-7{padding-right:calc(var(--spacing)*7)}.pr-8{padding-right:calc(var(--spacing)*8)}.pr-9{padding-right:calc(var(--spacing)*9)}.pr-10{padding-right:calc(var(--spacing)*10)}.pb-2{padding-bottom:calc(var(--spacing)*2)}.pb-3{padding-bottom:calc(var(--spacing)*3)}.pb-4{padding-bottom:calc(var(--spacing)*4)}.pb-6{padding-bottom:calc(var(--spacing)*6)}.pb-8{padding-bottom:calc(var(--spacing)*8)}.pb-10{padding-bottom:calc(var(--spacing)*10)}.pb-16{padding-bottom:calc(var(--spacing)*16)}.pb-20{padding-bottom:calc(var(--spacing)*20)}.pb-28{padding-bottom:calc(var(--spacing)*28)}.pb-\[max\(0\.75rem\,env\(safe-area-inset-bottom\)\)\]{padding-bottom:max(.75rem,env(safe-area-inset-bottom))}.pl-2{padding-left:calc(var(--spacing)*2)}.pl-3{padding-left:calc(var(--spacing)*3)}.pl-4{padding-left:calc(var(--spacing)*4)}.pl-5{padding-left:calc(var(--spacing)*5)}.pl-9{padding-left:calc(var(--spacing)*9)}.pl-13{padding-left:calc(var(--spacing)*13)}.pl-16{padding-left:calc(var(--spacing)*16)}.pl-\[10\%\]{padding-left:10%}.text-center{text-align:center}.text-left{text-align:left}.text-right{text-align:right}.align-middle{vertical-align:middle}.align-top{vertical-align:top}.font-\[\'DM_Sans\'\,Roboto\,Arial\,sans-serif\]{font-family:DM Sans,Roboto,Arial,sans-serif}.font-\[\'DM_Sans\'\]{font-family:DM Sans}.font-\[\'Roboto\'\,sans-serif\]{font-family:Roboto,sans-serif}.font-mono{font-family:var(--font-mono)}.text-2xl{font-size:var(--text-2xl);line-height:var(--tw-leading,var(--text-2xl--line-height))}.text-3xl{font-size:var(--text-3xl);line-height:var(--tw-leading,var(--text-3xl--line-height))}.text-4xl{font-size:var(--text-4xl);line-height:var(--tw-leading,var(--text-4xl--line-height))}.text-8xl{font-size:var(--text-8xl);line-height:var(--tw-leading,var(--text-8xl--line-height))}.text-base{font-size:var(--text-base);line-height:var(--tw-leading,var(--text-base--line-height))}.text-lg{font-size:var(--text-lg);line-height:var(--tw-leading,var(--text-lg--line-height))}.text-sm{font-size:var(--text-sm);line-height:var(--tw-leading,var(--text-sm--line-height))}.text-xl{font-size:var(--text-xl);line-height:var(--tw-leading,var(--text-xl--line-height))}.text-xs{font-size:var(--text-xs);line-height:var(--tw-leading,var(--text-xs--line-height))}.text-\[0\.9rem\]{font-size:.9rem}.text-\[1\.5rem\]{font-size:1.5rem}.text-\[1rem\]{font-size:1rem}.text-\[9px\]{font-size:9px}.text-\[10\.5px\]{font-size:10.5px}.text-\[10px\]{font-size:10px}.text-\[11\.5px\]{font-size:11.5px}.text-\[11px\]{font-size:11px}.text-\[12\.5px\]{font-size:12.5px}.text-\[12px\]{font-size:12px}.text-\[13\.5px\]{font-size:13.5px}.text-\[13px\]{font-size:13px}.text-\[14px\]{font-size:14px}.text-\[15px\]{font-size:15px}.text-\[16px\]{font-size:16px}.text-\[17px\]{font-size:17px}.text-\[18px\]{font-size:18px}.text-\[20px\]{font-size:20px}.text-\[22px\]{font-size:22px}.text-\[24px\]{font-size:24px}.text-\[26px\]{font-size:26px}.text-\[28px\]{font-size:28px}.text-\[30px\]{font-size:30px}.text-\[48px\]{font-size:48px}.leading-4{--tw-leading:calc(var(--spacing)*4);line-height:calc(var(--spacing)*4)}.leading-5{--tw-leading:calc(var(--spacing)*5);line-height:calc(var(--spacing)*5)}.leading-6{--tw-leading:calc(var(--spacing)*6);line-height:calc(var(--spacing)*6)}.leading-7{--tw-leading:calc(var(--spacing)*7);line-height:calc(var(--spacing)*7)}.leading-8{--tw-leading:calc(var(--spacing)*8);line-height:calc(var(--spacing)*8)}.leading-9{--tw-leading:calc(var(--spacing)*9);line-height:calc(var(--spacing)*9)}.leading-\[1\.5\]{--tw-leading:1.5;line-height:1.5}.leading-none{--tw-leading:1;line-height:1}.leading-relaxed{--tw-leading:var(--leading-relaxed);line-height:var(--leading-relaxed)}.leading-snug{--tw-leading:var(--leading-snug);line-height:var(--leading-snug)}.leading-tight{--tw-leading:var(--leading-tight);line-height:var(--leading-tight)}.font-bold{--tw-font-weight:var(--font-weight-bold);font-weight:var(--font-weight-bold)}.font-extrabold{--tw-font-weight:var(--font-weight-extrabold);font-weight:var(--font-weight-extrabold)}.font-medium{--tw-font-weight:var(--font-weight-medium);font-weight:var(--font-weight-medium)}.font-normal{--tw-font-weight:var(--font-weight-normal);font-weight:var(--font-weight-normal)}.font-semibold{--tw-font-weight:var(--font-weight-semibold);font-weight:var(--font-weight-semibold)}.tracking-normal{--tw-tracking:var(--tracking-normal);letter-spacing:var(--tracking-normal)}.tracking-tight{--tw-tracking:var(--tracking-tight);letter-spacing:var(--tracking-tight)}.tracking-tighter{--tw-tracking:var(--tracking-tighter);letter-spacing:var(--tracking-tighter)}.tracking-wide{--tw-tracking:var(--tracking-wide);letter-spacing:var(--tracking-wide)}.tracking-wider{--tw-tracking:var(--tracking-wider);letter-spacing:var(--tracking-wider)}.tracking-widest{--tw-tracking:var(--tracking-widest);letter-spacing:var(--tracking-widest)}.break-words{overflow-wrap:break-word}.break-all{word-break:break-all}.whitespace-normal{white-space:normal}.whitespace-nowrap{white-space:nowrap}.whitespace-pre-line{white-space:pre-line}.text-\[\#1A73E8\]{color:#1a73e8}.text-\[\#1f1f1f\]{color:#1f1f1f}.text-\[\#5F6368\]{color:#5f6368}.text-\[\#9AA0A6\]{color:#9aa0a6}.text-amber-600{color:var(--color-amber-600)}.text-amber-700{color:var(--color-amber-700)}.text-amber-800{color:var(--color-amber-800)}.text-amber-900{color:var(--color-amber-900)}.text-black{color:var(--color-black)}.text-blue-600{color:var(--color-blue-600)}.text-blue-800\/80{color:#193cb8cc}@supports (color:color-mix(in lab, red, red)){.text-blue-800\/80{color:color-mix(in oklab,var(--color-blue-800)80%,transparent)}}.text-blue-900{color:var(--color-blue-900)}.text-emerald-700{color:var(--color-emerald-700)}.text-emerald-800{color:var(--color-emerald-800)}.text-error{color:var(--color-error)}.text-error\/70{color:#c5221fb3}@supports (color:color-mix(in lab, red, red)){.text-error\/70{color:color-mix(in oklab,var(--color-error)70%,transparent)}}.text-file-link{color:var(--color-file-link)}.text-gray-200{color:var(--color-gray-200)}.text-gray-300{color:var(--color-gray-300)}.text-gray-400{color:var(--color-gray-400)}.text-gray-500{color:var(--color-gray-500)}.text-gray-600{color:var(--color-gray-600)}.text-gray-700{color:var(--color-gray-700)}.text-gray-800{color:var(--color-gray-800)}.text-gray-900{color:var(--color-gray-900)}.text-green-400{color:var(--color-green-400)}.text-green-500{color:var(--color-green-500)}.text-green-600{color:var(--color-green-600)}.text-green-700{color:var(--color-green-700)}.text-green-800{color:var(--color-green-800)}.text-indigo-600{color:var(--color-indigo-600)}.text-indigo-700{color:var(--color-indigo-700)}.text-inherit{color:inherit}.text-on-surface{color:var(--color-on-surface)}.text-on-surface-disabled{color:var(--color-on-surface-disabled)}.text-on-surface-muted{color:var(--color-on-surface-muted)}.text-on-surface-muted-strong{color:var(--color-on-surface-muted-strong)}.text-on-surface-soft{color:var(--color-on-surface-soft)}.text-on-surface-strong{color:var(--color-on-surface-strong)}.text-on-surface-variant{color:var(--color-on-surface-variant)}.text-primary{color:var(--color-primary)}.text-primary-soft{color:var(--color-primary-soft)}.text-primary-strong{color:var(--color-primary-strong)}.text-red-400{color:var(--color-red-400)}.text-red-500{color:var(--color-red-500)}.text-red-600{color:var(--color-red-600)}.text-red-700{color:var(--color-red-700)}.text-red-800{color:var(--color-red-800)}.text-sky-500{color:var(--color-sky-500)}.text-success{color:var(--color-success)}.text-warning{color:var(--color-warning)}.text-warning-on-container{color:var(--color-warning-on-container)}.text-warning-strong{color:var(--color-warning-strong)}.text-white{color:var(--color-white)}.text-white\/50{color:#ffffff80}@supports (color:color-mix(in lab, red, red)){.text-white\/50{color:color-mix(in oklab,var(--color-white)50%,transparent)}}.text-yellow-800{color:var(--color-yellow-800)}.text-zinc-800{color:var(--color-zinc-800)}.capitalize{text-transform:capitalize}.uppercase{text-transform:uppercase}.italic{font-style:italic}.no-underline{text-decoration-line:none}.underline{text-decoration-line:underline}.decoration-sky-500{-webkit-text-decoration-color:var(--color-sky-500);-webkit-text-decoration-color:var(--color-sky-500);text-decoration-color:var(--color-sky-500)}.antialiased{-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}.placeholder-gray-400::placeholder{color:var(--color-gray-400)}.placeholder-gray-500::placeholder{color:var(--color-gray-500)}.placeholder-on-surface-disabled::placeholder{color:var(--color-on-surface-disabled)}.accent-primary{accent-color:var(--color-primary)}.accent-success{accent-color:var(--color-success)}.opacity-0{opacity:0}.opacity-25{opacity:.25}.opacity-40{opacity:.4}.opacity-50{opacity:.5}.opacity-60{opacity:.6}.opacity-70{opacity:.7}.opacity-75{opacity:.75}.opacity-80{opacity:.8}.shadow{--tw-shadow:0 1px 3px 0 var(--tw-shadow-color,#0000001a),0 1px 2px -1px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-2xl{--tw-shadow:0 25px 50px -12px var(--tw-shadow-color,#00000040);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-\[0_-2px_12px_rgba\(60\,64\,67\,0\.08\)\]{--tw-shadow:0 -2px 12px var(--tw-shadow-color,#3c404314);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-\[0_0_20px_1px_var\(--color-shadow-soft\)\]{--tw-shadow:0 0 20px 1px var(--tw-shadow-color,var(--color-shadow-soft));box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-inner{--tw-shadow:inset 0 2px 4px 0 var(--tw-shadow-color,#0000000d);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-lg{--tw-shadow:0 10px 15px -3px var(--tw-shadow-color,#0000001a),0 4px 6px -4px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-md{--tw-shadow:0 4px 6px -1px var(--tw-shadow-color,#0000001a),0 2px 4px -2px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-none{--tw-shadow:0 0 #0000;box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-sm{--tw-shadow:0 1px 3px 0 var(--tw-shadow-color,#0000001a),0 1px 2px -1px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-xl{--tw-shadow:0 20px 25px -5px var(--tw-shadow-color,#0000001a),0 8px 10px -6px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-xs{--tw-shadow:0 1px 2px 0 var(--tw-shadow-color,#0000000d);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.ring,.ring-1{--tw-ring-shadow:var(--tw-ring-inset,)0 0 0 calc(1px + var(--tw-ring-offset-width))var(--tw-ring-color,currentcolor);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.shadow-slate-500\/20{--tw-shadow-color:#62748e33}@supports (color:color-mix(in lab, red, red)){.shadow-slate-500\/20{--tw-shadow-color:color-mix(in oklab,color-mix(in oklab,var(--color-slate-500)20%,transparent)var(--tw-shadow-alpha),transparent)}}.ring-indigo-700\/10{--tw-ring-color:#432dd71a}@supports (color:color-mix(in lab, red, red)){.ring-indigo-700\/10{--tw-ring-color:color-mix(in oklab,var(--color-indigo-700)10%,transparent)}}.outline,.outline-1{outline-style:var(--tw-outline-style);outline-width:1px}.outline-outline-strong{outline-color:var(--color-outline-strong)}.grayscale{--tw-grayscale:grayscale(100%);filter:var(--tw-blur,)var(--tw-brightness,)var(--tw-contrast,)var(--tw-grayscale,)var(--tw-hue-rotate,)var(--tw-invert,)var(--tw-saturate,)var(--tw-sepia,)var(--tw-drop-shadow,)}.filter{filter:var(--tw-blur,)var(--tw-brightness,)var(--tw-contrast,)var(--tw-grayscale,)var(--tw-hue-rotate,)var(--tw-invert,)var(--tw-saturate,)var(--tw-sepia,)var(--tw-drop-shadow,)}.backdrop-blur{--tw-backdrop-blur:blur(8px);-webkit-backdrop-filter:var(--tw-backdrop-blur,)var(--tw-backdrop-brightness,)var(--tw-backdrop-contrast,)var(--tw-backdrop-grayscale,)var(--tw-backdrop-hue-rotate,)var(--tw-backdrop-invert,)var(--tw-backdrop-opacity,)var(--tw-backdrop-saturate,)var(--tw-backdrop-sepia,);backdrop-filter:var(--tw-backdrop-blur,)var(--tw-backdrop-brightness,)var(--tw-backdrop-contrast,)var(--tw-backdrop-grayscale,)var(--tw-backdrop-hue-rotate,)var(--tw-backdrop-invert,)var(--tw-backdrop-opacity,)var(--tw-backdrop-saturate,)var(--tw-backdrop-sepia,)}.transition{transition-property:color,background-color,border-color,outline-color,text-decoration-color,fill,stroke,--tw-gradient-from,--tw-gradient-via,--tw-gradient-to,opacity,box-shadow,transform,translate,scale,rotate,filter,-webkit-backdrop-filter,backdrop-filter,display,visibility,content-visibility,overlay,pointer-events;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.transition-\[transform\,width\]{transition-property:transform,width;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.transition-all{transition-property:all;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.transition-colors{transition-property:color,background-color,border-color,outline-color,text-decoration-color,fill,stroke,--tw-gradient-from,--tw-gradient-via,--tw-gradient-to;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.transition-opacity{transition-property:opacity;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.transition-shadow{transition-property:box-shadow;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.transition-transform{transition-property:transform,translate,scale,rotate;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.duration-150{--tw-duration:.15s;transition-duration:.15s}.duration-200{--tw-duration:.2s;transition-duration:.2s}.duration-300{--tw-duration:.3s;transition-duration:.3s}.ease-in{--tw-ease:var(--ease-in);transition-timing-function:var(--ease-in)}.ease-in-out{--tw-ease:var(--ease-in-out);transition-timing-function:var(--ease-in-out)}.ease-out{--tw-ease:var(--ease-out);transition-timing-function:var(--ease-out)}.outline-none{--tw-outline-style:none;outline-style:none}.select-none{-webkit-user-select:none;user-select:none}.\[-webkit-overflow-scrolling\:touch\]{-webkit-overflow-scrolling:touch}.\[scrollbar-width\:none\]{scrollbar-width:none}.ring-inset{--tw-ring-inset:inset}.group-open\:hidden:is(:where(.group):is([open],:popover-open,:open) *){display:none}.group-open\:inline:is(:where(.group):is([open],:popover-open,:open) *){display:inline}.group-open\:rotate-180:is(:where(.group):is([open],:popover-open,:open) *){rotate:180deg}.group-focus-within\:block:is(:where(.group):focus-within *){display:block}@media (hover:hover){.group-hover\:block:is(:where(.group):hover *){display:block}.group-hover\:-translate-x-1:is(:where(.group):hover *){--tw-translate-x:calc(var(--spacing)*-1);translate:var(--tw-translate-x)var(--tw-translate-y)}.group-hover\:-translate-y-1:is(:where(.group):hover *){--tw-translate-y:calc(var(--spacing)*-1);translate:var(--tw-translate-x)var(--tw-translate-y)}.group-hover\:border-green-300:is(:where(.group):hover *){border-color:var(--color-green-300)}.group-hover\:bg-white:is(:where(.group):hover *){background-color:var(--color-white)}.group-hover\:text-on-surface-strong:is(:where(.group):hover *){color:var(--color-on-surface-strong)}.group-hover\:text-white:is(:where(.group):hover *){color:var(--color-white)}.group-hover\:underline:is(:where(.group):hover *){text-decoration-line:underline}.group-hover\:opacity-100:is(:where(.group):hover *){opacity:1}.group-hover\:shadow-md:is(:where(.group):hover *){--tw-shadow:0 4px 6px -1px var(--tw-shadow-color,#0000001a),0 2px 4px -2px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.group-hover\/member\:opacity-100:is(:where(.group\/member):hover *),.group-hover\/opt\:opacity-100:is(:where(.group\/opt):hover *){opacity:1}}.group-aria-selected\:bg-primary-strong:is(:where(.group)[aria-selected=true] *){background-color:var(--color-primary-strong)}.peer-checked\:bg-green-500:is(:where(.peer):checked~*){background-color:var(--color-green-500)}.peer-checked\:bg-success:is(:where(.peer):checked~*){background-color:var(--color-success)}.peer-focus\:hidden:is(:where(.peer):focus~*){display:none}.peer-focus\:outline-none:is(:where(.peer):focus~*){--tw-outline-style:none;outline-style:none}.marker\:text-black ::marker{color:var(--color-black)}.marker\:text-black::marker{color:var(--color-black)}.marker\:text-black ::-webkit-details-marker{color:var(--color-black)}.marker\:text-black::-webkit-details-marker{color:var(--color-black)}.file\:h-full::file-selector-button{height:100%}.file\:rounded-l-lg::file-selector-button{border-top-left-radius:var(--radius-lg);border-bottom-left-radius:var(--radius-lg)}.file\:border-gray-300::file-selector-button{border-color:var(--color-gray-300)}.file\:bg-gray-300::file-selector-button{background-color:var(--color-gray-300)}.file\:px-2::file-selector-button{padding-inline:calc(var(--spacing)*2)}.file\:py-2::file-selector-button{padding-block:calc(var(--spacing)*2)}.backdrop\:bg-black\/40::backdrop{background-color:#0006}@supports (color:color-mix(in lab, red, red)){.backdrop\:bg-black\/40::backdrop{background-color:color-mix(in oklab,var(--color-black)40%,transparent)}}.backdrop\:bg-black\/50::backdrop{background-color:#00000080}@supports (color:color-mix(in lab, red, red)){.backdrop\:bg-black\/50::backdrop{background-color:color-mix(in oklab,var(--color-black)50%,transparent)}}.before\:absolute:before{content:var(--tw-content);position:absolute}.before\:top-0:before{content:var(--tw-content);top:calc(var(--spacing)*0)}.before\:bottom-0:before{content:var(--tw-content);bottom:calc(var(--spacing)*0)}.before\:left-0:before{content:var(--tw-content);left:calc(var(--spacing)*0)}.before\:w-px:before{content:var(--tw-content);width:1px}.before\:bg-outline-variant:before{content:var(--tw-content);background-color:var(--color-outline-variant)}.before\:content-\[\'\'\]:before{content:var(--tw-content);--tw-content:"";content:var(--tw-content)}.after\:absolute:after{content:var(--tw-content);position:absolute}.after\:start-\[2px\]:after{content:var(--tw-content);inset-inline-start:2px}.after\:top-\[2px\]:after{content:var(--tw-content);top:2px}.after\:top-\[10\%\]:after{content:var(--tw-content);top:10%}.after\:left-\[5\%\]:after{content:var(--tw-content);left:5%}.after\:h-4:after{content:var(--tw-content);height:calc(var(--spacing)*4)}.after\:h-\[80\%\]:after{content:var(--tw-content);height:80%}.after\:w-4:after{content:var(--tw-content);width:calc(var(--spacing)*4)}.after\:w-\[45\%\]:after{content:var(--tw-content);width:45%}.after\:rounded-full:after{content:var(--tw-content);border-radius:3.40282e38px}.after\:border:after{content:var(--tw-content);border-style:var(--tw-border-style);border-width:1px}.after\:border-gray-300:after{content:var(--tw-content);border-color:var(--color-gray-300)}.after\:bg-white:after{content:var(--tw-content);background-color:var(--color-white)}.after\:transition-all:after{content:var(--tw-content);transition-property:all;transition-timing-function:var(--tw-ease,var(--default-transition-timing-function));transition-duration:var(--tw-duration,var(--default-transition-duration))}.after\:content-\[\'\'\]:after{content:var(--tw-content);--tw-content:"";content:var(--tw-content)}.peer-checked\:after\:translate-x-full:is(:where(.peer):checked~*):after{content:var(--tw-content);--tw-translate-x:100%;translate:var(--tw-translate-x)var(--tw-translate-y)}.peer-checked\:after\:border-white:is(:where(.peer):checked~*):after{content:var(--tw-content);border-color:var(--color-white)}.first\:pt-0:first-child{padding-top:calc(var(--spacing)*0)}.last\:mb-0:last-child{margin-bottom:calc(var(--spacing)*0)}.open\:flex:is([open],:popover-open,:open){display:flex}.focus-within\:border-primary:focus-within{border-color:var(--color-primary)}.focus-within\:opacity-100:focus-within{opacity:1}.focus-within\:ring-1:focus-within{--tw-ring-shadow:var(--tw-ring-inset,)0 0 0 calc(1px + var(--tw-ring-offset-width))var(--tw-ring-color,currentcolor);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.focus-within\:ring-primary:focus-within{--tw-ring-color:var(--color-primary)}@media (hover:hover){.hover\:cursor-pointer:hover{cursor:pointer}.hover\:border-error\/30:hover{border-color:#c5221f4d}@supports (color:color-mix(in lab, red, red)){.hover\:border-error\/30:hover{border-color:color-mix(in oklab,var(--color-error)30%,transparent)}}.hover\:border-gray-300:hover{border-color:var(--color-gray-300)}.hover\:border-gray-400:hover{border-color:var(--color-gray-400)}.hover\:border-on-surface-strong:hover{border-color:var(--color-on-surface-strong)}.hover\:border-outline-strong:hover{border-color:var(--color-outline-strong)}.hover\:border-primary:hover{border-color:var(--color-primary)}.hover\:border-success\/30:hover{border-color:#1373334d}@supports (color:color-mix(in lab, red, red)){.hover\:border-success\/30:hover{border-color:color-mix(in oklab,var(--color-success)30%,transparent)}}.hover\:border-warning\/30:hover{border-color:#f57f174d}@supports (color:color-mix(in lab, red, red)){.hover\:border-warning\/30:hover{border-color:color-mix(in oklab,var(--color-warning)30%,transparent)}}.hover\:bg-\[\#1a6abf\]:hover{background-color:#1a6abf}.hover\:bg-black\/5:hover{background-color:#0000000d}@supports (color:color-mix(in lab, red, red)){.hover\:bg-black\/5:hover{background-color:color-mix(in oklab,var(--color-black)5%,transparent)}}.hover\:bg-emerald-100:hover{background-color:var(--color-emerald-100)}.hover\:bg-error-container:hover{background-color:var(--color-error-container)}.hover\:bg-error-hover:hover{background-color:var(--color-error-hover)}.hover\:bg-gray-50:hover{background-color:var(--color-gray-50)}.hover\:bg-gray-100:hover{background-color:var(--color-gray-100)}.hover\:bg-gray-300:hover{background-color:var(--color-gray-300)}.hover\:bg-green-600:hover{background-color:var(--color-green-600)}.hover\:bg-indigo-700:hover{background-color:var(--color-indigo-700)}.hover\:bg-outline-variant:hover{background-color:var(--color-outline-variant)}.hover\:bg-primary-container:hover{background-color:var(--color-primary-container)}.hover\:bg-primary-container-hover:hover{background-color:var(--color-primary-container-hover)}.hover\:bg-primary-hover:hover{background-color:var(--color-primary-hover)}.hover\:bg-red-50:hover{background-color:var(--color-red-50)}.hover\:bg-red-700:hover{background-color:var(--color-red-700)}.hover\:bg-slate-700:hover{background-color:var(--color-slate-700)}.hover\:bg-success-hover:hover{background-color:var(--color-success-hover)}.hover\:bg-surface-hover:hover{background-color:var(--color-surface-hover)}.hover\:bg-surface-hover\/50:hover{background-color:#f8f9fa80}@supports (color:color-mix(in lab, red, red)){.hover\:bg-surface-hover\/50:hover{background-color:color-mix(in oklab,var(--color-surface-hover)50%,transparent)}}.hover\:bg-surface-hover\/60:hover{background-color:#f8f9fa99}@supports (color:color-mix(in lab, red, red)){.hover\:bg-surface-hover\/60:hover{background-color:color-mix(in oklab,var(--color-surface-hover)60%,transparent)}}.hover\:bg-surface-variant:hover{background-color:var(--color-surface-variant)}.hover\:bg-surface-variant-deep:hover{background-color:var(--color-surface-variant-deep)}.hover\:bg-surface-variant-hover:hover{background-color:var(--color-surface-variant-hover)}.hover\:bg-white\/60:hover{background-color:#fff9}@supports (color:color-mix(in lab, red, red)){.hover\:bg-white\/60:hover{background-color:color-mix(in oklab,var(--color-white)60%,transparent)}}.hover\:bg-zinc-800:hover{background-color:var(--color-zinc-800)}.hover\:text-\[\#3C4043\]:hover{color:#3c4043}.hover\:text-blue-800:hover{color:var(--color-blue-800)}.hover\:text-error:hover{color:var(--color-error)}.hover\:text-gray-600:hover{color:var(--color-gray-600)}.hover\:text-gray-700:hover{color:var(--color-gray-700)}.hover\:text-gray-800:hover{color:var(--color-gray-800)}.hover\:text-gray-900:hover{color:var(--color-gray-900)}.hover\:text-green-600:hover{color:var(--color-green-600)}.hover\:text-on-surface:hover{color:var(--color-on-surface)}.hover\:text-on-surface-strong:hover{color:var(--color-on-surface-strong)}.hover\:text-primary:hover{color:var(--color-primary)}.hover\:text-primary-hover:hover{color:var(--color-primary-hover)}.hover\:text-red-600:hover{color:var(--color-red-600)}.hover\:text-red-700:hover{color:var(--color-red-700)}.hover\:text-sky-700:hover{color:var(--color-sky-700)}.hover\:text-zinc-600:hover{color:var(--color-zinc-600)}.hover\:underline:hover{text-decoration-line:underline}.hover\:decoration-sky-700:hover{-webkit-text-decoration-color:var(--color-sky-700);-webkit-text-decoration-color:var(--color-sky-700);text-decoration-color:var(--color-sky-700)}.hover\:opacity-100:hover{opacity:1}.hover\:shadow-lg:hover{--tw-shadow:0 10px 15px -3px var(--tw-shadow-color,#0000001a),0 4px 6px -4px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.hover\:shadow-md:hover{--tw-shadow:0 4px 6px -1px var(--tw-shadow-color,#0000001a),0 2px 4px -2px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.hover\:shadow-sm:hover{--tw-shadow:0 1px 3px 0 var(--tw-shadow-color,#0000001a),0 1px 2px -1px var(--tw-shadow-color,#0000001a);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.hover\:shadow-slate-500\/30:hover{--tw-shadow-color:#62748e4d}@supports (color:color-mix(in lab, red, red)){.hover\:shadow-slate-500\/30:hover{--tw-shadow-color:color-mix(in oklab,color-mix(in oklab,var(--color-slate-500)30%,transparent)var(--tw-shadow-alpha),transparent)}}.hover\:file\:bg-gray-400:hover::file-selector-button{background-color:var(--color-gray-400)}}.focus\:border-blue-500:focus{border-color:var(--color-blue-500)}.focus\:border-green-400:focus{border-color:var(--color-green-400)}.focus\:border-green-500:focus{border-color:var(--color-green-500)}.focus\:border-indigo-500:focus{border-color:var(--color-indigo-500)}.focus\:border-primary:focus{border-color:var(--color-primary)}.focus\:border-transparent:focus{border-color:#0000}.focus\:bg-surface:focus{background-color:var(--color-surface)}.focus\:bg-white:focus{background-color:var(--color-white)}.focus\:text-on-surface:focus{color:var(--color-on-surface)}.focus\:ring-0:focus{--tw-ring-shadow:var(--tw-ring-inset,)0 0 0 calc(0px + var(--tw-ring-offset-width))var(--tw-ring-color,currentcolor);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.focus\:ring-1:focus{--tw-ring-shadow:var(--tw-ring-inset,)0 0 0 calc(1px + var(--tw-ring-offset-width))var(--tw-ring-color,currentcolor);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.focus\:ring-2:focus{--tw-ring-shadow:var(--tw-ring-inset,)0 0 0 calc(2px + var(--tw-ring-offset-width))var(--tw-ring-color,currentcolor);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.focus\:ring-4:focus{--tw-ring-shadow:var(--tw-ring-inset,)0 0 0 calc(4px + var(--tw-ring-offset-width))var(--tw-ring-color,currentcolor);box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.focus\:ring-blue-500:focus{--tw-ring-color:var(--color-blue-500)}.focus\:ring-blue-500\/10:focus{--tw-ring-color:#3080ff1a}@supports (color:color-mix(in lab, red, red)){.focus\:ring-blue-500\/10:focus{--tw-ring-color:color-mix(in oklab,var(--color-blue-500)10%,transparent)}}.focus\:ring-green-400:focus{--tw-ring-color:var(--color-green-400)}.focus\:ring-green-500:focus{--tw-ring-color:var(--color-green-500)}.focus\:ring-indigo-500:focus{--tw-ring-color:var(--color-indigo-500)}.focus\:ring-indigo-600:focus{--tw-ring-color:var(--color-indigo-600)}.focus\:ring-primary:focus{--tw-ring-color:var(--color-primary)}.focus\:ring-success:focus{--tw-ring-color:var(--color-success)}.focus\:ring-offset-2:focus{--tw-ring-offset-width:2px;--tw-ring-offset-shadow:var(--tw-ring-inset,)0 0 0 var(--tw-ring-offset-width)var(--tw-ring-offset-color)}.focus\:outline-none:focus{--tw-outline-style:none;outline-style:none}.active\:scale-95:active{--tw-scale-x:95%;--tw-scale-y:95%;--tw-scale-z:95%;scale:var(--tw-scale-x)var(--tw-scale-y)}.active\:cursor-grabbing:active{cursor:grabbing}.disabled\:pointer-events-none:disabled{pointer-events:none}.disabled\:cursor-not-allowed:disabled{cursor:not-allowed}.disabled\:bg-surface-tint:disabled{background-color:var(--color-surface-tint)}.disabled\:text-on-surface-disabled:disabled{color:var(--color-on-surface-disabled)}.disabled\:opacity-40:disabled{opacity:.4}.disabled\:opacity-50:disabled{opacity:.5}.has-\[\:checked\]\:border-primary:has(:checked){border-color:var(--color-primary)}.has-\[\:checked\]\:bg-primary-container\/40:has(:checked){background-color:#e8f0fe66}@supports (color:color-mix(in lab, red, red)){.has-\[\:checked\]\:bg-primary-container\/40:has(:checked){background-color:color-mix(in oklab,var(--color-primary-container)40%,transparent)}}@media (prefers-reduced-motion:reduce){.motion-reduce\:transition-none{transition-property:none}}@media not all and (min-width:640px){.max-\[640px\]\:text-\[16px\]{font-size:16px}}@media not all and (min-width:40rem){.max-sm\:before\:hidden:before{content:var(--tw-content);display:none}}@media (min-width:1245px){.min-\[1245px\]\:static{position:static}.min-\[1245px\]\:sticky{position:sticky}.min-\[1245px\]\:top-6{top:calc(var(--spacing)*6)}.min-\[1245px\]\:top-full{top:100%}.min-\[1245px\]\:bottom-auto{bottom:auto}.min-\[1245px\]\:mt-1\.5{margin-top:calc(var(--spacing)*1.5)}.min-\[1245px\]\:mb-0{margin-bottom:calc(var(--spacing)*0)}.min-\[1245px\]\:flex{display:flex}.min-\[1245px\]\:hidden{display:none}.min-\[1245px\]\:h-\[700px\]{height:700px}.min-\[1245px\]\:max-h-\[calc\(100vh-3rem\)\]{max-height:calc(100vh - 3rem)}.min-\[1245px\]\:origin-top{transform-origin:top}.min-\[1245px\]\:translate-x-0{--tw-translate-x:calc(var(--spacing)*0);translate:var(--tw-translate-x)var(--tw-translate-y)}.min-\[1245px\]\:border-l-0{border-left-style:var(--tw-border-style);border-left-width:0}.min-\[1245px\]\:pb-8{padding-bottom:calc(var(--spacing)*8)}.min-\[1245px\]\:pb-10{padding-bottom:calc(var(--spacing)*10)}.min-\[1245px\]\:shadow-none{--tw-shadow:0 0 #0000;box-shadow:var(--tw-inset-shadow),var(--tw-inset-ring-shadow),var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow)}.min-\[1245px\]\:transition-none{transition-property:none}}@media (min-width:40rem){.sm\:mx-\[5px\]{margin-inline:5px}.sm\:mx-\[10px\]{margin-inline:10px}.sm\:mx-auto{margin-inline:auto}.sm\:mt-0{margin-top:calc(var(--spacing)*0)}.sm\:mb-0{margin-bottom:calc(var(--spacing)*0)}.sm\:mb-4{margin-bottom:calc(var(--spacing)*4)}.sm\:ml-6{margin-left:calc(var(--spacing)*6)}.sm\:ml-auto{margin-left:auto}.sm\:block{display:block}.sm\:flex{display:flex}.sm\:hidden{display:none}.sm\:inline{display:inline}.sm\:h-20{height:calc(var(--spacing)*20)}.sm\:h-28{height:calc(var(--spacing)*28)}.sm\:w-1\/2{width:50%}.sm\:w-32{width:calc(var(--spacing)*32)}.sm\:w-64{width:calc(var(--spacing)*64)}.sm\:w-\[85\%\]{width:85%}.sm\:w-\[190px\]{width:190px}.sm\:w-\[240px\]{width:240px}.sm\:w-\[260px\]{width:260px}.sm\:w-auto{width:auto}.sm\:w-full{width:100%}.sm\:max-w-3xl{max-width:var(--container-3xl)}.sm\:min-w-0{min-width:calc(var(--spacing)*0)}.sm\:grid-cols-2{grid-template-columns:repeat(2,minmax(0,1fr))}.sm\:grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}.sm\:flex-row{flex-direction:row}.sm\:flex-nowrap{flex-wrap:nowrap}.sm\:items-center{align-items:center}.sm\:items-start{align-items:flex-start}.sm\:justify-between{justify-content:space-between}.sm\:justify-end{justify-content:flex-end}.sm\:gap-0{gap:calc(var(--spacing)*0)}.sm\:gap-3{gap:calc(var(--spacing)*3)}.sm\:gap-4{gap:calc(var(--spacing)*4)}.sm\:gap-6{gap:calc(var(--spacing)*6)}.sm\:rounded-2xl{border-radius:var(--radius-2xl)}.sm\:p-8{padding:calc(var(--spacing)*8)}.sm\:p-\[15px\]{padding:15px}.sm\:px-4{padding-inline:calc(var(--spacing)*4)}.sm\:px-5{padding-inline:calc(var(--spacing)*5)}.sm\:px-6{padding-inline:calc(var(--spacing)*6)}.sm\:px-8{padding-inline:calc(var(--spacing)*8)}.sm\:px-12{padding-inline:calc(var(--spacing)*12)}.sm\:px-\[10px\]{padding-inline:10px}.sm\:px-\[15px\]{padding-inline:15px}.sm\:py-20{padding-block:calc(var(--spacing)*20)}.sm\:py-\[4px\]{padding-block:4px}.sm\:pt-6{padding-top:calc(var(--spacing)*6)}.sm\:pt-14{padding-top:calc(var(--spacing)*14)}.sm\:pr-10{padding-right:calc(var(--spacing)*10)}.sm\:pl-10{padding-left:calc(var(--spacing)*10)}.sm\:text-left{text-align:left}.sm\:text-5xl{font-size:var(--text-5xl);line-height:var(--tw-leading,var(--text-5xl--line-height))}.sm\:text-9xl{font-size:var(--text-9xl);line-height:var(--tw-leading,var(--text-9xl--line-height))}.sm\:text-base{font-size:var(--text-base);line-height:var(--tw-leading,var(--text-base--line-height))}.sm\:text-sm{font-size:var(--text-sm);line-height:var(--tw-leading,var(--text-sm--line-height))}.sm\:text-xl{font-size:var(--text-xl);line-height:var(--tw-leading,var(--text-xl--line-height))}.sm\:text-\[1rem\]{font-size:1rem}.sm\:text-\[22px\]{font-size:22px}.sm\:text-\[36px\]{font-size:36px}.sm\:leading-\[44px\]{--tw-leading:44px;line-height:44px}}@media (min-width:48rem){.md\:mt-0{margin-top:calc(var(--spacing)*0)}.md\:block{display:block}.md\:flex{display:flex}.md\:w-1\/3{width:33.3333%}.md\:w-2\/3{width:66.6667%}.md\:w-\[75\%\]{width:75%}.md\:w-\[240px\]{width:240px}.md\:w-auto{width:auto}.md\:max-w-2xl{max-width:var(--container-2xl)}.md\:grid-cols-2{grid-template-columns:repeat(2,minmax(0,1fr))}.md\:grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}.md\:grid-cols-\[200px_1fr\]{grid-template-columns:200px 1fr}.md\:grid-cols-\[200px_1fr_260px\]{grid-template-columns:200px 1fr 260px}.md\:flex-row{flex-direction:row}.md\:items-center{align-items:center}.md\:items-end{align-items:flex-end}.md\:items-start{align-items:flex-start}.md\:justify-between{justify-content:space-between}.md\:gap-4{gap:calc(var(--spacing)*4)}.md\:gap-8{gap:calc(var(--spacing)*8)}:where(.md\:divide-x>:not(:last-child)){--tw-divide-x-reverse:0;border-inline-style:var(--tw-border-style);border-inline-start-width:calc(1px*var(--tw-divide-x-reverse));border-inline-end-width:calc(1px*calc(1 - var(--tw-divide-x-reverse)))}:where(.md\:divide-y-0>:not(:last-child)){--tw-divide-y-reverse:0;border-bottom-style:var(--tw-border-style);border-top-style:var(--tw-border-style);border-top-width:calc(0px*var(--tw-divide-y-reverse));border-bottom-width:calc(0px*calc(1 - var(--tw-divide-y-reverse)))}.md\:p-6{padding:calc(var(--spacing)*6)}.md\:px-8{padding-inline:calc(var(--spacing)*8)}.md\:text-3xl{font-size:var(--text-3xl);line-height:var(--tw-leading,var(--text-3xl--line-height))}.md\:text-4xl{font-size:var(--text-4xl);line-height:var(--tw-leading,var(--text-4xl--line-height))}.md\:text-lg{font-size:var(--text-lg);line-height:var(--tw-leading,var(--text-lg--line-height))}.md\:text-sm{font-size:var(--text-sm);line-height:var(--tw-leading,var(--text-sm--line-height))}}@media (min-width:64rem){.lg\:static{position:static}.lg\:sticky{position:sticky}.lg\:top-header{top:var(--spacing-header)}.lg\:flex{display:flex}.lg\:hidden{display:none}.lg\:h-\[calc\(100vh-var\(--spacing-header\)\)\]{height:calc(100vh - var(--spacing-header))}.lg\:w-10\/12{width:83.3333%}.lg\:w-\[50\%\]{width:50%}.lg\:w-\[270px\]{width:270px}.lg\:max-w-4xl{max-width:var(--container-4xl)}.lg\:translate-x-0{--tw-translate-x:calc(var(--spacing)*0);translate:var(--tw-translate-x)var(--tw-translate-y)}.lg\:grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}.lg\:flex-row{flex-direction:row}.lg\:self-start{align-self:flex-start}.lg\:overflow-y-auto{overflow-y:auto}.lg\:px-8{padding-inline:calc(var(--spacing)*8)}.lg\:py-10{padding-block:calc(var(--spacing)*10)}.lg\:text-3xl{font-size:var(--text-3xl);line-height:var(--tw-leading,var(--text-3xl--line-height))}.lg\:text-4xl{font-size:var(--text-4xl);line-height:var(--tw-leading,var(--text-4xl--line-height))}.lg\:\[-webkit-overflow-scrolling\:touch\]{-webkit-overflow-scrolling:touch}.lg\:\[scrollbar-width\:none\]{scrollbar-width:none}.lg\:group-data-\[collapsed\=false\]\/sidebar\:mx-3:is(:where(.group\/sidebar)[data-collapsed=false] *){margin-inline:calc(var(--spacing)*3)}.lg\:group-data-\[collapsed\=false\]\/sidebar\:rounded-full:is(:where(.group\/sidebar)[data-collapsed=false] *){border-radius:3.40282e38px}.lg\:group-data-\[collapsed\=false\]\/sidebar\:bg-primary-container-alt:is(:where(.group\/sidebar)[data-collapsed=false] *){background-color:var(--color-primary-container-alt)}.lg\:group-data-\[collapsed\=false\]\/sidebar\:font-semibold:is(:where(.group\/sidebar)[data-collapsed=false] *){--tw-font-weight:var(--font-weight-semibold);font-weight:var(--font-weight-semibold)}.lg\:group-data-\[collapsed\=false\]\/sidebar\:text-primary-strong:is(:where(.group\/sidebar)[data-collapsed=false] *){color:var(--color-primary-strong)}.group-data-\[collapsed\=true\]\/sidebar\:lg\:hidden:is(:where(.group\/sidebar)[data-collapsed=true] *){display:none}.group-data-\[collapsed\=true\]\/sidebar\:lg\:justify-center:is(:where(.group\/sidebar)[data-collapsed=true] *){justify-content:center}.group-data-\[collapsed\=true\]\/sidebar\:lg\:px-0:is(:where(.group\/sidebar)[data-collapsed=true] *){padding-inline:calc(var(--spacing)*0)}@media (hover:hover){.group-data-\[collapsed\=true\]\/sidebar\:lg\:group-hover\/item\:block:is(:where(.group\/sidebar)[data-collapsed=true] *):is(:where(.group\/item):hover *){display:block}}.lg\:file\:px-5::file-selector-button{padding-inline:calc(var(--spacing)*5)}.data-\[collapsed\=true\]\:lg\:w-\[72px\][data-collapsed=true]{width:72px}.data-\[collapsed\=true\]\:lg\:overflow-visible[data-collapsed=true]{overflow:visible}}@media (min-width:80rem){.xl\:w-8\/12{width:66.6667%}.xl\:grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}}@media (min-width:96rem){.\32 xl\:w-6\/12{width:50%}}.rtl\:peer-checked\:after\:-translate-x-full:where(:dir(rtl),[dir=rtl],[dir=rtl] *):is(:where(.peer):checked~*):after{content:var(--tw-content);--tw-translate-x:-100%;translate:var(--tw-translate-x)var(--tw-translate-y)}@media (pointer:coarse){.pointer-coarse\:touch-pan-y{--tw-pan-y:pan-y;touch-action:var(--tw-pan-x,)var(--tw-pan-y,)var(--tw-pinch-zoom,)}.pointer-coarse\:opacity-100{opacity:1}}.\[\&_del\]\:rounded del{border-radius:.25rem}.\[\&_del\]\:bg-error-container del{background-color:var(--color-error-container)}.\[\&_del\]\:px-0\.5 del{padding-inline:calc(var(--spacing)*.5)}.\[\&_del\]\:text-error del{color:var(--color-error)}.\[\&_del\]\:line-through del{text-decoration-line:line-through}.\[\&_del\]\:no-underline del{text-decoration-line:none}.\[\&_ins\]\:rounded ins{border-radius:.25rem}.\[\&_ins\]\:bg-success-container ins{background-color:var(--color-success-container)}.\[\&_ins\]\:px-0\.5 ins{padding-inline:calc(var(--spacing)*.5)}.\[\&_ins\]\:font-medium ins{--tw-font-weight:var(--font-weight-medium);font-weight:var(--font-weight-medium)}.\[\&_ins\]\:text-success ins{color:var(--color-success)}.\[\&_ins\]\:no-underline ins{text-decoration-line:none}.\[\&_li\.diff-ol-item\]\:ml-6 li.diff-ol-item{margin-left:calc(var(--spacing)*6)}.\[\&_li\.diff-ol-item\]\:list-decimal li.diff-ol-item{list-style-type:decimal}.\[\&_li\.diff-ol-item\:\:marker\]\:font-bold li.diff-ol-item::marker{--tw-font-weight:var(--font-weight-bold);font-weight:var(--font-weight-bold)}.\[\&_li\.diff-ol-item\:\:marker\]\:text-on-surface-variant li.diff-ol-item::marker{color:var(--color-on-surface-variant)}.\[\&_li\.diff-ul-item\]\:ml-6 li.diff-ul-item{margin-left:calc(var(--spacing)*6)}.\[\&_li\.diff-ul-item\]\:list-disc li.diff-ul-item{list-style-type:disc}.\[\&_li\.diff-ul-item\:\:marker\]\:font-bold li.diff-ul-item::marker{--tw-font-weight:var(--font-weight-bold);font-weight:var(--font-weight-bold)}.\[\&_li\.diff-ul-item\:\:marker\]\:text-on-surface-variant li.diff-ul-item::marker{color:var(--color-on-surface-variant)}.\[\&\:\:-webkit-details-marker\]\:hidden::-webkit-details-marker{display:none}.\[\&\:\:-webkit-scrollbar\]\:hidden::-webkit-scrollbar{display:none}@media (min-width:64rem){.lg\:\[\&\:\:-webkit-scrollbar\]\:hidden::-webkit-scrollbar{display:none}}.\[\&\:\:marker\]\:hidden::marker{display:none}}#app-sidebar[data-collapsed=true]{overflow:visible}input[type=checkbox].accent-primary{accent-color:var(--color-primary)}input[type=checkbox].accent-success{accent-color:var(--color-success)}.editor-preview h1{margin-top:1em!important;margin-bottom:.5em!important;font-size:2em!important;font-weight:700!important;line-height:1.2!important}.editor-preview h2{margin-top:1em!important;margin-bottom:.5em!important;font-size:1.5em!important;font-weight:700!important;line-height:1.3!important}.editor-preview h3{margin-top:1em!important;margin-bottom:.5em!important;font-size:1.17em!important;font-weight:600!important;line-height:1.4!important}.editor-preview h4{margin-top:1em!important;margin-bottom:.5em!important;font-size:1em!important;font-weight:600!important;line-height:1.4!important}.editor-preview h5{margin-top:1em!important;margin-bottom:.5em!important;font-size:.83em!important;font-weight:500!important;line-height:1.4!important}.editor-preview h6{margin-top:1em!important;margin-bottom:.5em!important;font-size:.67em!important;font-weight:500!important;line-height:1.4!important}.editor-preview ul{margin-bottom:1em!important;padding-left:1.5em!important;list-style-type:disc!important}.editor-preview ol{margin-bottom:1em!important;padding-left:1.5em!important;list-style-type:decimal!important}.editor-preview>:first-child{margin-top:0!important}.card-markdown h1{margin-top:.25em!important;margin-bottom:.25em!important;font-size:1em!important;font-weight:700!important;line-height:.5!important}.card-markdown h2{margin-top:.2em!important;margin-bottom:.2em!important;font-size:.75em!important;font-weight:700!important;line-height:.5!important}.card-markdown h3{margin-top:.2em!important;margin-bottom:.2em!important;font-size:.5em!important;font-weight:700!important;line-height:.5!important}.card-markdown h4{margin-top:.2em!important;margin-bottom:.2em!important;font-size:.4em!important;font-weight:500!important;line-height:.5!important}.card-markdown h5{margin-top:.2em!important;margin-bottom:.2em!important;font-size:.35em!important;font-weight:500!important;line-height:.5!important}.card-markdown h6{margin-top:.2em!important;margin-bottom:.2em!important;font-size:.33em!important;font-weight:500!important;line-height:.5!important}.rich-diff-viewer del{color:#7f1d1d;background-color:#fecaca;-webkit-text-decoration:line-through #f87171;text-decoration:line-through #f87171;text-decoration-thickness:2px}.rich-diff-viewer ins{color:#14532d;background-color:#bbf7d0;font-weight:500;text-decoration:none}@property --tw-translate-x{syntax:"*";inherits:false;initial-value:0}@property --tw-translate-y{syntax:"*";inherits:false;initial-value:0}@property --tw-translate-z{syntax:"*";inherits:false;initial-value:0}@property --tw-rotate-x{syntax:"*";inherits:false}@property --tw-rotate-y{syntax:"*";inherits:false}@property --tw-rotate-z{syntax:"*";inherits:false}@property --tw-skew-x{syntax:"*";inherits:false}@property --tw-skew-y{syntax:"*";inherits:false}@property --tw-space-y-reverse{syntax:"*";inherits:false;initial-value:0}@property --tw-space-x-reverse{syntax:"*";inherits:false;initial-value:0}@property --tw-divide-y-reverse{syntax:"*";inherits:false;initial-value:0}@property --tw-border-style{syntax:"*";inherits:false;initial-value:solid}@property --tw-gradient-position{syntax:"*";inherits:false}@property --tw-gradient-from{syntax:"<color>";inherits:false;initial-value:#0000}@property --tw-gradient-via{syntax:"<color>";inherits:false;initial-value:#0000}@property --tw-gradient-to{syntax:"<color>";inherits:false;initial-value:#0000}@property --tw-gradient-stops{syntax:"*";inherits:false}@property --tw-gradient-via-stops{syntax:"*";inherits:false}@property --tw-gradient-from-position{syntax:"<length-percentage>";inherits:false;initial-value:0%}@property --tw-gradient-via-position{syntax:"<length-percentage>";inherits:false;initial-value:50%}@property --tw-gradient-to-position{syntax:"<length-percentage>";inherits:false;initial-value:100%}@property --tw-leading{syntax:"*";inherits:false}@property --tw-font-weight{syntax:"*";inherits:false}@property --tw-tracking{syntax:"*";inherits:false}@property --tw-shadow{syntax:"*";inherits:false;initial-value:0 0 #0000}@property --tw-shadow-color{syntax:"*";inherits:false}@property --tw-shadow-alpha{syntax:"<percentage>";inherits:false;initial-value:100%}@property --tw-inset-shadow{syntax:"*";inherits:false;initial-value:0 0 #0000}@property --tw-inset-shadow-color{syntax:"*";inherits:false}@property --tw-inset-shadow-alpha{syntax:"<percentage>";inherits:false;initial-value:100%}@property --tw-ring-color{syntax:"*";inherits:false}@property --tw-ring-shadow{syntax:"*";inherits:false;initial-value:0 0 #0000}@property --tw-inset-ring-color{syntax:"*";inherits:false}@property --tw-inset-ring-shadow{syntax:"*";inherits:false;initial-value:0 0 #0000}@property --tw-ring-inset{syntax:"*";inherits:false}@property --tw-ring-offset-width{syntax:"<length>";inherits:false;initial-value:0}@property --tw-ring-offset-color{syntax:"*";inherits:false;initial-value:#fff}@property --tw-ring-offset-shadow{syntax:"*";inherits:false;initial-value:0 0 #0000}@property --tw-outline-style{syntax:"*";inherits:false;initial-value:solid}@property --tw-blur{syntax:"*";inherits:false}@property --tw-brightness{syntax:"*";inherits:false}@property --tw-contrast{syntax:"*";inherits:false}@property --tw-grayscale{syntax:"*";inherits:false}@property --tw-hue-rotate{syntax:"*";inherits:false}@property --tw-invert{syntax:"*";inherits:false}@property --tw-opacity{syntax:"*";inherits:false}@property --tw-saturate{syntax:"*";inherits:false}@property --tw-sepia{syntax:"*";inherits:false}@property --tw-drop-shadow{syntax:"*";inherits:false}@property --tw-drop-shadow-color{syntax:"*";inherits:false}@property --tw-drop-shadow-alpha{syntax:"<percentage>";inherits:false;initial-value:100%}@property --tw-drop-shadow-size{syntax:"*";inherits:false}@property --tw-backdrop-blur{syntax:"*";inherits:false}@property --tw-backdrop-brightness{syntax:"*";inherits:false}@property --tw-backdrop-contrast{syntax:"*";inherits:false}@property --tw-backdrop-grayscale{syntax:"*";inherits:false}@property --tw-backdrop-hue-rotate{syntax:"*";inherits:false}@property --tw-backdrop-invert{syntax:"*";inherits:false}@property --tw-backdrop-opacity{syntax:"*";inherits:false}@property --tw-backdrop-saturate{syntax:"*";inherits:false}@property --tw-backdrop-sepia{syntax:"*";inherits:false}@property --tw-duration{syntax:"*";inherits:false}@property --tw-ease{syntax:"*";inherits:false}@property --tw-content{syntax:"*";inherits:false;initial-value:""}@property --tw-scale-x{syntax:"*";inherits:false;initial-value:1}@property --tw-scale-y{syntax:"*";inherits:false;initial-value:1}@property --tw-scale-z{syntax:"*";inherits:false;initial-value:1}@property --tw-divide-x-reverse{syntax:"*";inherits:false;initial-value:0}@property --tw-pan-x{syntax:"*";inherits:false}@property --tw-pan-y{syntax:"*";inherits:false}@property --tw-pinch-zoom{syntax:"*";inherits:false}@keyframes spin{to{transform:rotate(360deg)}}@keyframes pulse{50%{opacity:.5}}
app/assets/tailwind/application.css:1:@import "tailwindcss";
app/assets/tailwind/application.css:111:  font-size: 2em !important;
app/assets/tailwind/application.css:112:  font-weight: 700 !important;
app/assets/tailwind/application.css:113:  margin-top: 1em !important;
app/assets/tailwind/application.css:114:  margin-bottom: 0.5em !important;
app/assets/tailwind/application.css:115:  line-height: 1.2 !important;
app/assets/tailwind/application.css:119:  font-size: 1.5em !important;
app/assets/tailwind/application.css:120:  font-weight: 700 !important;
app/assets/tailwind/application.css:121:  margin-top: 1em !important;
app/assets/tailwind/application.css:122:  margin-bottom: 0.5em !important;
app/assets/tailwind/application.css:123:  line-height: 1.3 !important;
app/assets/tailwind/application.css:127:  font-size: 1.17em !important;
app/assets/tailwind/application.css:128:  font-weight: 600 !important;
app/assets/tailwind/application.css:129:  margin-top: 1em !important;
app/assets/tailwind/application.css:130:  margin-bottom: 0.5em !important;
app/assets/tailwind/application.css:131:  line-height: 1.4 !important;
app/assets/tailwind/application.css:135:  font-size: 1em !important;
app/assets/tailwind/application.css:136:  font-weight: 600 !important;
app/assets/tailwind/application.css:137:  margin-top: 1em !important;
app/assets/tailwind/application.css:138:  margin-bottom: 0.5em !important;
app/assets/tailwind/application.css:139:  line-height: 1.4 !important;
app/assets/tailwind/application.css:143:  font-size: 0.83em !important;
app/assets/tailwind/application.css:144:  font-weight: 500 !important;
app/assets/tailwind/application.css:145:  margin-top: 1em !important;
app/assets/tailwind/application.css:146:  margin-bottom: 0.5em !important;
app/assets/tailwind/application.css:147:  line-height: 1.4 !important;
app/assets/tailwind/application.css:151:  font-size: 0.67em !important;
app/assets/tailwind/application.css:152:  font-weight: 500 !important;
app/assets/tailwind/application.css:153:  margin-top: 1em !important;
app/assets/tailwind/application.css:154:  margin-bottom: 0.5em !important;
app/assets/tailwind/application.css:155:  line-height: 1.4 !important;
app/assets/tailwind/application.css:159:  list-style-type: disc !important;
app/assets/tailwind/application.css:160:  padding-left: 1.5em !important;
app/assets/tailwind/application.css:161:  margin-bottom: 1em !important;
app/assets/tailwind/application.css:165:  list-style-type: decimal !important;
app/assets/tailwind/application.css:166:  padding-left: 1.5em !important;
app/assets/tailwind/application.css:167:  margin-bottom: 1em !important;
app/assets/tailwind/application.css:171:  margin-top: 0 !important;
app/assets/tailwind/application.css:175:  font-size: 1em !important;
app/assets/tailwind/application.css:176:  font-weight: 700 !important;
app/assets/tailwind/application.css:177:  margin-top: 0.25em !important;
app/assets/tailwind/application.css:178:  margin-bottom: 0.25em !important;
app/assets/tailwind/application.css:179:  line-height: 0.5 !important;
app/assets/tailwind/application.css:183:  font-size: 0.75em !important;
app/assets/tailwind/application.css:184:  font-weight: 700 !important;
app/assets/tailwind/application.css:185:  margin-top: 0.2em !important;
app/assets/tailwind/application.css:186:  margin-bottom: 0.2em !important;
app/assets/tailwind/application.css:187:  line-height: 0.5 !important;
app/assets/tailwind/application.css:191:  font-size: 0.5em !important;
app/assets/tailwind/application.css:192:  font-weight: 700 !important;
app/assets/tailwind/application.css:193:  margin-top: 0.2em !important;
app/assets/tailwind/application.css:194:  margin-bottom: 0.2em !important;
app/assets/tailwind/application.css:195:  line-height: 0.5 !important;
app/assets/tailwind/application.css:199:  font-size: 0.4em !important;
app/assets/tailwind/application.css:200:  font-weight: 500 !important;
app/assets/tailwind/application.css:201:  margin-top: 0.2em !important;
app/assets/tailwind/application.css:202:  margin-bottom: 0.2em !important;
app/assets/tailwind/application.css:203:  line-height: 0.5 !important;
app/assets/tailwind/application.css:207:  font-size: 0.35em !important;
app/assets/tailwind/application.css:208:  font-weight: 500 !important;
app/assets/tailwind/application.css:209:  margin-top: 0.2em !important;
app/assets/tailwind/application.css:210:  margin-bottom: 0.2em !important;
app/assets/tailwind/application.css:211:  line-height: 0.5 !important;
app/assets/tailwind/application.css:215:  font-size: 0.33em !important;
app/assets/tailwind/application.css:216:  font-weight: 500 !important;
app/assets/tailwind/application.css:217:  margin-top: 0.2em !important;
app/assets/tailwind/application.css:218:  margin-bottom: 0.2em !important;
app/assets/tailwind/application.css:219:  line-height: 0.5 !important;
app/controllers/application_controller.rb:4:  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
app/controllers/courses_controller.rb:6:  before_action :set_course, only: %i[show add_students handle_add_students add_lecturers handle_add_lecturers settings handle_settings destroy export_csv profile update_coursecode update_email_domain grouping_preview]
app/controllers/courses_controller.rb:317:  def import_details
app/controllers/courses_controller.rb:350:  def update_coursecode
app/controllers/courses_controller.rb:354:      @course.generate_coursecode!
app/controllers/courses_controller.rb:358:    if params[:course]&.key?(:coursecode_enabled)
app/controllers/courses_controller.rb:359:      enabled = ActiveModel::Type::Boolean.new.cast(params[:course][:coursecode_enabled])
app/controllers/courses_controller.rb:360:      attributes = { coursecode_enabled: enabled }
app/controllers/courses_controller.rb:361:      attributes[:coursecode] = nil unless enabled
app/controllers/courses_controller.rb:400:  def enroll_via_coursecode
app/controllers/courses_controller.rb:401:    new_enrolment = Enrolment.enroll_via_coursecode(current_user, params[:coursecode])
app/controllers/courses_controller.rb:769:  # course with self-grouping disabled (groups arrive only via CSV/Moodle import
app/javascript/controllers/search_shortcut_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/dropdown_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/tab_fade_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/index.js:1:// Import and register all your controllers from the importmap via controllers/**/*_controller
app/javascript/controllers/index.js:2:import { application } from "controllers/application";
app/javascript/controllers/index.js:3:import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
app/javascript/controllers/lightbox_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/sidebar_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/method_picker_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/comments_drawer_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/version_select_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/record_update_modal_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/coursecode_form_handler_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/coursecode_form_handler_controller.js:3:// Connects to data-controller="coursecode-form-handler"
app/javascript/controllers/coursecode_form_handler_controller.js:4:// Formless coursecode widget (ADR-0010): no <form> in the static DOM, so it can
app/javascript/controllers/coursecode_form_handler_controller.js:6:// the update_coursecode endpoint with a form-encoded body, then render its
app/javascript/controllers/coursecode_form_handler_controller.js:36:        "course[coursecode_enabled]": event.target.value === "true" ? "1" : "0",
app/javascript/controllers/email_domain_form_handler_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/collapsible_sections_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/flash_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/copy_topic_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/students_select_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/dissolve_warning_modal_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/supervisor_capacity_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/landing_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/group_browse_filter_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/jump_bar_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/auto_submit_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/combobox_modal_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/field_expand_modal_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/textarea_resize_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/tabs_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/overlay_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/expandable_rows_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/markdown_editor_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/markdown_editor_controller.js:2:import TurndownService from "turndown";
app/javascript/controllers/markdown_editor_controller.js:3:import { tables, strikethrough } from "turndown-plugin-gfm";
app/javascript/controllers/markdown_editor_controller.js:39:    this.element.style.setProperty("display", "none", "important");
app/javascript/controllers/markdown_editor_controller.js:51:        this.element.style.setProperty("display", "none", "important");
app/javascript/controllers/invite_link_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/application.js:1:import { Application } from "@hotwired/stimulus";
app/javascript/controllers/grouping_settings_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/sortable_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/sortable_controller.js:2:import Sortable from "sortablejs";
app/javascript/controllers/dynamic_form_action_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/scroll_to_bottom_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/controllers/modal_controller.js:1:import { Controller } from "@hotwired/stimulus";
app/javascript/application.js:1:// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
app/javascript/application.js:2:import "@hotwired/turbo-rails";
app/javascript/application.js:3:import "controllers";
app/javascript/application.js:4:import "project_template_fields";
app/javascript/application.js:5:import "htmx.org";
app/views/courses/settings.html.erb:283:                            I will import students and the student list is final — no new students will be added. The system can automatically determine legal group sizes for every student.
app/views/courses/_add_students_modal.html.erb:2:<%# CSV import modal — the in-place replacement for the old add_students full
app/views/courses/add_students.html.erb:73:            To import students with their Groups, please provide a CSV file in
app/views/courses/add_students.html.erb:107:            To import students with their Groups, please provide a CSV file in
app/views/courses/_course_code_form.html.erb:3:    coursecode-form-handler (the same pattern as the sibling email-domain widget). There is no
app/views/courses/_course_code_form.html.erb:10:       data-controller="coursecode-form-handler"
app/views/courses/_course_code_form.html.erb:11:       data-coursecode-form-handler-url-value="<%= update_coursecode_course_path(course) %>">
app/views/courses/_course_code_form.html.erb:27:          <input type="radio" name="coursecode_enabled" value="true" id="coursecode_enabled_true"
app/views/courses/_course_code_form.html.erb:28:                 <%= 'checked' if course.coursecode_enabled %>
app/views/courses/_course_code_form.html.erb:30:                 data-action="change->coursecode-form-handler#toggle"> Yes
app/views/courses/_course_code_form.html.erb:33:          <input type="radio" name="coursecode_enabled" value="false" id="coursecode_enabled_false"
app/views/courses/_course_code_form.html.erb:34:                 <%= 'checked' unless course.coursecode_enabled %>
app/views/courses/_course_code_form.html.erb:36:                 data-action="change->coursecode-form-handler#toggle"> No
app/views/courses/_course_code_form.html.erb:42:    <% if course.coursecode_enabled %>
app/views/courses/_course_code_form.html.erb:45:          <label for="coursecode" class="absolute top-2 left-4 text-xs font-medium text-on-surface-variant">Course Join Code</label>
app/views/courses/_course_code_form.html.erb:46:          <input type="text" id="coursecode" disabled readonly
app/views/courses/_course_code_form.html.erb:47:                 data-coursecode-form-handler-target="codeInput"
app/views/courses/_course_code_form.html.erb:48:                 value="<%= course.coursecode %>" placeholder="—" autocomplete="off"
app/views/courses/_course_code_form.html.erb:52:                  data-action="click->coursecode-form-handler#copy"
app/views/courses/_course_code_form.html.erb:55:                  <%= 'disabled' if course.coursecode.blank? %>>
app/views/courses/_course_code_form.html.erb:56:            <span data-coursecode-form-handler-target="copyIcon" class="material-symbols-outlined text-[18px]">content_copy</span>
app/views/courses/_course_code_form.html.erb:61:                data-action="click->coursecode-form-handler#generate"
app/views/courses/_course_code_form.html.erb:64:          <%= course.coursecode.present? ? 'Re-Generate Join Code' : 'Generate Join Code' %>
app/views/courses/_copy_course_details.html.erb:2:  <%= form_with url: import_details_course_path(target), method: :post, class: "flex flex-col h-full max-h-[75vh]", data: { turbo: false } do |f| %>
app/views/landing/show.html.erb:190:@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}.jump-list{scroll-behavior:auto}*{transition:none!important}}
app/views/homescreen/_join_by_code_form.html.erb:3:    <%= form.label :coursecode,
app/views/homescreen/_join_by_code_form.html.erb:7:      <%= form.text_field :coursecode,
app/views/layouts/application.html.erb:19:    <%= javascript_importmap_tags %>
app/views/topics/_copy_topic_details.html.erb:2:  <%= form_with url: import_details_course_path(target), method: :post, class: "flex flex-col h-full max-h-[85dvh]" do |f| %>
app/views/styleguide/show.html.erb:23:  .styleguide-mobile-stage .min-\[1245px\]\:hidden { display: flex !important; }
config/routes.rb:17:  post 'invite', to: 'courses#enroll_via_coursecode', as: 'invite'
config/routes.rb:51:      post 'update_coursecode'
config/routes.rb:56:      post 'import_details'

### END
~~~~

### A.1.7  `grep -rnE "\.call\b|def call|def execute|\.execute\b|def self\." app/services app/controllers`

Service entry-point shapes: `call`, `execute`, class methods.

~~~~
### CMD: grep -rnE "\.call\b|def call|def execute|\.execute\b|def self\." app/services app/controllers

app/services/supervisor_capacity_updater.rb:32:    base = Queries::SupervisorCapacityCalculator.new(@course, lecturer_enrolments: all_lecturers).execute.base
app/services/user_details_validator.rb:4:  def self.call(name:, password:, password_confirmation:)
app/services/queries/supervisor_capacity_calculator.rb:53:    def execute
app/services/queries/group_size_confirmability_calculator.rb:11:    def execute
app/services/queries/group_size_confirmability_calculator.rb:26:    def self.feasible_count?(count, group_min, group_max)
app/services/queries/group_size_confirmability_calculator.rb:41:    def execute_quota(group_min, group_max)
app/services/queries/group_size_confirmability_calculator.rb:59:    def execute_min_max(group_min, group_max)
app/services/user_creator.rb:4:  def self.call(name:, email:, password:, verify_only:, instid: nil)
app/controllers/user_controller.rb:62:    result = UserDetailsValidator.call(name: name, password: params[:password], password_confirmation: params[:password_confirmation])
app/controllers/user_controller.rb:69:    result = UserCreator.call(name: name, email: email, password: params[:password], verify_only: true)
app/controllers/user_controller.rb:103:    result = UserDetailsValidator.call(name: name, password: params[:password], password_confirmation: params[:password_confirmation])
app/controllers/lecturers_controller.rb:6:    @capacity_result = Queries::SupervisorCapacityCalculator.new(@course).execute
app/controllers/lecturers_controller.rb:25:    @capacity_result = Queries::SupervisorCapacityCalculator.new(@course).execute
app/controllers/people_controller.rb:18:    @capacity_result = Queries::SupervisorCapacityCalculator.new(@course).execute
app/controllers/courses_controller.rb:415:    result = Queries::GroupSizeConfirmabilityCalculator.new(@course, students_to_group: student_count).execute
app/controllers/courses_controller.rb:444:    @capacity_result = Queries::SupervisorCapacityCalculator.new(@course).execute
app/controllers/courses_controller.rb:464:          result = UserCreator.call(
app/controllers/courses_controller.rb:515:        result = UserCreator.call(
app/controllers/courses_controller.rb:546:        result = UserCreator.call(
app/controllers/projects_controller.rb:98:    Queries::SupervisorCapacityCalculator.new(@course).execute.lecturer_capacities.each do |lc|
app/controllers/projects_controller.rb:141:    capacity_result = Queries::SupervisorCapacityCalculator.new(@course).execute

### END
~~~~

### A.1.8  `grep -rnE "TODO|FIXME|HACK|XXX" app test`

Outstanding markers in app and test.

~~~~
### CMD: grep -rnE "TODO|FIXME|HACK|XXX" app test

grep: app/assets/images/landing/Projects actions.png: binary file matches
grep: app/assets/images/landing/Project_templates.png: binary file matches
app/views/project_templates/edit.html.erb:78:              <%# TODO: refactor to pinned columns (17/20/13/15/20/7/8) %>

### END
~~~~

### A.2. Branch commits touching grouping

One line per commit on `main..HEAD` that either touches a grouping path
(`app/services/group_*`, `app/models/project_group*`, `app/controllers/project_group*`,
`app/policies/project_group*`, `app/views/project_group*`, `db/migrate/*`) or whose
message mentions grouping. Merges are marked `[merge]`. Format:
`<date>  <short sha>  <subject>`.

~~~~
2026-05-05  bf6d5775  Merge branch 'feat/grouping-settings' of https://github.com/hackerspacemmu/ProPro into feat/grouping-settings  [merge]
2026-05-07  72d86c16  feat: Coordinator actions controller and models
2026-05-08  156308be  feat: Coordinator grouping actions boilerplate
2026-05-09  2c134951  Stop linter from complaining
2026-05-09  2e833c40  formatting
2026-05-09  3a05073f  change
2026-05-09  57524cec  Add autocomplete attribute
2026-05-13  0a52ca20  More merge conflict resolutions
2026-05-13  17671eaa  committing first
2026-05-13  62af14c4  Merge with main  [merge]
2026-05-13  b4852a99  resolve merge conflict
2026-05-13  deac676f  Add autocomplete to stop linter from complaining
2026-05-13  ec007fa2  Another autocomplete
2026-05-15  dcc6fd09  feat: Grouping breadcrumb
2026-05-15  f924317d  formatting: Add autocomplete
2026-05-16  6f4c2dfd  Add Grouping warning banner
2026-05-19  2fbe8814  Committing first
2026-05-19  aa5cdb52  feat: got modal and drop to be working
2026-05-19  ca271805  feat: added popup to add student to group for coordinator
2026-05-20  8d4db684  seeds
2026-05-21  6ac1fc54  merging ying tong's branch  [merge]
2026-05-21  ac056548  feat: attempting to merge with yingtong's branch
2026-05-22  21a8c557  Merge branch 'main' into feat/grouping-settings  [merge]
2026-05-22  29ba6b33  merged yingtong branch #2, added create new group
2026-05-23  0bf45cfb  Add autocomplete
2026-05-23  173dfb1f  fix linter complaints
2026-05-23  1af8fe33  commit to see what linter is complaining about
2026-05-23  79ffcca9  fix: Add students
2026-05-23  a61dbc34  fix: Remove student from group
2026-05-24  4c86e286  testing out rubocop
2026-05-24  4f5f1e53  reverting rubocop linting and formatting test
2026-05-24  701fcc5d  test: rubocop test #3
2026-05-24  d82d00cd  test: testing out rubocop #2
2026-05-25  492f2c55  feat: Add missing grouping configuration options in grouping page
2026-05-25  97266c1f  feat: Project groups index page works now
2026-05-25  a992b2ce  feat: Add warning banner when grouping is toggled off
2026-05-25  fc750a36  Visual feedback for enforcing student_list_finalised
2026-05-30  db598df1  linting asdadsdads
2026-05-30  db654cb3  feat: added empty state for groups
2026-05-31  8ed23b3c  feat: added migration for project_group_invites, updated model methods, wrote tests
2026-05-31  9bc44e89  temp
2026-07-14  5e1daba7  feat: removed force_confirm, added migrations for adding tokens to invites & adding timestamp for projectgroups dissolved at
2026-07-14  7b0dc2d7  refactor: moving group size calculator from model into service  [merge]
2026-07-14  df2707b4  linting
2026-07-22  79140be7  linter
2026-07-22  8b8147bf  feat: added default mode to group size calc and group comfirmer/reverter
2026-07-24  2977d6a3  feat: updated pundit for group confirmer/revert ad added error messages, updated test cases and call sites in controllers to up to date for execute method
2026-07-24  42e76c86  linter
2026-07-24  ea98ef2b  fixing remaining test cases
2026-07-25  aa4ecfcc  linter
2026-07-25  c8e571e1  feat: added group member remover service
2026-07-27  0b112a91  linter
2026-07-27  353d5e92  removing dissolved at timestamp project groups
2026-07-30  04eb3446  linter
2026-07-30  94677806  feat: added student create groups + student join services
2026-08-04  6fbc6430  feat: added invites/requests
2026-08-04  b800ad13  linter
2026-08-07  139cf85f  linter
2026-08-07  1e4e4803  fix: added autocomplete field cause linter screaming
2026-08-07  2aecce42  linter
2026-08-07  350ddd9e  feat: refactored the project group invites tables
2026-08-07  601ab904  linter
2026-08-07  ba9feeda  linter
2026-08-11  3bb88bad  linter
2026-08-11  dcf494af  feat: finished group invite links redeem
2026-08-12  52052e28  feat: styling
2026-08-12  798650f8  linter
2026-08-13  51a3af17  feat: added new seeds and fixed a few style bugs
2026-08-17  416819a0  feat: refactored flash
2026-08-17  c0172f02  linter
2026-08-20  9fb34b9b  feat: changed groupsizelegalitycalculator to groupsizeconfirmabilitycalculator
2026-08-20  a48f894f  linter
2026-08-21  429b676f  HUGEEE TEST CASES
2026-08-21  c27072d5  feat: adding validations to grouping
2026-08-21  f39f918d  linter
2026-08-22  2b84b6e9  finishing up
2026-08-22  ff6b1909  feat: updated auto elibility mode text
2026-08-23  06f6b521  feat: changing some user facing terms for grouping
2026-10-21  8a35e745  Merge branch 'main' into feat/student-grouping-crud  [merge]
~~~~

### A.3. Schema and migration state

**FACT** - `db/schema.rb` declares `ActiveRecord::Schema[8.0].define(version: 2026_10_01_123305)`
(`db/schema.rb:13`). The **same version string** is on `origin/main`, but the file
contents differ: main has none of the grouping tables. The eight grouping migrations
on this branch are all dated *before* that schema version, so the schema on this
branch already includes them.

| Migration | Effect | Still on this branch? |
|---|---|---|
| `20260714065220_add_dissolved_at_to_project_groups.rb` | adds `dissolved_at` | superseded |
| `20260726153230_remove_dissolved_at_from_project_groups.rb` | drops `dissolved_at` | yes - groups are hard-deleted |
| `20260714065259_add_token_and_expires_at_to_project_group_invites.rb` | adds token/expiry to invites | superseded |
| `20260806113423_reshape_project_group_invites.rb` | moves token/expiry to a new links table, adds `kind` | yes |
| `20260531093000_create_project_group_invites.rb` | creates the invites table | yes (reshaped) |
| `20260806113610_create_project_group_invite_links.rb` | creates the links table | yes |
| `20260811072831_fix_direct_invite_sender_unique_index.rb` | fixes the partial unique index | yes |
| `20260811102449_add_lecturers_can_manage_groups_to_courses.rb` | adds `lecturers_can_manage_groups` | yes |

**FACT** - the grouping-relevant schema excerpt is dumped verbatim in
`docs/grouping_backend_dump.md`, section E1.

~~~~
$ git diff main --stat -- db/schema.rb
 db/schema.rb | 74 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 74 insertions(+)
~~~~

---

# Excluded / not found

| Expected | Found? | Note |
|---|---|---|
| A `Group::` namespace directory | **NO** | All eleven grouping services are flat in `app/services/`. The convention document only mandates `module Queries` for query objects (`docs/Abstraction/service_classes.md:9`); it does not require a namespace for command services. |
| A shared `ServiceResult` module | **NO** | `grep -rn "ServiceResult" app lib test` -> zero hits. The module appears only as an illustrative snippet inside `docs/Abstraction/service_classes.md:88-92`. |
| `test/services/group_member_remover_test.rb` | **NO** | `GroupMemberRemover` has no service-level test file. |
| `test/policies/` directory | **NO** | No policy in `app/policies/` has a direct test. |
| `test/fixtures/` directory | **NO** | All test data comes from FactoryBot. |
| `app/models/concerns/*.rb` | **NO** | Only `.keep`. |
| `app/jobs/*group*.rb` | **NO** | `app/jobs/` contains only `application_job.rb`. |
| A "link" kind on `ProjectGroupInvite` | **NO** | `enum :kind, { direct_request: 0, direct_invite: 1 }` (`app/models/project_group_invite.rb:6`). Links are a separate model/table. |
| `force_confirm` | **NO** | Removed in `5e1daba7`; zero hits repo-wide. |
| `dissolved_at` on `project_groups` | **NO** | Added and then removed on this branch. |
| Coverage tooling | **NO** | No `simplecov` in `Gemfile`/`Gemfile.lock`, no `test/coverage/`. |
| `CONTEXT.md` grouping glossary | **NO** | `CONTEXT.md` has no grouping section; the two grouping ADRs are dumped in `docs/grouping_backend_dump.md`, section G. |
| `STUDENT_GROUPING_ARCHITECTURE.md`, `STUDENT_GROUPING_CRUD_TASKS.md`, `STUDENT_GROUPING_REFERENCE.md` | **NO** | Listed in `.gitignore`, not present in the working tree, not tracked. |
| `ProPro_Design/groups_tab_mockup.html.erb` | **YES, not included** | An HTML design mockup under a gitignored directory - not backend material. |

## Capture fidelity

- The eight search blocks are complete stdout, including a `### END` marker appended
  by the capture script so that truncation would be visible.
- Block A.1.8 is the only one that is not pure stdout: `grep` reports
  `grep: app/assets/images/landing/Projects actions.png: binary file matches` instead
  of a matching line, because the file is a PNG. That line is reproduced verbatim.
- The commit list in A.2 was generated with `git log main..HEAD` filtered by touched
  path and by message, then sorted by date; it is not a literal `git log` transcript.
- No secrets are included: `config/master.key`, `config/credentials*` and any `.env*`
  file were never read, and no token or key value appears in any block.
