# frozen_string_literal: true

namespace :one_time do
  desc "Remove 'S-' prefix from student IDs in the database"
  task remove_student_id_prefix: :environment do
    User.where('student_id LIKE ?', 'S-%').find_each do |user|
      old_id = user.instid
      user.instid = user.instid.sub(/^S-/, '')
      if user.save
        puts "Updated student ID for User ID #{user.id} (#{old_id} -> #{user.instid})"
      else
        puts "Failed to update User ID #{user.id}: #{user.errors.full_messages.join(', ')}"
      end
    end
  end
end
