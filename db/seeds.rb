# Create Users
willie = User.create!(
  email_address: "willie@mmu.edu.my",
  username: "Willie Poh",
  has_registered: true,
  student_id: nil,
  web_link: "willie",
  is_staff: true,
  password: "password123"
)

suhaini = User.create!(
  email_address: "suhaini@mmu.edu.my", 
  username: "Suhaini Nordin",
  has_registered: true,
  student_id: nil,
  web_link: "suhaini",
  is_staff: true,
  password: "password123"
)

alex = User.create!(
  email_address: "alex@student.mmu.edu.my",
  username: "Alex Chiam",
  has_registered: true,
  student_id: "1191202123",
  web_link: "alex_student",
  is_staff: false,
  password: "password123"
)

soo = User.create!(
  email_address: "soo@student.mmu.edu.my",
  username: "Soo Shi Jian", 
  has_registered: true,
  student_id: "1191202124",
  web_link: "soo_student",
  is_staff: false,
  password: "password123"
)

niilesh = User.create!(
  email_address: "niilesh@student.mmu.edu.my",
  username: "Niilesh",
  has_registered: true, 
  student_id: "1191202125",
  web_link: "niilesh_student",
  is_staff: false,
  password: "password123"
)

# Create Courses
course_no_groups = Course.create!(
  course_name: "Subject Solo FreeTopic",
  number_of_updates: 8,
  starting_week: 2,
  student_access: "own_lecturer_only",
  lecturer_access: false,
  grouped: false,
  supervisor_projects_limit: 10,
  require_coordinator_approval: false,
  use_progress_updates: false
)

course_with_groups = Course.create!(
  course_name: "Subject Groups TopicApprovals", 
  number_of_updates: 5,
  starting_week: 2,
  student_access: "no_restriction",
  lecturer_access: true,
  grouped: true,
  supervisor_projects_limit: 6,
  require_coordinator_approval: true,
  use_progress_updates: true
)

# Create Enrolments
willie_coordinator_enrolment = Enrolment.create!(
  user: willie,
  course: course_no_groups,
  role: :coordinator
)

willie_lecturer_enrolment = Enrolment.create!(
  user: willie,
  course: course_no_groups,
  role: :lecturer
)

suhaini_lecturer_enrolment = Enrolment.create!(
  user: suhaini,
  course: course_no_groups,
  role: :lecturer
)

alex_student_enrolment = Enrolment.create!(
  user: alex,
  course: course_no_groups,
  role: :student
)

willie_coordinator_groups_enrolment = Enrolment.create!(
  user: willie,
  course: course_with_groups,
  role: :coordinator
)

willie_lecturer_groups_enrolment = Enrolment.create!(
  user: willie,
  course: course_with_groups,
  role: :lecturer
)

soo_student_enrolment = Enrolment.create!(
  user: soo,
  course: course_with_groups,
  role: :student
)

niilesh_student_enrolment = Enrolment.create!(
  user: niilesh,
  course: course_with_groups,
  role: :student
)

# Create Project Group
blabla_group = ProjectGroup.create!(
  group_name: "Blabla",
  course: course_with_groups
)

# Create Project Group Members
ProjectGroupMember.create!(
  user: soo,
  project_group: blabla_group
)

ProjectGroupMember.create!(
  user: niilesh,
  project_group: blabla_group
)

# Create Project Templates
individual_template = ProjectTemplate.create!(
  course: course_no_groups,
  description: "Individual project proposal template"
)

group_template = ProjectTemplate.create!(
  course: course_with_groups,
  description: "Group project proposal template"
)

# Create Project Template Fields 
project_description_field = ProjectTemplateField.create!(
  project_template: individual_template,
  field_type: 1, 
  applicable_to: 0, 
  label: "Project Description", 
  hint: "Describe your project objectives and scope"
)

lecturer_feedback_field = ProjectTemplateField.create!(
  project_template: individual_template,
  field_type: 1, 
  applicable_to: 1, 
  label: "Lecturer Feedback",
  hint: "Provide feedback on the proposal"
)

# Create Project Template Fields for Group Template
group_description_field = ProjectTemplateField.create!(
  project_template: group_template,
  field_type: 1, # textarea
  applicable_to: 0, # student
  label: "Group Project Description",
  hint: "Describe the group project scope and member responsibilities"
)

# Create Ownerships
alex_ownership = Ownership.create!(
  owner: alex,
  ownership_type: :student
)

suhaini_ownership = Ownership.create!(
  owner: suhaini,
  ownership_type: :lecturer
)

group_ownership = Ownership.create!(
  owner: blabla_group,
  ownership_type: :project_group
)

# Create OTPs
Otp.create!(
  user: soo,
  otp: "123456",
  token: "d46c8b1e-f6b7-4b1c-ad1b-baf8c6f8b87e"
)

Otp.create!(
  user: willie,
  otp: "654321",
  token: "c69bf258-ec55-4f06-900a-d4cd298308e1"
)

# Create Sessions
Session.create!(
  user: willie,
  ip_address: "192.168.1.100",
  user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
)

Session.create!(
  user: alex,
  ip_address: "192.168.1.101", 
  user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
)

puts "Seeded successfully!"