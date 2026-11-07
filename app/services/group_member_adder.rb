# Coordinator/lecturer adds a student directly to a group. Coordinators may
# exceed group_max; the checks run inside the locks so a concurrent write cannot
# slip a non-enrolled or already-grouped student in.
class GroupMemberAdder
  include Groups::GroupLocking

  def initialize(group, user:, current_user:)
    @group = group
    @user = user
    @current_user = current_user
  end

  def add!
    course = @group.course

    result = course.with_no_key_update_lock do
      with_group_lock(@group) do
        return blocked(:not_enrolled) unless course.enrolments.exists?(user_id: @user.id, role: :student)
        return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @user.id)

        return blocked(:already_grouped) unless ProjectGroupMember.add(user: @user, group: @group)

        ProjectGroupInvite.clear_pending_for!(@user, course)

        Result.new(added: true, blocked_reason: nil)
      end
    end

    return blocked(:group_gone) if result.equal?(Groups::GroupLocking::GROUP_GONE)

    result
  end

  private

  def blocked(reason)
    Result.new(added: false, blocked_reason: reason)
  end

  class Result
    attr_reader :blocked_reason

    def initialize(added:, blocked_reason:)
      @added = added
      @blocked_reason = blocked_reason
    end

    def added? = @added
    def blocked? = !added?

    def message
      return 'Student added to group.' if added?

      case blocked_reason
      when :already_grouped then 'This student is already in a group for this course.'
      when :not_enrolled then 'This student is not enrolled in this course.'
      when :group_gone then 'This group no longer exists.'
      end
    end
  end
end
