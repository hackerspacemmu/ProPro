module Groups
  # Deletes a not-confirmed group on its leader's request while formation is
  # open.
  class Deleter
    def initialize(group)
      @group = group
    end

    def delete!
      @group.with_lock do
        return blocked(:window_closed) unless @group.course.grouping_window_open?
        return blocked(:has_project) if @group.project.present?
        return blocked(:group_confirmed) if @group.confirmed?

        @group.destroy!
        Result.new(deleted: true)
      end
    end

    private

    def blocked(reason)
      Result.new(deleted: false, blocked_reason: reason)
    end

    class Result
      attr_reader :blocked_reason

      def initialize(deleted:, blocked_reason: nil)
        @deleted = deleted
        @blocked_reason = blocked_reason
      end

      def deleted? = @deleted
      def blocked? = !deleted?
      def needs_confirmation? = false

      def message
        return 'Group deleted.' if deleted?

        case blocked_reason
        when :window_closed then 'Group formation is closed.'
        when :has_project then 'This group has a proposal, so only a coordinator can delete it.'
        when :group_confirmed then 'A confirmed group can only be deleted by a coordinator.'
        end
      end
    end
  end
end
