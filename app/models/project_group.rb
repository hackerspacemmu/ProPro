class ProjectGroup < ApplicationRecord
  has_many :project_group_members, dependent: :destroy
  belongs_to :course

  has_many :users, through: :project_group_members
  has_one :project, dependent: :destroy, as: :owner
  has_many :project_group_invites, dependent: :destroy

  def can_confirm?
    if course.student_list_finalised?
      result = course.group_size_distribution
      return false if result.nil? || result[:error].present?

      result[:groups].map { |e| e[:size] }.include?(project_group_members.count)
    else
      project_group_members.count >= course.group_min.to_i && project_group_members.count <= course.group_max.to_i
    end
  end

  def confirm!
    transaction do
      with_lock do
        return false unless can_confirm?
        update!(confirmed: true)
      end
    end
  end

  def add_member!(user, is_coordinator: false)
    transaction do
      raise StandardError, "Error: #{user.name} is already in a group for this course." if course.project_group_members.exists?(user: user)

      raise StandardError, "This group has reached the maximum limit of #{course.group_max} members." if !is_coordinator && (project_group_members.count >= course.group_max.to_i)

      project_group_members.create!(user: user)
    end
    true
  end

  def remove_member!(user)
    transaction do
      member = project_group_members.find_by!(user_id: user.id)
      was_leader = (leader_id == user.id)

      member.destroy!

      # Reload to get accurate count after deletion
      remaining = project_group_members.reload

      if remaining.none?
        dissolve!    # group destroyed — caller must not use self after this
        return
      end

      assign_next_leader! if was_leader

      # A confirmed group that no longer meets its legal size reverts to draft.
      revert_to_draft! if confirmed? && !can_confirm?
    end
  end

  def revert_to_draft!
    update!(confirmed: false)
  end

  # Promotes the earliest-joined remaining member to group leader.
  # If no members remain, dissolves the group.
  # Returns the new leader User, or nil if dissolved.
  def assign_next_leader!
    successor_member = project_group_members.order(created_at: :asc).first

    if successor_member
      update!(leader_id: successor_member.user_id)
      successor_member.user
    else
      dissolve!
      nil
    end
  end

  # Hard-deletes the group and its pending invites.
  # Projects associated with this group become orphaned — they are NOT deleted.
  # Call only when last member leaves or coordinator removes last member.
  def dissolve!
    transaction do
      project_group_invites.destroy_all
      destroy!
    end
  end

  def pending_requests
    project_group_invites.pending
  end

  # Returns true if this group has at least one associated project.
  def has_project?
    project.exists?
  end

  def leader?(user)
    leader_id == user.id
  end

  # coordinator can force confirm regardless of the value of can_confirm
  def force_confirm!
    update!(confirmed: true)
  end
end
