class Group < ApplicationRecord
    enum :group_role, { student: 0, instructor: 1, coordinator: 2 }
end
