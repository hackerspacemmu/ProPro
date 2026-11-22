module Groups
  # Shared group-row locking with a deleted-group sentinel.
  module GroupLocking
    GROUP_GONE = Object.new.freeze

    private

    # Locks the group row and yields it. A group deleted while we were waiting
    # for the lock comes back as GROUP_GONE instead of a raw RecordNotFound.
    def with_group_lock(group)
      gone = false

      result = group.transaction do
        begin
          group.lock!
        rescue ActiveRecord::RecordNotFound => e
          raise unless e.model == group.class.name

          gone = true
          next
        end

        yield group
      end

      gone ? GROUP_GONE : result
    end
  end
end
