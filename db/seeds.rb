# Create Users
lecturer1 = User.create!(
  email_address: "lecturer1@test.com",
  username: "lecturer1",
  has_registered: true,
  student_id: nil,
  web_link: "test.com",
  password: "password123"
)

lecturer2 = User.create!(
  email_address: "lecturer2@test.com",
  username: "lecturer2",
  has_registered: true,
  student_id: nil,
  web_link: "test.com",
  password: "password123"
)

lecturer3 = User.create!(
  email_address: "lecturer3@test.com",
  username: "lecturer3",
  has_registered: true,
  student_id: nil,
  web_link: "test.com",
  password: "password123"
)

student1 = User.create!(
  email_address: "student1@test.com",
  username: "student1",
  has_registered: true,
  student_id: "1191202123",
  password: "password123"
)

student2 = User.create!(
  email_address: "student2@test.com",
  username: "student2",
  has_registered: true,
  student_id: "1191202124",
  password: "password123"
)

student3 = User.create!(
  email_address: "student3@test.com",
  username: "student3",
  has_registered: true,
  student_id: "1191202125",
  password: "password123"
)

student4 = User.create!(
  email_address: "student4@test.com",
  username: "student4",
  has_registered: true,
  student_id: "1191202126",
  password: "password123"
)

student5 = User.create!(
  email_address: "student5@test.com",
  username: "student5",
  has_registered: true,
  student_id: "1191202126",
  password: "password123"
)

student6 = User.create!(
  email_address: "student6@test.com",
  username: "student6",
  has_registered: true,
  student_id: "1191202127",
  password: "password123"
)

student7 = User.create!(
  email_address: "student7@test.com",
  username: "student7",
  has_registered: true,
  student_id: "1191202128",
  password: "password123"
)

student8 = User.create!(
  email_address: "student8@test.com",
  username: "student8",
  has_registered: true,
  student_id: "1191202129",
  password: "password123"
)

student9 = User.create!(
  email_address: "student9@test.com",
  username: "student9",
  has_registered: true,
  student_id: "1191202130",
  password: "password123"
)

student10 = User.create!(
  email_address: "student10@test.com",
  username: "student10",
  has_registered: true,
  student_id: "1191202131",
  password: "password123"
)

student11 = User.create!(
  email_address: "student11@test.com",
  username: "student11",
  has_registered: true,
  student_id: "1191202132",
  password: "password123"
)

student12 = User.create!(
  email_address: "student12@test.com",
  username: "student12",
  has_registered: true,
  student_id: "1191202133",
  password: "password123"
)

student13 = User.create!(
  email_address: "student13@test.com",
  username: "student13",
  has_registered: true,
  student_id: "1191202133",
  password: "password123"
)

student14 = User.create!(
  email_address: "student14@test.com",
  username: "student14",
  has_registered: true,
  student_id: "1191202134",
  password: "password123"
)

student15 = User.create!(
  email_address: "student15@test.com",
  username: "student15",
  has_registered: true,
  student_id: "1191202135",
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
title_field_individual = ProjectTemplateField.create!(
  project_template: individual_template,
  field_type: :shorttext,
  applicable_to: :both,
  label: "Project Title"
)

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

title_field_group = ProjectTemplateField.create!(
  project_template: group_template,
  field_type: :shorttext,
  applicable_to: :both,
  label: "Project Title"
)

group_description_field = ProjectTemplateField.create!(
  project_template: group_template,
  field_type: 1, # textarea
  applicable_to: 1, # student
  label: "Group Project Description",
  hint: "Describe the group project scope and member responsibilities"
)

# Create Projects
lecturer_1_topic_1 = Topic.create!(
  course: course_with_groups,
  owner: lecturer1,
)

lecturer_1_topic_2 = Topic.create!(
  course: course_with_groups,
  owner: lecturer1,
)

lecturer_1_topic_3 = Topic.create!(
  course: course_with_groups,
  owner: lecturer1,
)

lecturer_1_topic_4 = Topic.create!(
  course: course_with_groups,
  owner: lecturer1,
)


lecturer_2_topic_1 = Topic.create!(
  course: course_with_groups,
  owner: lecturer2,
)

lecturer_2_topic_2 = Topic.create!(
  course: course_with_groups,
  owner: lecturer2,
)

lecturer_2_topic_3 = Topic.create!(
  course: course_with_groups,
  owner: lecturer2,
)

lecturer_2_topic_4 = Topic.create!(
  course: course_with_groups,
  owner: lecturer2,
)


lecturer_3_topic_1 = Topic.create!(
  course: course_with_groups,
  owner: lecturer3,
)

lecturer_3_topic_2 = Topic.create!(
  course: course_with_groups,
  owner: lecturer3,
)

lecturer_3_topic_3 = Topic.create!(
  course: course_with_groups,
  owner: lecturer3,
)

lecturer_3_topic_4 = Topic.create!(
  course: course_with_groups,
  owner: lecturer3,
)


lecturer_1_topic_1_no_groups = Topic.create!(
  course: course_no_groups,
  owner: lecturer1,
)

lecturer_1_topic_2_no_groups = Topic.create!(
  course: course_no_groups,
  owner: lecturer1,
)


lecturer_2_topic_1_no_groups = Topic.create!(
  course: course_no_groups,
  owner: lecturer2,
)

lecturer_2_topic_2_no_groups = Topic.create!(
  course: course_no_groups,
  owner: lecturer2,
)


lecturer_3_topic_1_no_groups = Topic.create!(
  course: course_no_groups,
  owner: lecturer3,
)

lecturer_3_topic_2_no_groups = Topic.create!(
  course: course_no_groups,
  owner: lecturer3,
)


group_1_project = Project.create!(
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment,
  owner: group_1,
  ownership_type: :project_group
)

group_2_project = Project.create!(
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment,
  owner: group_2,
  ownership_type: :project_group
)

group_3_project = Project.create!(
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment,
  owner: group_3,
  ownership_type: :project_group
)

group_4_project = Project.create!(
  course: course_with_groups,
  enrolment: lecturer_1_lecturer_enrolment,
  owner: group_4,
  ownership_type: :project_group
)


student_1_project = Project.create!(
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups,
  owner: student1,
  ownership_type: :student
)

student_2_project = Project.create!(
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups,
  owner: student2,
  ownership_type: :student
)

student_3_project = Project.create!(
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups,
  owner: student3,
  ownership_type: :student
)

student_4_project = Project.create!(
  course: course_no_groups,
  enrolment: lecturer_1_lecturer_enrolment_no_groups,
  owner: student4,
  ownership_type: :student
)


# Create Project Instances
lecturer_1_topic_1_instance_1 = TopicInstance.create!(
  topic: lecturer_1_topic_1,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 1",
  status: :approved,
)

lecturer_1_topic_2_instance_1 = TopicInstance.create!(
  topic: lecturer_1_topic_2,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 2",
  status: :approved,
)

lecturer_1_topic_3_instance_1 = TopicInstance.create!(
  topic: lecturer_1_topic_3,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 3",
  status: :pending,
)

lecturer_1_topic_4_instance_1 = TopicInstance.create!(
  topic: lecturer_1_topic_4,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic 4",
  status: :redo,
)


lecturer_2_topic_1_instance_1 = TopicInstance.create!(
  topic: lecturer_2_topic_1,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 1 Lecturer 2",
  status: :approved,
)

lecturer_2_topic_2_instance_1 = TopicInstance.create!(
  topic: lecturer_2_topic_2,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 2 Lecturer 2",
  status: :approved
)

lecturer_2_topic_3_instance_1 = TopicInstance.create!(
  topic: lecturer_2_topic_3,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 3 Lecturer 2",
  status: :pending
)

lecturer_2_topic_4_instance_1 = TopicInstance.create!(
  topic: lecturer_2_topic_4,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic 4 Lecturer 2",
  status: :redo
)


lecturer_3_topic_1_instance_1 = TopicInstance.create!(
  topic: lecturer_3_topic_1,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 1 Lecturer 3",
  status: :approved
)

lecturer_3_topic_2_instance_1 = TopicInstance.create!(
  topic: lecturer_3_topic_2,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 2 Lecturer 3",
  status: :approved
)

lecturer_3_topic_3_instance_1 = TopicInstance.create!(
  topic: lecturer_3_topic_3,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 3 Lecturer 3",
  status: :pending
)

lecturer_3_topic_4_instance_1 = TopicInstance.create!(
  topic: lecturer_3_topic_4,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic 4 Lecturer 3",
  status: :rejected
)

lecturer_1_topic_1_no_groups_instance_1 = TopicInstance.create!(
  topic: lecturer_1_topic_1_no_groups,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic Lecturer 1 no 1",
  status: :rejected
)

lecturer_1_topic_2_no_groups_instance_1 = TopicInstance.create!(
  topic: lecturer_1_topic_2_no_groups,
  version: 1, 
  created_by: lecturer1,
  title: "Difficult Topic Lecturer 1 no 2",
  status: :approved
)

lecturer_2_topic_1_no_groups_instance_1 = TopicInstance.create!(
  topic: lecturer_2_topic_1_no_groups,
  version: 1,
  created_by: lecturer2,
  title: "Difficult Topic Lecturer 2 no 1",
  status: :redo
)

lecturer_2_topic_2_no_groups_instance_1 = TopicInstance.create!(
  topic: lecturer_2_topic_2_no_groups,
  version: 1, 
  created_by: lecturer2,
  title: "Difficult Topic Lecturer 2 no 2",
  status: :rejected
)

lecturer_3_topic_1_no_groups_instance_1 = TopicInstance.create!(
  topic: lecturer_3_topic_1_no_groups,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic Lecturer 3 no 1",
  status: :pending
)

lecturer_3_topic_2_no_groups_instance_1 = TopicInstance.create!(
  topic: lecturer_3_topic_2_no_groups,
  version: 1, 
  created_by: lecturer3,
  title: "Difficult Topic Lecturer 1 no 2",
  status: :rejected
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
  instance: group_1_instance_1,
  project_template_field: title_field_group,
  value: "Difficult Group Project 1"
)

ProjectInstanceField.create!(
  instance: group_1_instance_1,
  project_template_field: group_description_field,
  value: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis vitae lacus risus. Fusce nec mi nec ante porttitor interdum. Cras ut lacinia diam."
)

ProjectInstanceField.create!(
  instance: group_1_instance_2,
  project_template_field: title_field_group,
  value: "Difficult Group Project 2"
)

ProjectInstanceField.create!(
  instance: group_1_instance_2,
  project_template_field: group_description_field,
  value: "Phasellus orci ante, bibendum a maximus et, suscipit quis quam. Sed a vehicula mauris, sit amet sodales ex. Ut justo dolor, aliquet non nisi ac, porta sodales arcu."
)

ProjectInstanceField.create!(
  instance: group_1_instance_3,
  project_template_field: title_field_group,
  value: "Difficult Group Project 3"
)

ProjectInstanceField.create!(
  instance: group_1_instance_3,
  project_template_field: group_description_field,
  value: "In interdum accumsan ante a aliquet. Donec viverra tempor ligula, vel efficitur velit ultrices non. Aliquam erat volutpat. Nam imperdiet arcu ut porttitor rutrum."
)

ProjectInstanceField.create!(
  instance: group_1_instance_4,
  project_template_field: title_field_group,
  value: "Difficult Group Project 4"
)

ProjectInstanceField.create!(
  instance: group_1_instance_4,
  project_template_field: group_description_field,
  value: "Phasellus orci ante, bibendum a maximus et, suscipit quis quam. Sed a vehicula mauris, sit amet sodales ex. Ut justo dolor, aliquet non nisi ac, porta sodales arcu."
)

ProjectInstanceField.create!(
  instance: group_2_instance_1,
  project_template_field: title_field_group,
  value: "Difficult Group Project Group 2"
)

ProjectInstanceField.create!(
  instance: group_2_instance_1,
  project_template_field: group_description_field,
  value: "Quisque efficitur magna nec eros luctus, at vestibulum ipsum rutrum. Donec auctor metus vitae feugiat gravida"
)

ProjectInstanceField.create!(
  instance: group_3_instance_1,
  project_template_field: title_field_group,
  value: "Difficult Group Project Group 3"
)

ProjectInstanceField.create!(
  instance: group_3_instance_1,
  project_template_field: group_description_field,
  value: "Cras vestibulum efficitur sapien ornare aliquet. Aliquam hendrerit vestibulum lectus, quis lacinia urna porta id."
)

ProjectInstanceField.create!(
  instance: group_4_instance_1,
  project_template_field: title_field_group,
  value: "Difficult Group Project Group 4"
)

ProjectInstanceField.create!(
  instance: group_4_instance_1,
  project_template_field: group_description_field,
  value: "Praesent ultrices ipsum nec ante lobortis feugiat. Vivamus auctor ex eget lobortis cursus"
)

ProjectInstanceField.create!(instance: lecturer_1_topic_1_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 1"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_1_instance_1,
  project_template_field: project_description_field,
  value: "Sed ut vulputate neque"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_2_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 2"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_2_instance_1,
  project_template_field: project_description_field,
  value: "Donec luctus sem tellus, ac sagittis urna suscipit non."
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_3_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 3"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_3_instance_1,
  project_template_field: project_description_field,
  value: "Etiam mollis risus nec dolor faucibus, lacinia consectetur quam semper"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_4_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 4"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_4_instance_1,
  project_template_field: project_description_field,
  value: "Duis quis sagittis libero"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_1_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 1 Lecturer 2"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_1_instance_1,
  project_template_field: project_description_field,
  value: "Etiam eleifend sodales tincidunt"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_2_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 2 Lecturer 2"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_2_instance_1,
  project_template_field: project_description_field,
  value: "In in auctor ante."
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_3_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 3 Lecturer 2"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_3_instance_1,
  project_template_field: project_description_field,
  value: "Donec mattis sed ex eget aliquet"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_4_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 4 Lecturer 2"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_4_instance_1,
  project_template_field: project_description_field,
  value: "Vivamus tempor lacus consectetur magna laoreet dictum"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_1_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 1 Lecturer 3"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_1_instance_1,
  project_template_field: project_description_field,
  value: "Aenean accumsan vehicula ex eget aliquam."
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_2_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 2 Lecturer 3"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_2_instance_1,
  project_template_field: project_description_field,
  value: "Ut tincidunt cursus nisi eget semper"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_3_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 3 Lecturer 3"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_3_instance_1,
  project_template_field: project_description_field,
  value: "Nullam vitae ornare ex"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_4_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic 4 Lecturer 3"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_4_instance_1,
  project_template_field: project_description_field,
  value: "Quisque efficitur magna nec eros luctus, at vestibulum ipsum rutrum."
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_1,
  project_template_field: title_field_individual,
  value: "Student 1 Project"
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_1,
  project_template_field: project_description_field,
  value: "Vestibulum tincidunt et sapien sit amet semper."
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_2,
  project_template_field: title_field_individual,
  value: "Student 1 Project 2"
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_2,
  project_template_field: project_description_field,
  value: "Curabitur sit amet lacus consectetur, feugiat erat nec, aliquam metus"
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_3,
  project_template_field: title_field_individual,
  value: "Student 1 Project 3"
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_3,
  project_template_field: project_description_field,
  value: "In ex enim, ornare id bibendum ac, euismod a libero."
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_4,
  project_template_field: title_field_individual,
  value: "Student 1 Project 4"
)

ProjectInstanceField.create!(
  instance: student_1_project_instance_4,
  project_template_field: project_description_field,
  value: "Mauris pretium libero non enim mollis, quis consequat tellus pulvinar."
)

ProjectInstanceField.create!(
  instance: student_2_project_instance_1,
  project_template_field: title_field_individual,
  value: "Student 2 Project"
)

ProjectInstanceField.create!(
  instance: student_2_project_instance_1,
  project_template_field: project_description_field,
  value: "Vestibulum tincidunt et sapien sit amet semper. "
)

ProjectInstanceField.create!(
  instance: student_3_project_instance_1,
  project_template_field: title_field_individual,
  value: "Student 3 Project"
)

ProjectInstanceField.create!(
  instance: student_3_project_instance_1,
  project_template_field: project_description_field,
  value: "Aliquam eget imperdiet mi, ac dictum massa."
)

ProjectInstanceField.create!(
  instance: student_4_project_instance_1,
  project_template_field: title_field_individual,
  value: "Student 4 Project"
)

ProjectInstanceField.create!(
  instance: student_4_project_instance_1,
  project_template_field: project_description_field,
  value: "Nam eleifend nulla ut finibus interdum."
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_1_no_groups_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic Lecturer 1 no 1"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_1_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Nam eleifend nulla ut finibus interdum."
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_2_no_groups_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic Lecturer 1 no 2"
)

ProjectInstanceField.create!(
  instance: lecturer_1_topic_2_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Mauris efficitur nunc ut fringilla fermentum"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_1_no_groups_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic Lecturer 2 no 1"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_1_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Class aptent taciti sociosqu ad litora torquent per conubia nostra"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_2_no_groups_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic Lecturer 2 no 2"
)

ProjectInstanceField.create!(
  instance: lecturer_2_topic_2_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Curabitur scelerisque, ante ac mattis posuere, nisi sapien elementum libero, eget fermentum mauris sem egestas sem"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_1_no_groups_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic Lecturer 3 no 1"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_1_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Donec a cursus purus"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_2_no_groups_instance_1,
  project_template_field: title_field_individual,
  value: "Difficult Topic Lecturer 1 no 2"
)

ProjectInstanceField.create!(
  instance: lecturer_3_topic_2_no_groups_instance_1,
  project_template_field: lecturer_feedback_field,
  value: "Nulla sagittis consequat metus, at bibendum massa aliquet sit amet"
)

# Create Comments
Comment.create!(
  user: lecturer2,
  text: "Donec et vestibulum velit.",
  location: group_1_instance_1
)

Comment.create!(
  user: student1,
  text: "Sed aliquet diam ligula, quis feugiat dolor vestibulum in.",
  location: group_1_instance_1
)

Comment.create!(
  user: lecturer2,
  text: "Sed fermentum nibh felis",
  location: group_1_instance_1
)

Comment.create!(
  user: lecturer2,
  text: "at lobortis lorem dapibus id",
  location: group_1_instance_2
)

Comment.create!(
  user: lecturer2,
  text: "In nulla ipsum",
  location: group_1_instance_2
)

Comment.create!(
  user: student2,
  text: "dignissim non velit quis",
  location: group_1_instance_2
)

Comment.create!(
  user: lecturer2,
  text: "consectetur pulvinar neque",
  location: group_1_instance_2
)

Comment.create!(
  user: lecturer3,
  text: "Maecenas mauris urna",
  location: group_1_instance_3
)

Comment.create!(
  user: lecturer3,
  text: "vestibulum rhoncus molestie nec",
  location: group_1_instance_3
)

Comment.create!(
  user: student3,
  text: "ultricies ut nisi",
  location: group_1_instance_2
)

Comment.create!(
  user: lecturer1,
  text: "Morbi placerat tristique sem ac imperdiet",
  location: group_1_instance_4
)

Comment.create!(
  user: student3,
  text: "Pellentesque nec elit posuere est sollicitudin faucibus id dignissim leo",
  location: group_1_instance_4
)


Comment.create!(
  user: lecturer3,
  text: "Donec et vestibulum velit.",
  location: student_1_project_instance_1
)

Comment.create!(
  user: student1,
  text: "Sed aliquet diam ligula, quis feugiat dolor vestibulum in.",
  location: student_1_project_instance_1
)

Comment.create!(
  user: lecturer3,
  text: "Sed fermentum nibh felis",
  location: student_1_project_instance_1
)

Comment.create!(
  user: student1,
  text: "Proin id nibh diam.",
  location: student_1_project_instance_1
)

Comment.create!(
  user: lecturer3,
  text: "at lobortis lorem dapibus id",
  location: student_1_project_instance_2
)

Comment.create!(
  user: lecturer3,
  text: "In nulla ipsum",
  location: student_1_project_instance_2
)

Comment.create!(
  user: student1,
  text: "dignissim non velit quis",
  location: student_1_project_instance_2
)

Comment.create!(
  user: student1,
  text: "consectetur pulvinar neque",
  location: student_1_project_instance_2
)

Comment.create!(
  user: lecturer2,
  text: "Maecenas mauris urna",
  location: student_1_project_instance_3
)

Comment.create!(
  user: lecturer2,
  text: "vestibulum rhoncus molestie nec",
  location: student_1_project_instance_3
)

Comment.create!(
  user: student1,
  text: "ultricies ut nisi",
  location: student_1_project_instance_3
)

Comment.create!(
  user: student1,
  text: "Pellentesque sed augue non tellus rhoncus luctus.",
  location: student_1_project_instance_3
)

Comment.create!(
  user: lecturer1,
  text: "Morbi placerat tristique sem ac imperdiet",
  location: student_1_project_instance_4
)

Comment.create!(
  user: student3,
  text: "Pellentesque nec elit posuere est sollicitudin faucibus id dignissim leo",
  location: student_1_project_instance_4
)

Comment.create!(
  user: lecturer1,
  text: "Aliquam luctus ex sit amet bibendum mattis",
  location: student_1_project_instance_4
)

Comment.create!(
  user: student3,
  text: "Aenean accumsan ligula ut felis porta commodo eu a elit.",
  location: student_1_project_instance_4
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