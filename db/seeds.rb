# db/seeds.rb
if !Rails.env.development?
  puts "[ db/seeds.rb ] Seed data is for development only, not #{Rails.env}"
  exit 0
end

require 'faker'

Faker::Config.random = Random.new(42)

puts "[ db/seeds.rb ] Destroying existing data..."

ProgressUpdate.destroy_all
Comment.destroy_all
ProjectInstanceField.destroy_all
ProjectInstance.unscoped.destroy_all
TopicInstance.unscoped.destroy_all
Project.unscoped.destroy_all
ProjectGroupMember.destroy_all
ProjectGroup.destroy_all
ProjectTemplateField.destroy_all
ProjectTemplate.destroy_all
Enrolment.destroy_all
User.destroy_all
Course.destroy_all

puts "[ db/seeds.rb ] Creating users..."

lecturers = 3.times.map do |i|
  User.create!(
    email_address: "lecturer#{i + 1}@test.com",
    username: "lecturer#{i + 1}",
    has_registered: true,
    student_id: nil,
    web_link: Faker::Internet.url,
    is_staff: true,
    password: 'password123'
  )
end

students = 15.times.map do |i|
  User.create!(
    email_address: "student#{i + 1}@test.com",
    username: "student#{i + 1}",
    has_registered: true,
    student_id: Faker::Number.unique.number(digits: 10).to_s,
    is_staff: false,
    password: 'password123'
  )
end

puts "[ db/seeds.rb ] Creating courses..."

course_with_groups = Course.create!(
  course_name: 'Grouped TopicApprovalEnabled',
  number_of_updates: 5,
  starting_week: 2,
  student_access: 0,
  lecturer_access: true,
  grouped: true,
  supervisor_projects_limit: 6,
  require_coordinator_approval: true,
  use_progress_updates: true
)

course_no_groups = Course.create!(
  course_name: 'Solo Subject',
  number_of_updates: 8,
  starting_week: 2,
  student_access: 1,
  lecturer_access: false,
  grouped: false,
  supervisor_projects_limit: 10,
  require_coordinator_approval: false,
  use_progress_updates: false
)

puts "[ db/seeds.rb ] Creating enrolments..."

Enrolment.create!(user: lecturers[0], course: course_with_groups, role: :coordinator)
Enrolment.create!(user: lecturers[0], course: course_no_groups, role: :coordinator)

lecturer_enrolments = lecturers.map do |lecturer|
  Enrolment.create!(user: lecturer, course: course_with_groups, role: :lecturer)
end

lecturer_enrolments_no_groups = lecturers.map do |lecturer|
  Enrolment.create!(user: lecturer, course: course_no_groups, role: :lecturer)
end

students.each { |s| Enrolment.create!(user: s, course: course_with_groups, role: :student) }
students.first(5).each { |s| Enrolment.create!(user: s, course: course_no_groups, role: :student) }

puts "[ db/seeds.rb ] Creating project groups..."

groups = 5.times.map do |i|
  ProjectGroup.create!(
    group_name: "group_#{i + 1}",
    course: course_with_groups
  )
end

students.each_slice(3).with_index do |group_students, i|
  group_students.each do |student|
    ProjectGroupMember.create!(user: student, project_group: groups[i])
  end
end

puts "[ db/seeds.rb ] Creating project templates..."

individual_template = ProjectTemplate.create!(
  course: course_no_groups,
  description: 'Individual project proposal template'
)

group_template = ProjectTemplate.create!(
  course: course_with_groups,
  description: 'Group project proposal template'
)

# Individual template fields (student-facing)
individual_student_fields = [
  { label: 'Project Title',          field_type: 0, applicable_to: 1, hint: 'Provide a concise and descriptive title for your project' },
  { label: 'Research Objectives',    field_type: 1, applicable_to: 1, hint: 'List the main objectives your project aims to achieve' },
  { label: 'Problem Statement',      field_type: 1, applicable_to: 1, hint: 'Describe the problem or gap your project addresses' },
  { label: 'Methodology',            field_type: 1, applicable_to: 1, hint: 'Outline the approach and methods you plan to use' },
  { label: 'Expected Outcomes',      field_type: 1, applicable_to: 1, hint: 'Describe the anticipated results and contributions' },
  { label: 'Timeline',               field_type: 1, applicable_to: 1, hint: 'Provide a week-by-week breakdown of your project plan' },
  { label: 'References',             field_type: 1, applicable_to: 1, hint: 'List any references or prior work relevant to your project' }
].map do |f|
  ProjectTemplateField.create!(
    project_template: individual_template,
    field_type: f[:field_type],
    applicable_to: f[:applicable_to],
    label: f[:label],
    hint: f[:hint]
  )
end

# Individual template fields (lecturer-facing)
individual_lecturer_fields = [
  { label: 'Lecturer Feedback',      field_type: 1, applicable_to: 0, hint: 'Provide overall feedback on the proposal' },
  { label: 'Methodology Comments',   field_type: 1, applicable_to: 0, hint: 'Comment on the suitability of the proposed methodology' },
  { label: 'Approval Justification', field_type: 1, applicable_to: 0, hint: 'State the reason for approval, rejection, or revision request' },
].map do |f|
  ProjectTemplateField.create!(
    project_template: individual_template,
    field_type: f[:field_type],
    applicable_to: f[:applicable_to],
    label: f[:label],
    hint: f[:hint]
  )
end

# Shared individual fields (both student and lecturer)
individual_shared_fields = [
  { label: 'Project Title', field_type: 0, applicable_to: 2, hint: nil }
].map do |f|
  ProjectTemplateField.create!(
    project_template: individual_template,
    field_type: f[:field_type],
    applicable_to: f[:applicable_to],
    label: f[:label],
    hint: f[:hint]
  )
end

# Group template fields (student-facing)
group_student_fields = [
  { label: 'Project Title',              field_type: 0, applicable_to: 1, hint: 'Provide a concise and descriptive title for your group project' },
  { label: 'Project Overview',           field_type: 1, applicable_to: 1, hint: 'Summarise the scope and goals of your group project' },
  { label: 'Member Responsibilities',    field_type: 1, applicable_to: 1, hint: 'Describe each group member\'s role and responsibilities' },
  { label: 'Research Questions',         field_type: 1, applicable_to: 1, hint: 'State the key research questions your project will address' },
  { label: 'Proposed Methodology',       field_type: 1, applicable_to: 1, hint: 'Describe the methods and tools your group will use' },
  { label: 'Collaboration Plan',         field_type: 1, applicable_to: 1, hint: 'Explain how the group will coordinate and communicate' },
  { label: 'Risk Assessment',            field_type: 1, applicable_to: 1, hint: 'Identify potential risks and how you plan to mitigate them' },
  { label: 'References',                 field_type: 1, applicable_to: 1, hint: 'List relevant references and background reading' }
].map do |f|
  ProjectTemplateField.create!(
    project_template: group_template,
    field_type: f[:field_type],
    applicable_to: f[:applicable_to],
    label: f[:label],
    hint: f[:hint]
  )
end

# Group template fields (lecturer-facing)
group_lecturer_fields = [
  { label: 'Supervisor Feedback',     field_type: 1, applicable_to: 0, hint: 'Provide feedback on the group\'s proposal' },
  { label: 'Feasibility Assessment',  field_type: 1, applicable_to: 0, hint: 'Assess whether the project scope is achievable within the timeframe' },
].map do |f|
  ProjectTemplateField.create!(
    project_template: group_template,
    field_type: f[:field_type],
    applicable_to: f[:applicable_to],
    label: f[:label],
    hint: f[:hint]
  )
end

# Helper to get a title field for each template
individual_title_field = individual_student_fields.first
group_title_field = group_student_fields.first

puts "[ db/seeds.rb ] Creating topics..."

topic_statuses_with_groups = [
  [:approved, :approved, :pending, :redo],
  [:approved, :approved, :pending, :redo],
  [:approved, :approved, :pending, :rejected]
]

topic_statuses_no_groups = [
  [:rejected, :approved],
  [:redo, :rejected],
  [:pending, :rejected]
]

lecturers.each_with_index do |lecturer, li|
  4.times do |i|
    topic = Topic.create!(
      course: course_with_groups,
      owner: lecturer
    )

    instance = TopicInstance.create!(
      project_id: topic.id,
      version: 1,
      created_by: lecturer,
      title: Faker::Educator.subject,
      status: topic_statuses_with_groups[li][i]
    )

    ProjectInstanceField.create!(instance: instance, project_template_field: individual_title_field, value: instance.title)
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[1], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[2], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[3], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[4], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[5], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[6], value: Faker::Lorem.paragraph(sentence_count: 3))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[0], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[1], value: Faker::Lorem.paragraph(sentence_count: 3))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[2], value: Faker::Lorem.paragraph(sentence_count: 3))
  end
end

lecturers.each_with_index do |lecturer, li|
  2.times do |i|
    topic = Topic.create!(
      course: course_no_groups,
      owner: lecturer
    )

    instance = TopicInstance.create!(
      project_id: topic.id,
      version: 1,
      created_by: lecturer,
      title: Faker::Educator.subject,
      status: topic_statuses_no_groups[li][i]
    )

    ProjectInstanceField.create!(instance: instance, project_template_field: individual_title_field, value: instance.title)
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[1], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[2], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[3], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[4], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[0], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[1], value: Faker::Lorem.paragraph(sentence_count: 3))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[2], value: Faker::Lorem.paragraph(sentence_count: 3))
  end
end

puts "[ db/seeds.rb ] Creating group projects..."

group_project_configs = [
  {
    group: groups[0],
    creator: students[0],
    enrolments: [lecturer_enrolments[1], lecturer_enrolments[1], lecturer_enrolments[2], lecturer_enrolments[0]],
    statuses: [:pending, :redo, :rejected, :approved]
  },
  {
    group: groups[1],
    creator: students[3],
    enrolments: [lecturer_enrolments[0]],
    statuses: [:rejected]
  },
  {
    group: groups[2],
    creator: students[6],
    enrolments: [lecturer_enrolments[0]],
    statuses: [:redo]
  },
  {
    group: groups[3],
    creator: students[9],
    enrolments: [lecturer_enrolments[0]],
    statuses: [:pending]
  }
]

group_project_configs.each do |config|
  project = Project.unscoped.create!(
    course: course_with_groups,
    enrolment: config[:enrolments].last,
    owner: config[:group],
    ownership_type: :project_group
  )

  config[:statuses].each_with_index do |status, v|
    instance = ProjectInstance.create!(
      project: project,
      version: v + 1,
      created_by: config[:creator],
      title: Faker::App.name,
      status: status,
      enrolment: config[:enrolments][v]
    )

    ProjectInstanceField.create!(instance: instance, project_template_field: group_title_field, value: instance.title)
    ProjectInstanceField.create!(instance: instance, project_template_field: group_student_fields[1], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_student_fields[2], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_student_fields[3], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_student_fields[4], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_student_fields[5], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_student_fields[6], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_student_fields[7], value: Faker::Lorem.paragraph(sentence_count: 3))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_lecturer_fields[0], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: group_lecturer_fields[1], value: Faker::Lorem.paragraph(sentence_count: 3))
  end
end

puts "[ db/seeds.rb ] Creating student projects..."

student_project_configs = [
  {
    student: students[0],
    enrolments: [lecturer_enrolments_no_groups[2], lecturer_enrolments_no_groups[2], lecturer_enrolments_no_groups[1], lecturer_enrolments_no_groups[0]],
    statuses: [:pending, :rejected, :redo, :approved]
  },
  {
    student: students[1],
    enrolments: [lecturer_enrolments_no_groups[0]],
    statuses: [:pending]
  },
  {
    student: students[2],
    enrolments: [lecturer_enrolments_no_groups[0]],
    statuses: [:redo]
  },
  {
    student: students[3],
    enrolments: [lecturer_enrolments_no_groups[0]],
    statuses: [:rejected]
  }
]

student_project_configs.each do |config|
  project = Project.unscoped.create!(
    course: course_no_groups,
    enrolment: config[:enrolments].last,
    owner: config[:student],
    ownership_type: :student
  )

  config[:statuses].each_with_index do |status, v|
    instance = ProjectInstance.create!(
      project: project,
      version: v + 1,
      created_by: config[:student],
      title: Faker::App.name,
      status: status,
      enrolment: config[:enrolments][v]
    )

    ProjectInstanceField.create!(instance: instance, project_template_field: individual_title_field, value: instance.title)
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[1], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[2], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[3], value: Faker::Lorem.paragraph(sentence_count: 5))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[4], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[5], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_student_fields[6], value: Faker::Lorem.paragraph(sentence_count: 3))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[0], value: Faker::Lorem.paragraph(sentence_count: 4))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[1], value: Faker::Lorem.paragraph(sentence_count: 3))
    ProjectInstanceField.create!(instance: instance, project_template_field: individual_lecturer_fields[2], value: Faker::Lorem.paragraph(sentence_count: 3))
  end
end

puts "[ db/seeds.rb ] Creating comments..."

group_1_project = Project.unscoped.find_by(owner: groups[0])
group_1_instances = ProjectInstance.unscoped.where(project: group_1_project).order(:version)

comment_configs_group = [
  { users: [lecturers[1], students[0], lecturers[1]], instance: group_1_instances[0] },
  { users: [lecturers[1], students[1], lecturers[1], students[2]], instance: group_1_instances[1] },
  { users: [lecturers[2], lecturers[2]], instance: group_1_instances[2] },
  { users: [lecturers[0], students[2]], instance: group_1_instances[3] }
]

comment_configs_group.each do |config|
  config[:users].each do |user|
    Comment.create!(
      user: user,
      text: Faker::Lorem.paragraph(sentence_count: 4),
      location: config[:instance]
    )
  end
end

student_1_project = Project.unscoped.find_by(owner: students[0], course: course_no_groups)
student_1_instances = ProjectInstance.unscoped.where(project: student_1_project).order(:version)

comment_configs_student = [
  { users: [lecturers[2], students[0], lecturers[2], students[0]], instance: student_1_instances[0] },
  { users: [lecturers[2], lecturers[2], students[0], students[0]], instance: student_1_instances[1] },
  { users: [lecturers[1], lecturers[1], students[0], students[0]], instance: student_1_instances[2] },
  { users: [lecturers[0], students[2], lecturers[0], students[2]], instance: student_1_instances[3] }
]

comment_configs_student.each do |config|
  config[:users].each do |user|
    Comment.create!(
      user: user,
      text: Faker::Lorem.paragraph(sentence_count: 4),
      location: config[:instance]
    )
  end
end

puts "[ db/seeds.rb ] Creating progress updates..."

[group_1_project, student_1_project].each do |project|
  ratings = %i[no_progress unsatisfactory satisfactory excellent]
  start_date = Date.new(2025, 2, 14)

  ratings.each_with_index do |rating, i|
    ProgressUpdate.create!(
      project: project,
      rating: rating,
      feedback: Faker::Lorem.paragraph(sentence_count: 4),
      date: start_date + (i * 7)
    )
  end
end

puts "[ db/seeds.rb ] Done"