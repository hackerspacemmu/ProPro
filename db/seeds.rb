# Create Users
lecturer1 = User.create!(
  email_address: "lecturer1@test.com",
  username: "lecturer1",
  has_registered: true,
  student_id: nil,
  web_link: "test.com",
  is_staff: true,
  password: "password123"
)

lecturer2 = User.create!(
  email_address: "lecturer2@test.com",
  username: "lecturer2",
  has_registered: true,
  student_id: nil,
  web_link: "test.com",
  is_staff: true,
  password: "password123"
)

lecturer3 = User.create!(
  email_address: "lecturer3@test.com",
  username: "lecturer3",
  has_registered: true,
  student_id: nil,
  web_link: "test.com",
  is_staff: true,
  password: "password123"
)

student1 = User.create!(
  email_address: "student1@test.com",
  username: "student1",
  has_registered: true,
  student_id: "1191202123",
  is_staff: false,
  password: "password123"
)

student2 = User.create!(
  email_address: "student2@test.com",
  username: "student2",
  has_registered: true,
  student_id: "1191202124",
  is_staff: false,
  password: "password123"
)

student3 = User.create!(
  email_address: "student3@test.com",
  username: "student3",
  has_registered: true,
  student_id: "1191202125",
  is_staff: false,
  password: "password123"
)

student4 = User.create!(
  email_address: "student4@test.com",
  username: "student4",
  has_registered: true,
  student_id: "1191202126",
  is_staff: false,
  password: "password123"
)

student5 = User.create!(
  email_address: "student5@test.com",
  username: "student5",
  has_registered: true,
  student_id: "1191202126",
  is_staff: false,
  password: "password123"
)

student6 = User.create!(
  email_address: "student6@test.com",
  username: "student6",
  has_registered: true,
  student_id: "1191202127",
  is_staff: false,
  password: "password123"
)

student7 = User.create!(
  email_address: "student7@test.com",
  username: "student7",
  has_registered: true,
  student_id: "1191202128",
  is_staff: false,
  password: "password123"
)

student8 = User.create!(
  email_address: "student8@test.com",
  username: "student8",
  has_registered: true,
  student_id: "1191202129",
  is_staff: false,
  password: "password123"
)

student9 = User.create!(
  email_address: "student9@test.com",
  username: "student9",
  has_registered: true,
  student_id: "1191202130",
  is_staff: false,
  password: "password123"
)

student10 = User.create!(
  email_address: "student10@test.com",
  username: "student10",
  has_registered: true,
  student_id: "1191202131",
  is_staff: false,
  password: "password123"
)

student11 = User.create!(
  email_address: "student11@test.com",
  username: "student11",
  has_registered: true,
  student_id: "1191202132",
  is_staff: false,
  password: "password123"
)

student12 = User.create!(
  email_address: "student12@test.com",
  username: "student12",
  has_registered: true,
  student_id: "1191202133",
  is_staff: false,
  password: "password123"
)

student13 = User.create!(
  email_address: "student13@test.com",
  username: "student13",
  has_registered: true,
  student_id: "1191202133",
  is_staff: false,
  password: "password123"
)

student14 = User.create!(
  email_address: "student14@test.com",
  username: "student14",
  has_registered: true,
  student_id: "1191202134",
  is_staff: false,
  password: "password123"
)

student15 = User.create!(
  email_address: "student15@test.com",
  username: "student15",
  has_registered: true,
  student_id: "1191202135",
  is_staff: false,
  password: "password123"
)

# Create Courses
course_with_groups = Course.create!(
  course_name: "Grouped TopicApprovalEnabled", 
  number_of_updates: 5,
  starting_week: 2,
  student_access: "no_restriction",
  lecturer_access: true,
  grouped: true,
  supervisor_projects_limit: 6,
  require_coordinator_approval: true,
  use_progress_updates: true
)

course_no_groups = Course.create!(
  course_name: "Solo Subject",
  number_of_updates: 8,
  starting_week: 2,
  student_access: "own_lecturer_only",
  lecturer_access: false,
  grouped: false,
  supervisor_projects_limit: 10,
  require_coordinator_approval: false,
  use_progress_updates: false
)

# Create Enrolments

lecturer_1_coordinator_enrolment = Enrolment.create!(
  user: lecturer1,
  course: course_with_groups,
  role: :coordinator
)

lecturer_1_lecturer_enrolment = Enrolment.create!(
  user: lecturer1,
  course: course_with_groups,
  role: :lecturer
)

lecturer_2_lecturer_enrolment = Enrolment.create!(
  user: lecturer2,
  course: course_with_groups,
  role: :lecturer
)

lecturer_3_lecturer_enrolment = Enrolment.create!(
  user: lecturer3,
  course: course_with_groups,
  role: :lecturer
)


lecturer_1_coordinator_enrolment_no_groups = Enrolment.create!(
  user: lecturer1,
  course: course_no_groups,
  role: :coordinator
)

lecturer_1_lecturer_enrolment_no_groups = Enrolment.create!(
  user: lecturer1,
  course: course_no_groups,
  role: :lecturer
)

lecturer_2_lecturer_enrolment_no_groups = Enrolment.create!(
  user: lecturer2,
  course: course_no_groups,
  role: :lecturer
)

lecturer_3_lecturer_enrolment_no_groups = Enrolment.create!(
  user: lecturer3,
  course: course_no_groups,
  role: :lecturer
)


student_1_grouped_enrolment = Enrolment.create!(
  user: student1,
  course: course_with_groups,
  role: :student
)

student_2_grouped_enrolment = Enrolment.create!(
  user: student2,
  course: course_with_groups,
  role: :student
)

student_3_grouped_enrolment = Enrolment.create!(
  user: student3,
  course: course_with_groups,
  role: :student
)

student_4_grouped_enrolment = Enrolment.create!(
  user: student4,
  course: course_with_groups,
  role: :student
)

student_5_grouped_enrolment = Enrolment.create!(
  user: student5,
  course: course_with_groups,
  role: :student
)

student_6_grouped_enrolment = Enrolment.create!(
  user: student6,
  course: course_with_groups,
  role: :student
)

student_7_grouped_enrolment = Enrolment.create!(
  user: student7,
  course: course_with_groups,
  role: :student
)

student_8_grouped_enrolment = Enrolment.create!(
  user: student8,
  course: course_with_groups,
  role: :student
)

student_9_grouped_enrolment = Enrolment.create!(
  user: student9,
  course: course_with_groups,
  role: :student
)

student_10_grouped_enrolment = Enrolment.create!(
  user: student10,
  course: course_with_groups,
  role: :student
)

student_11_grouped_enrolment = Enrolment.create!(
  user: student11,
  course: course_with_groups,
  role: :student
)

student_12_grouped_enrolment = Enrolment.create!(
  user: student12,
  course: course_with_groups,
  role: :student
)

student_13_grouped_enrolment = Enrolment.create!(
  user: student13,
  course: course_with_groups,
  role: :student
)

student_14_grouped_enrolment = Enrolment.create!(
  user: student14,
  course: course_with_groups,
  role: :student
)

student_15_grouped_enrolment = Enrolment.create!(
  user: student15,
  course: course_with_groups,
  role: :student
)


student_1_no_groups_enrolment = Enrolment.create!(
  user: student1,
  course: course_no_groups,
  role: :student
)

student_2_no_groups_enrolment = Enrolment.create!(
  user: student2,
  course: course_no_groups,
  role: :student
)

student_3_no_groups_enrolment = Enrolment.create!(
  user: student3,
  course: course_no_groups,
  role: :student
)

student_4_no_groups_enrolment = Enrolment.create!(
  user: student4,
  course: course_no_groups,
  role: :student
)

student_5_no_groups_enrolment = Enrolment.create!(
  user: student5,
  course: course_no_groups,
  role: :student
)


# Create Project Group
group_1 = ProjectGroup.create!(
  group_name: "group_1",
  course: course_with_groups
)

group_2 = ProjectGroup.create!(
  group_name: "group_2",
  course: course_with_groups
)

group_3 = ProjectGroup.create!(
  group_name: "group_3",
  course: course_with_groups
)

group_4 = ProjectGroup.create!(
  group_name: "group_4",
  course: course_with_groups
)

group_5 = ProjectGroup.create!(
  group_name: "group_5",
  course: course_with_groups
)

# Create Project Group Members
ProjectGroupMember.create!(
  user: student1,
  project_group: group_1
)

ProjectGroupMember.create!(
  user: student2,
  project_group: group_1
)

ProjectGroupMember.create!(
  user: student3,
  project_group: group_1
)


ProjectGroupMember.create!(
  user: student4,
  project_group: group_2
)

ProjectGroupMember.create!(
  user: student5,
  project_group: group_2
)

ProjectGroupMember.create!(
  user: student6,
  project_group: group_2
)


ProjectGroupMember.create!(
  user: student7,
  project_group: group_3
)

ProjectGroupMember.create!(
  user: student8,
  project_group: group_3
)

ProjectGroupMember.create!(
  user: student9,
  project_group: group_3
)


ProjectGroupMember.create!(
  user: student10,
  project_group: group_4
)

ProjectGroupMember.create!(
  user: student11,
  project_group: group_4
)

ProjectGroupMember.create!(
  user: student12,
  project_group: group_4
)


ProjectGroupMember.create!(
  user: student13,
  project_group: group_5
)

ProjectGroupMember.create!(
  user: student14,
  project_group: group_5
)

ProjectGroupMember.create!(
  user: student15,
  project_group: group_5
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
  applicable_to: 1, 
  label: "Project Description", 
  hint: "Describe your project objectives and scope"
)

lecturer_feedback_field = ProjectTemplateField.create!(
  project_template: individual_template,
  field_type: 1, 
  applicable_to: 0, 
  label: "Lecturer Feedback",
  hint: "Provide feedback on the proposal"
)

group_description_field = ProjectTemplateField.create!(
  project_template: group_template,
  field_type: 1, # textarea
  applicable_to: 1, # student
  label: "Group Project Description",
  hint: "Describe the group project scope and member responsibilities"
)

# Create Ownerships
lecturer_1_topic_1_ownership = Ownership.create!(
  owner: lecturer1,
  ownership_type: :lecturer
)

lecturer_1_topic_2_ownership = Ownership.create!(
  owner: lecturer1,
  ownership_type: :lecturer
)

lecturer_1_topic_3_ownership = Ownership.create!(
  owner: lecturer1,
  ownership_type: :lecturer
)

lecturer_1_topic_4_ownership = Ownership.create!(
  owner: lecturer1,
  ownership_type: :lecturer
)


lecturer_2_topic_1_ownership = Ownership.create!(
  owner: lecturer2,
  ownership_type: :lecturer
)

lecturer_2_topic_2_ownership = Ownership.create!(
  owner: lecturer2,
  ownership_type: :lecturer
)

lecturer_2_topic_3_ownership = Ownership.create!(
  owner: lecturer2,
  ownership_type: :lecturer
)

lecturer_2_topic_4_ownership = Ownership.create!(
  owner: lecturer2,
  ownership_type: :lecturer
)


lecturer_3_topic_1_ownership = Ownership.create!(
  owner: lecturer3,
  ownership_type: :lecturer
)

lecturer_3_topic_2_ownership = Ownership.create!(
  owner: lecturer3,
  ownership_type: :lecturer
)

lecturer_3_topic_3_ownership = Ownership.create!(
  owner: lecturer3,
  ownership_type: :lecturer
)

lecturer_3_topic_4_ownership = Ownership.create!(
  owner: lecturer3,
  ownership_type: :lecturer
)


lecturer_1_topic_1_no_groups_ownership = Ownership.create!(
  owner: lecturer1,
  ownership_type: :lecturer
)

lecturer_1_topic_2_no_groups_ownership = Ownership.create!(
  owner: lecturer1,
  ownership_type: :lecturer
)

lecturer_2_topic_1_no_groups_ownership = Ownership.create!(
  owner: lecturer2,
  ownership_type: :lecturer
)

lecturer_2_topic_2_no_groups_ownership = Ownership.create!(
  owner: lecturer2,
  ownership_type: :lecturer
)

lecturer_3_topic_1_no_groups_ownership = Ownership.create!(
  owner: lecturer3,
  ownership_type: :lecturer
)

lecturer_3_topic_2_no_groups_ownership = Ownership.create!(
  owner: lecturer3,
  ownership_type: :lecturer
)


group_1_ownership = Ownership.create!(
  owner: group_1,
  ownership_type: :project_group
)

group_2_ownership = Ownership.create!(
  owner: group_2,
  ownership_type: :project_group
)

group_3_ownership = Ownership.create!(
  owner: group_3,
  ownership_type: :project_group
)

group_4_ownership = Ownership.create!(
  owner: group_4,
  ownership_type: :project_group
)

student_1_ownership = Ownership.create!(
  owner: student1,
  ownership_type: :student
)

student_2_ownership = Ownership.create!(
  owner: student2,
  ownership_type: :student
)

student_3_ownership = Ownership.create!(
  owner: student3,
  ownership_type: :student
)

student_4_ownership = Ownership.create!(
  owner: student4,
  ownership_type: :student
)

student_5_ownership = Ownership.create!(
  owner: student5,
  ownership_type: :student
)

# Create Projects
lecturer_1_topic_1 = Project.create!(
  ownership: lecturer_1_topic_1_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_2 = Project.create!(
  ownership: lecturer_1_topic_2_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_3 = Project.create!(
  ownership: lecturer_1_topic_3_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_4 = Project.create!(
  ownership: lecturer_1_topic_4_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)


lecturer_2_topic_1 = Project.create!(
  ownership: lecturer_2_topic_1_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_2_topic_2 = Project.create!(
  ownership: lecturer_2_topic_2_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_2_topic_3 = Project.create!(
  ownership: lecturer_2_topic_3_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_2_topic_4 = Project.create!(
  ownership: lecturer_2_topic_4_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)


lecturer_3_topic_1 = Project.create!(
  ownership: lecturer_3_topic_1_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_3_topic_2 = Project.create!(
  ownership: lecturer_3_topic_2_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_3_topic_3 = Project.create!(
  ownership: lecturer_3_topic_3_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_3_topic_4 = Project.create!(
  ownership: lecturer_3_topic_4_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_coordinator_enrolment
)


lecturer_1_topic_1_no_groups = Project.create!(
  ownership: lecturer_1_topic_1_no_groups_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_2_no_groups = Project.create!(
  ownership: lecturer_1_topic_2_no_groups_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_coordinator_enrolment
)


lecturer_2_topic_1_no_groups = Project.create!(
  ownership: lecturer_2_topic_1_no_groups_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_2_topic_2_no_groups = Project.create!(
  ownership: lecturer_2_topic_2_no_groups_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_coordinator_enrolment
)


lecturer_3_topic_1_no_groups = Project.create!(
  ownership: lecturer_3_topic_1_no_groups_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_3_topic_2_no_groups = Project.create!(
  ownership: lecturer_3_topic_2_no_groups_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_coordinator_enrolment
)


group_1_project = Project.create!(
  ownership: group_1_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment
)

group_2_project = Project.create!(
  ownership: group_2_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment
)

group_3_project = Project.create!(
  ownership: group_3_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment
)

group_4_project = Project.create!(
  ownership: group_4_ownership,
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment
)


student_1_project = Project.create!(
  ownership: student_1_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)

student_2_project = Project.create!(
  ownership: student_2_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)

student_3_project = Project.create!(
  ownership: student_3_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)

student_4_project = Project.create!(
  ownership: student_4_ownership,
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)


# Create Project Instances
lecturer_1_topic_1_instance_1 = ProjectInstance.create!(
  project: lecturer_1_topic_1,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 1",
  status: :approved,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_2_instance_1 = ProjectInstance.create!(
  project: lecturer_1_topic_2,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 2",
  status: :approved,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_3_instance_1 = ProjectInstance.create!(
  project: lecturer_1_topic_3,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 3",
  status: :pending,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_4_instance_1 = ProjectInstance.create!(
  project: lecturer_1_topic_4,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 4",
  status: :redo,
  enrolment: lecturer_1_coordinator_enrolment
)


lecturer_2_topic_1_instance_1 = ProjectInstance.create!(
  project: lecturer_2_topic_1,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 1 Lecturer 2",
  status: :approved,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_2_topic_2_instance_1 = ProjectInstance.create!(
  project: lecturer_2_topic_2,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 2 Lecturer 2",
  status: :approved,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_2_topic_3_instance_1 = ProjectInstance.create!(
  project: lecturer_2_topic_3,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 3 Lecturer 2",
  status: :pending,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_2_topic_4_instance_1 = ProjectInstance.create!(
  project: lecturer_2_topic_4,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 4 Lecturer 2",
  status: :redo,
  enrolment: lecturer_1_coordinator_enrolment
)


lecturer_3_topic_1_instance_1 = ProjectInstance.create!(
  project: lecturer_3_topic_1,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 1 Lecturer 3",
  status: :approved,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_3_topic_2_instance_1 = ProjectInstance.create!(
  project: lecturer_3_topic_2,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 2 Lecturer 3",
  status: :approved,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_3_topic_3_instance_1 = ProjectInstance.create!(
  project: lecturer_3_topic_3,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 3 Lecturer 3",
  status: :pending,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_3_topic_4_instance_1 = ProjectInstance.create!(
  project: lecturer_3_topic_4,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 4 Lecturer 3",
  status: :rejected,
  enrolment: lecturer_1_coordinator_enrolment
)

lecturer_1_topic_1_no_groups_instance_1 = ProjectInstance.create!(
  project: lecturer_1_topic_1_no_groups,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic Lecturer 1 no 1",
  status: :rejected,
  enrolment: lecturer_1_coordinator_enrolment_no_groups
)

lecturer_1_topic_2_no_groups_instance_1 = ProjectInstance.create!(
  project: lecturer_1_topic_2_no_groups,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic Lecturer 1 no 2",
  status: :approved,
  enrolment: lecturer_1_coordinator_enrolment_no_groups
)

lecturer_2_topic_1_no_groups_instance_1 = ProjectInstance.create!(
  project: lecturer_2_topic_1_no_groups,
  version: 1,
  created_by: lecturer2,
  title: "Difficult Topic Lecturer 2 no 1",
  status: :redo,
  enrolment: lecturer_1_coordinator_enrolment_no_groups
)

lecturer_2_topic_2_no_groups_instance_1 = ProjectInstance.create!(
  project: lecturer_2_topic_2_no_groups,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic Lecturer 2 no 2",
  status: :rejected,
  enrolment: lecturer_1_coordinator_enrolment_no_groups
)

lecturer_3_topic_1_no_groups_instance_1 = ProjectInstance.create!(
  project: lecturer_3_topic_1_no_groups,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic Lecturer 3 no 1",
  status: :pending,
  enrolment: lecturer_1_coordinator_enrolment_no_groups
)

lecturer_3_topic_2_no_groups_instance_1 = ProjectInstance.create!(
  project: lecturer_3_topic_2_no_groups,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic Lecturer 1 no 2",
  status: :rejected,
  enrolment: lecturer_1_coordinator_enrolment_no_groups
)


group_1_instance_1 = ProjectInstance.create!(
  project: group_1_project,
  version: 1, 
  created_by: student1,
  title: "Difficult Group Project 1",
  status: :pending,
  enrolment: lecturer_2_lecturer_enrolment
)


group_1_instance_2 = ProjectInstance.create!(
  project: group_1_project,
  version: 2,
  created_by: student1,
  title: "Difficult Group Project 2",
  status: :redo,
  enrolment: lecturer_2_lecturer_enrolment
)

group_1_instance_3 = ProjectInstance.create!(
  project: group_1_project,
  version: 3, 
  created_by: student1,
  title: "Difficult Group Project 3",
  status: :rejected,
  enrolment: lecturer_3_lecturer_enrolment
)

group_1_instance_4 = ProjectInstance.create!(
  project: group_1_project,
  version: 4, 
  created_by: student1,
  title: "Difficult Group Project 4",
  status: :approved,
  enrolment: lecturer_1_lecturer_enrolment
)

group_2_instance_1 = ProjectInstance.create!(
  project: group_2_project,
  version: 1, 
  created_by: student4,
  title: "Difficult Group Project Group 2",
  status: :rejected,
  enrolment: lecturer_1_lecturer_enrolment
)

group_3_instance_1 = ProjectInstance.create!(
  project: group_3_project,
  version: 1, 
  created_by: student7,
  title: "Difficult Group Project Group 3",
  status: :redo,
  enrolment: lecturer_1_lecturer_enrolment
)

group_4_instance_1 = ProjectInstance.create!(
  project: group_4_project,
  version: 1, 
  created_by: student10,
  title: "Difficult Group Project Group 4",
  status: :pending,
  enrolment: lecturer_1_lecturer_enrolment
)



student_1_project_instance_1 = ProjectInstance.create!(
  project: student_1_project,
  version: 1,
  created_by: student1,
  title: "Student 1 Project",
  status: :pending,
  enrolment: lecturer_3_lecturer_enrolment_no_groups
)

student_1_project_instance_2 = ProjectInstance.create!(
  project: student_1_project,
  version: 2,
  created_by: student1,
  title: "Student 1 Project 2",
  status: :rejected,
  enrolment: lecturer_3_lecturer_enrolment_no_groups
)

student_1_project_instance_3 = ProjectInstance.create!(
  project: student_1_project,
  version: 3,
  created_by: student1,
  title: "Student 1 Project 3",
  status: :redo,
  enrolment: lecturer_2_lecturer_enrolment_no_groups
)

student_1_project_instance_4 = ProjectInstance.create!(
  project: student_1_project,
  version: 4,
  created_by: student1,
  title: "Student 1 Project 4",
  status: :approved,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)


student_2_project_instance_1 = ProjectInstance.create!(
  project: student_2_project,
  version: 1,
  created_by: student2,
  title: "Student 2 Project",
  status: :pending,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)

student_3_project_instance_1 = ProjectInstance.create!(
  project: student_3_project,
  version: 1,
  created_by: student3,
  title: "Student 3 Project",
  status: :redo,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)

student_4_project_instance_1 = ProjectInstance.create!(
  project: student_4_project,
  version: 1,
  created_by: student4,
  title: "Student 4 Project",
  status: :rejected,
  enrolment: lecturer_1_lecturer_enrolment_no_groups
)


# Create Project Instance Fields
ProjectInstanceField.create!(
  project_instance: group_1_instance_1,
  project_template_field: group_description_field,
  value: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis vitae lacus risus. Fusce nec mi nec ante porttitor interdum. Cras ut lacinia diam."
)

ProjectInstanceField.create!(
  project_instance: group_1_instance_2,
  project_template_field: group_description_field,
  value: "Phasellus orci ante, bibendum a maximus et, suscipit quis quam. Sed a vehicula mauris, sit amet sodales ex. Ut justo dolor, aliquet non nisi ac, porta sodales arcu."
)

ProjectInstanceField.create!(
  project_instance: group_1_instance_3,
  project_template_field: group_description_field,
  value: "In interdum accumsan ante a aliquet. Donec viverra tempor ligula, vel efficitur velit ultrices non. Aliquam erat volutpat. Nam imperdiet arcu ut porttitor rutrum."
)

ProjectInstanceField.create!(
  project_instance: group_1_instance_4,
  project_template_field: group_description_field,
  value: "Phasellus orci ante, bibendum a maximus et, suscipit quis quam. Sed a vehicula mauris, sit amet sodales ex. Ut justo dolor, aliquet non nisi ac, porta sodales arcu."
)


ProjectInstanceField.create!(
  project_instance: group_2_instance_1,
  project_template_field: group_description_field,
  value: "Quisque efficitur magna nec eros luctus, at vestibulum ipsum rutrum. Donec auctor metus vitae feugiat gravida"
)


ProjectInstanceField.create!(
  project_instance: group_3_instance_1,
  project_template_field: group_description_field,
  value: "Cras vestibulum efficitur sapien ornare aliquet. Aliquam hendrerit vestibulum lectus, quis lacinia urna porta id."
)


ProjectInstanceField.create!(
  project_instance: group_4_instance_1,
  project_template_field: group_description_field,
  value: "Praesent ultrices ipsum nec ante lobortis feugiat. Vivamus auctor ex eget lobortis cursus"
)


ProjectInstanceField.create!(
  project_instance: lecturer_1_topic_1_instance_1,
  project_template_field: project_description_field,
  value: "Sed ut vulputate neque"
)

ProjectInstanceField.create!(
  project_instance: lecturer_1_topic_2_instance_1,
  project_template_field: project_description_field,
  value: "Donec luctus sem tellus, ac sagittis urna suscipit non."
)

ProjectInstanceField.create!(
  project_instance: lecturer_1_topic_3_instance_1,
  project_template_field: project_description_field,
  value: "Etiam mollis risus nec dolor faucibus, lacinia consectetur quam semper"
)

ProjectInstanceField.create!(
  project_instance: lecturer_1_topic_4_instance_1,
  project_template_field: project_description_field,
  value: "Duis quis sagittis libero"
)

ProjectInstanceField.create!(
  project_instance: lecturer_2_topic_1_instance_1,
  project_template_field: project_description_field,
  value: "Etiam eleifend sodales tincidunt"
)

ProjectInstanceField.create!(
  project_instance: lecturer_2_topic_2_instance_1,
  project_template_field: project_description_field,
  value: "In in auctor ante."
)

ProjectInstanceField.create!(
  project_instance: lecturer_2_topic_3_instance_1,
  project_template_field: project_description_field,
  value: "Donec mattis sed ex eget aliquet"
)

ProjectInstanceField.create!(
  project_instance: lecturer_2_topic_4_instance_1,
  project_template_field: project_description_field,
  value: "Vivamus tempor lacus consectetur magna laoreet dictum"
)

ProjectInstanceField.create!(
  project_instance: lecturer_3_topic_1_instance_1,
  project_template_field: project_description_field,
  value: "Aenean accumsan vehicula ex eget aliquam."
)

ProjectInstanceField.create!(
  project_instance: lecturer_3_topic_2_instance_1,
  project_template_field: project_description_field,
  value: "Ut tincidunt cursus nisi eget semper"
)

ProjectInstanceField.create!(
  project_instance: lecturer_3_topic_3_instance_1,
  project_template_field: project_description_field,
  value: "Nullam vitae ornare ex"
)

ProjectInstanceField.create!(
  project_instance: lecturer_3_topic_4_instance_1,
  project_template_field: project_description_field,
  value: "Quisque efficitur magna nec eros luctus, at vestibulum ipsum rutrum."
)



ProjectInstanceField.create!(
  project_instance: student_1_project_instance_1,
  project_template_field: project_description_field,
  value: "Vestibulum tincidunt et sapien sit amet semper."
)

ProjectInstanceField.create!(
  project_instance: student_1_project_instance_2,
  project_template_field: project_description_field,
  value: "Curabitur sit amet lacus consectetur, feugiat erat nec, aliquam metus"
)

ProjectInstanceField.create!(
  project_instance: student_1_project_instance_3,
  project_template_field: project_description_field,
  value: "In ex enim, ornare id bibendum ac, euismod a libero."
)

ProjectInstanceField.create!(
  project_instance: student_1_project_instance_4,
  project_template_field: project_description_field,
  value: "Mauris pretium libero non enim mollis, quis consequat tellus pulvinar."
)

ProjectInstanceField.create!(
  project_instance: student_2_project_instance_1,
  project_template_field: project_description_field,
  value: "Vestibulum tincidunt et sapien sit amet semper. "
)


ProjectInstanceField.create!(
  project_instance: student_3_project_instance_1,
  project_template_field: project_description_field,
  value: "Aliquam eget imperdiet mi, ac dictum massa."
)


ProjectInstanceField.create!(
  project_instance: student_4_project_instance_1,
  project_template_field: project_description_field,
  value: "Nam eleifend nulla ut finibus interdum."
)


ProjectInstanceField.create!(
  project_instance: lecturer_1_topic_1_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Nam eleifend nulla ut finibus interdum."
)

ProjectInstanceField.create!(
  project_instance: lecturer_1_topic_2_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Mauris efficitur nunc ut fringilla fermentum"
)

ProjectInstanceField.create!(
  project_instance: lecturer_2_topic_1_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Class aptent taciti sociosqu ad litora torquent per conubia nostra"
)

ProjectInstanceField.create!(
  project_instance: lecturer_2_topic_2_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Curabitur scelerisque, ante ac mattis posuere, nisi sapien elementum libero, eget fermentum mauris sem egestas sem"
)

ProjectInstanceField.create!(
  project_instance: lecturer_3_topic_1_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Donec a cursus purus"
)

ProjectInstanceField.create!(
  project_instance: lecturer_3_topic_2_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Nulla sagittis consequat metus, at bibendum massa aliquet sit amet"
)

# Create Comments
Comment.create!(
  user: lecturer2,
  project: group_1_project,
  text: "Donec et vestibulum velit.",
  project_version_number: 1
)

Comment.create!(
  user: student1,
  project: group_1_project,
  text: "Sed aliquet diam ligula, quis feugiat dolor vestibulum in.",
  project_version_number: 1
)

Comment.create!(
  user: lecturer2,
  project: group_1_project,
  text: "Sed fermentum nibh felis",
  project_version_number: 1
)

Comment.create!(
  user: lecturer2,
  project: group_1_project,
  text: "at lobortis lorem dapibus id",
  project_version_number: 2
)

Comment.create!(
  user: lecturer2,
  project: group_1_project,
  text: "In nulla ipsum",
  project_version_number: 2
)

Comment.create!(
  user: student2,
  project: group_1_project,
  text: "dignissim non velit quis",
  project_version_number: 2
)

Comment.create!(
  user: lecturer2,
  project: group_1_project,
  text: "consectetur pulvinar neque",
  project_version_number: 2
)

Comment.create!(
  user: lecturer3,
  project: group_1_project,
  text: "Maecenas mauris urna",
  project_version_number: 3
)

Comment.create!(
  user: lecturer3,
  project: group_1_project,
  text: "vestibulum rhoncus molestie nec",
  project_version_number: 3
)

Comment.create!(
  user: student3,
  project: group_1_project,
  text: "ultricies ut nisi",
  project_version_number: 3
)

Comment.create!(
  user: lecturer1,
  project: group_1_project,
  text: "Morbi placerat tristique sem ac imperdiet",
  project_version_number: 4
)

Comment.create!(
  user: student3,
  project: group_1_project,
  text: "Pellentesque nec elit posuere est sollicitudin faucibus id dignissim leo",
  project_version_number: 4
)


Comment.create!(
  user: lecturer3,
  project: student_1_project,
  text: "Donec et vestibulum velit.",
  project_version_number: 1
)

Comment.create!(
  user: student1,
  project: student_1_project,
  text: "Sed aliquet diam ligula, quis feugiat dolor vestibulum in.",
  project_version_number: 1
)

Comment.create!(
  user: lecturer3,
  project: student_1_project,
  text: "Sed fermentum nibh felis",
  project_version_number: 1
)

Comment.create!(
  user: student1,
  project: student_1_project,
  text: "Proin id nibh diam.",
  project_version_number: 1
)

Comment.create!(
  user: lecturer3,
  project: student_1_project,
  text: "at lobortis lorem dapibus id",
  project_version_number: 2
)

Comment.create!(
  user: lecturer3,
  project: student_1_project,
  text: "In nulla ipsum",
  project_version_number: 2
)

Comment.create!(
  user: student1,
  project: student_1_project,
  text: "dignissim non velit quis",
  project_version_number: 2
)

Comment.create!(
  user: student1,
  project: student_1_project,
  text: "consectetur pulvinar neque",
  project_version_number: 2
)

Comment.create!(
  user: lecturer2,
  project: student_1_project,
  text: "Maecenas mauris urna",
  project_version_number: 3
)

Comment.create!(
  user: lecturer2,
  project: student_1_project,
  text: "vestibulum rhoncus molestie nec",
  project_version_number: 3
)

Comment.create!(
  user: student1,
  project: student_1_project,
  text: "ultricies ut nisi",
  project_version_number: 3
)

Comment.create!(
  user: student1,
  project: student_1_project,
  text: "Pellentesque sed augue non tellus rhoncus luctus.",
  project_version_number: 3
)

Comment.create!(
  user: lecturer1,
  project: student_1_project,
  text: "Morbi placerat tristique sem ac imperdiet",
  project_version_number: 4
)

Comment.create!(
  user: student3,
  project: student_1_project,
  text: "Pellentesque nec elit posuere est sollicitudin faucibus id dignissim leo",
  project_version_number: 4
)

Comment.create!(
  user: lecturer1,
  project: student_1_project,
  text: "Aliquam luctus ex sit amet bibendum mattis",
  project_version_number: 4
)

Comment.create!(
  user: student3,
  project: student_1_project,
  text: "Aenean accumsan ligula ut felis porta commodo eu a elit.",
  project_version_number: 4
)


# Create Progress Updates
ProgressUpdate.create!(
  project: group_1_project,
  rating: :no_progress,
  feedback: "Vivamus blandit mauris sem",
  date: "2025-2-14"
)

ProgressUpdate.create!(
  project: group_1_project,
  rating: :unsatisfactory,
  feedback: "ac varius lacus efficitur sed",
  date: "2025-2-21"
)

ProgressUpdate.create!(
  project: group_1_project,
  rating: :satisfactory,
  feedback: "Pellentesque sit amet vehicula velit",
  date: "2025-2-28"
)

ProgressUpdate.create!(
  project: group_1_project,
  rating: :excellent,
  feedback: "Nullam interdum ante eu diam euismod",
  date: "2025-3-7"
)


ProgressUpdate.create!(
  project: student_1_project,
  rating: :no_progress,
  feedback: "Vivamus blandit mauris sem",
  date: "2025-2-14"
)

ProgressUpdate.create!(
  project: student_1_project,
  rating: :unsatisfactory,
  feedback: "ac varius lacus efficitur sed",
  date: "2025-2-21"
)

ProgressUpdate.create!(
  project: student_1_project,
  rating: :satisfactory,
  feedback: "Pellentesque sit amet vehicula velit",
  date: "2025-2-28"
)

ProgressUpdate.create!(
  project: student_1_project,
  rating: :excellent,
  feedback: "Nullam interdum ante eu diam euismod",
  date: "2025-3-7"
)
