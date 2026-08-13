# Coordinator/lecturer adds a student directly to a group bypassing group legality.
# group_max is still checked.
class GroupMemberAdder
  def initialize(group, user:, current_user:)
    @group = group
    @user = user
    @current_user = current_user
  end

  def add!
    course = @group.course

    return blocked(:already_grouped) if course.project_group_members.exists?(user_id: @user.id)
    return blocked(:group_full) if group_full?(course)

    @group.with_lock do
      ProjectGroupMember.create!(user: @user, project_group: @group)
      Result.new(added: true, blocked_reason: nil)
    end
  end

  private

  def group_full?(course)
    course.group_max.present? && @group.project_group_members.count >= course.group_max
  end

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
      when :group_full then 'This group has reached its maximum size.'
      end
    end
  end
end
