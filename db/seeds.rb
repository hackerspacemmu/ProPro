# Create Users
willie = User.create!(
  email_address: "willie@mmu.edu.my",
  username: "willie",
  has_registered: true,
  student_id: nil,
  web_link: "willie",
  is_staff: true,
  password: "password123"
)

suhaini = User.create!(
  email_address: "suhaini@mmu.edu.my", 
  username: "suhaini",
  has_registered: true,
  student_id: nil,
  web_link: "suhaini",
  is_staff: true,
  password: "password123"
)

alex = User.create!(
  email_address: "alex@student.mmu.edu.my",
  username: "alex",
  has_registered: true,
  student_id: "1191202123",
  web_link: "alex_student",
  is_staff: false,
  password: "password123"
)

soo = User.create!(
  email_address: "soo@student.mmu.edu.my",
  username: "soo", 
  has_registered: true,
  student_id: "1191202124",
  web_link: "soo_student",
  is_staff: false,
  password: "password123"
)

niilesh = User.create!(
  email_address: "niilesh@student.mmu.edu.my",
  username: "niilesh",
  has_registered: true, 
  student_id: "1191202125",
  web_link: "niilesh_student",
  is_staff: false,
  password: "password123"
)

# Create Courses
course_no_groups = Course.create!(
  course_name: "CSP1123NoGroups",
  number_of_updates: 3,
  starting_week: 1,
  student_access: "no_restriction",
  lecturer_access: true,
  grouped: false,
  supervisor_projects_limit: 10,
  require_coordinator_approval: false,
  use_progress_updates: false
)

course_with_groups = Course.create!(
  course_name: "SubjectUsingGroups", 
  number_of_updates: 2,
  starting_week: 2,
  student_access: "own_lecturer_only",
  lecturer_access: false,
  grouped: true,
  supervisor_projects_limit: 6,
  require_coordinator_approval: false,
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
  #course: course_with_groups,
  project_group: blabla_group
)

ProjectGroupMember.create!(
  user: niilesh,
  #course: course_with_groups,
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
project_title_field = ProjectTemplateField.create!(
  project_template: individual_template,
  field_type: 0, 
  applicable_to: 0, 
  label: "Project Title",
  hint: "Enter a descriptive title for your project",
)

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
group_title_field = ProjectTemplateField.create!(
  project_template: group_template,
  field_type: 0, # text
  applicable_to: 0, # student
  label: "Group Project Title",
  hint: "Enter the group project title",
)

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

# Create Projects
alex_project = Project.create!(
  ownership: alex_ownership,
  course_id: alex_student_enrolment.course_id,
  enrolment: willie_lecturer_enrolment
)

suhaini_project = Project.create!(
  ownership: suhaini_ownership,
  course_id: suhaini_lecturer_enrolment.course_id,
  enrolment: willie_lecturer_enrolment
)

group_project = Project.create!(
  ownership: group_ownership,
  course_id: soo_student_enrolment.course_id,
  enrolment: willie_lecturer_enrolment
)

# Create Project Instances
alex_instance_v1 = ProjectInstance.create!(
  project: alex_project,
  version: 1,
  created_by: alex,
  submitted_at: "2025-07-15 10:30:00",
  title: "Happy Go Lucky",
  status: "rejected",
  #enrolment: willie_lecturer_enrolment
)

suhaini_instance = ProjectInstance.create!(
  project: suhaini_project,
  version: 1,
  created_by: suhaini,
  submitted_at: "2025-07-10 14:20:00",
  title: "My Nice Topic",
  status: "pending",
  #enrolment: willie_lecturer_enrolment
)

group_instance = ProjectInstance.create!(
  project: group_project,
  version: 1, 
  created_by: soo,
  submitted_at: "2025-07-18 16:45:00",
  title: "Difficult Group Project",
  status: "pending",
  #enrolment: willie_lecturer_enrolment
)

alex_instance_v2 = ProjectInstance.create!(
  project: alex_project,
  version: 2,
  created_by: alex,
  submitted_at: nil,
  title: "Happy Go Lucky - Revised",
  status: "approved",
  #enrolment: willie_lecturer_enrolment
)

# Create Project Instance Fields
ProjectInstanceField.create!(
  project_instance: alex_instance_v1,
  project_template_field: project_title_field,
  value: "Happy Go Lucky"
)

ProjectInstanceField.create!(
  project_instance: alex_instance_v1,
  project_template_field: project_description_field,
  value: "A mobile app that helps students manage their daily tasks with gamification elements to boost productivity and happiness."
)

ProjectInstanceField.create!(
  project_instance: suhaini_instance,
  project_template_field: project_title_field,
  value: "My Nice Topic"
)

ProjectInstanceField.create!(
  project_instance: suhaini_instance,
  project_template_field: project_description_field,
  value: "Research on machine learning applications in student assessment systems."
)

ProjectInstanceField.create!(
  project_instance: group_instance,
  project_template_field: group_title_field,
  value: "Difficult Group Project"
)

ProjectInstanceField.create!(
  project_instance: group_instance,
  project_template_field: group_description_field,
  value: "Development of a comprehensive student management system with role-based access control. Soo will handle backend development, Niilesh will focus on frontend and UI design."
)

# Create Comments
Comment.create!(
  user: willie,
  project: alex_project,
  text: "Great concept! Please elaborate more on the gamification mechanics and provide a timeline."
)

Comment.create!(
  user: alex,
  project: alex_project,
  text: "Thank you for the feedback. I will include a detailed timeline and gamification strategy in the next version."
)

Comment.create!(
  user: willie,
  project: group_project,
  text: "The scope seems quite ambitious. Consider breaking it down into phases and focus on core features first."
)

# Create Progress Updates
ProgressUpdate.create!(
  project: alex_project,
  rating: 3,
  feedback: "Good progress on initial research and mockups. Need to focus more on technical implementation details."
)

ProgressUpdate.create!(
  project: group_project,
  rating: 0,
  feedback: "No progress update lol."
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
