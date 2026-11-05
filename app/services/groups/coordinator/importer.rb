module Groups
  module Coordinator
    # Places students from a grouped CSV into groups. New groups are created confirmed,
    # led by the first member in CSV order. Students already in another group are
    # reported, not moved.
    class Importer
      def initialize(course)
        @course = course
      end

      # rows: { 'Group name' => [User, ...] }, members in CSV order.
      def import!(rows)
        skipped = []

        @course.with_no_key_update_lock do
          return Result.new(blocked_reason: :not_grouped, skipped: skipped) unless @course.grouped?

          rows.each { |group_name, users| import_group!(group_name, users, skipped) }
        end

        Result.new(blocked_reason: nil, skipped: skipped)
      end

      private

      def import_group!(group_name, users, skipped)
        group = @course.project_groups.find_by(group_name: group_name)
        created = false

        users.each do |user|
          existing = @course.project_group_members.includes(:project_group).find_by(user_id: user.id)

          if existing
            skipped << { user: user, group_name: group_name } unless existing.project_group_id == group&.id
            next
          end

          # Created on first placement, so a group whose members are all skipped is never saved.
          unless group
            group = @course.project_groups.create!(group_name: group_name, confirmed: true, origin: :import)
            created = true
          end

          skipped << { user: user, group_name: group_name } unless ProjectGroupMember.add(user: user, group: group)
        end

        return unless group
        return group.destroy! if created && group.project_group_members.none?

        assign_leader!(group)
      end

      # The CSV has no leader column, so a group without one gets its earliest member.
      def assign_leader!(group)
        return if group.leader_id.present?

        first_member = group.project_group_members.order(:created_at, :id).first
        group.update!(leader_id: first_member.user_id) if first_member
      end

      class Result
        attr_reader :blocked_reason, :skipped

        def initialize(blocked_reason:, skipped:)
          @blocked_reason = blocked_reason
          @skipped = skipped
        end

        def blocked? = blocked_reason.present?
        def skipped? = skipped.any?

        def skipped_messages
          skipped.map { |entry| "#{entry[:user].name} was already in a group and wasn't moved." }
        end
      end
    end
  end
end
