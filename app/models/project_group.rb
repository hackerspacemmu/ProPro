class ProjectGroup < ApplicationRecord
  enum :origin, { formation: 'formation', import: 'import' }, prefix: true, validate: true

  has_many :project_group_members, dependent: :destroy
  belongs_to :course

  has_many :users, through: :project_group_members
  has_one :project, dependent: :destroy, as: :owner
  has_many :project_group_invites, dependent: :destroy
  has_many :project_group_invite_links, dependent: :destroy

  validates :group_name, presence: true, uniqueness: { scope: :course_id }

  # Membership changes touch the group. Notify both grouping pages only after
  # the transaction commits, so counts, leadership and status refresh together.
  after_commit :refresh_grouping_displays

  def leader?(user)
    leader_id == user.id
  end

  def confirmable?
    count = project_group_members.count
    return course.size_within_limits?(count) unless course.student_list_finalised?

    Queries::GroupSizeConfirmabilityCalculator
      .new(course, students_to_group: course.unconfirmed_students_count)
      .execute
      .confirmable_size?(count)
  end

  # Reopens a confirmed group as not confirmed with a fresh Tmp number.
  # Callers hold the course and group locks. Pending join requests are dropped
  # because a request only makes sense on a confirmed group.
  def reopen!
    project_group_invites.direct_request.pending.delete_all
    clear_invite_links!
    update!(confirmed: false, group_name: course.lowest_free_tmp_group_name)
    group_name
  end

  # A shareable link only makes sense while the group is open for new members.
  def clear_invite_links!
    project_group_invite_links.delete_all
  end

  private

  def refresh_grouping_displays
    Turbo::StreamsChannel.broadcast_refresh_to(course, :grouping)
  end
end
