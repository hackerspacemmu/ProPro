FactoryBot.define do
  factory :project_template_field do
    association :project_template
    label { 'Case Study Title' }
    field_type { :shorttext }
    applicable_to { :both }
    required { false }
    is_project_title { false }

    trait :title_field do
      label { 'Project Title' }
      is_project_title { true }
      required { true }
    end
  end
end