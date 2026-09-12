class Enrolment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  has_many :projects, dependent: :destroy
  enum :role, { lecturer: 0, coordinator: 1, student: 2 }
  validates :supervisor_capacity_offset, numericality: { only_integer: true }, allow_nil: true

  # Enrolls a user in a course using a course code.
  # Validates that the course exists and that joining via course code is enabled.
  # Returns true if the user was newly enrolled, or false if they were already enrolled.
  def self.enroll_via_coursecode(user, code)
    course = Course.by_coursecode(code).first

    raise 'Invalid course code' unless course
    raise 'Joining via course code is disabled for this course' unless course.coursecode_enabled

    if course.email_domain_restriction_enabled?
      domain_array = (course.email_domain_restriction).split(",").map(&:strip)
      user_email_domain = (user.email_address).sub(/^.*@/, '')
      
      if !domain_array.include?(user_email_domain)
        #Only thing this does is add @ to each domain to make it prettier
        domain_array_string = domain_array.map { |d| " @#{d} " }.join(", ")
        raise "Email Domain Restriction is enabled for this course. Please join using an account linked to an email with #{domain_array_string} ."
      end
    end

    enrolment = find_or_create_by!(
      user: user,
      course: course,
      role: :student
    )

    enrolment.previously_new_record?
  end
end
