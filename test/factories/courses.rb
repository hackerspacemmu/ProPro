FactoryBot.define do
  factory :course do
    course_name { Faker::Educator.course_name }
    grouped { false }
    supervisor_projects_limit { 5 }
    starting_week { 1 }
    student_access { :no_restriction }
    lecturer_access { true }
    use_progress_updates { false }
    require_coordinator_approval { false }
  end

  trait :grouped do
    grouped { true }
  end
end