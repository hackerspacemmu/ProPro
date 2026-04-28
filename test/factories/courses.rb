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

    after(:create) do |course|
      template = course.build_project_template
      template.project_template_fields.build(
        label: 'Project Title',
        field_type: 'shorttext',
        applicable_to: 'both',
        is_project_title: true
      )
      template.save!
    end

    trait :grouped do
      grouped { true }
    end
  end
end