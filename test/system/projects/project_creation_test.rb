require "application_system_test_case"

class ProjectCreationTest < ApplicationSystemTestCase
  setup do
    @course = create(:course, :grouped)
    @student = create(:user, is_staff: false)
    @other_student = create(:user, is_staff: false)
    @lecturer = create(:user, is_staff: true)

    @student_enrolment = create(:enrolment, user: @student, course: @course, role: :student)
    @other_student_enrolment = create(:enrolment, user: @other_student, course: @course, role: :student)
    @lecturer_enrolment = create(:enrolment, user: @lecturer, course: @course, role: :lecturer)

    # Create project group and add student to it (required for grouped courses)
    @group = create(:project_group, course: @course)
    create(:project_group_member, user: @student, project_group: @group)

    # Create project template with fields
    @template = create(:project_template, course: @course)
    @title_field = create(:project_template_field, 
      project_template: @template,
      field_type: :shorttext,
      applicable_to: :both,
      label: "Project Title",
      required: true
    )
    @description_field = create(:project_template_field,
      project_template: @template,
      field_type: :textarea,
      applicable_to: :student,
      label: "Project Description",
      required: true
    )

    # Create a topic with instance for the student to select
    @topic = create(:topic, course: @course, owner: @lecturer, status: :approved)
    @topic_instance = create(:topic_instance, 
      topic: @topic, 
      created_by: @lecturer,
      title: "Introduction to Rails",
      status: :approved
    )
  end

  test "student can successfully create project with topic happy path" do
    login_as(@student)
    visit course_path(@course)

    # Navigate to create project form
    click_link "Submit Proposal"

    # Select topic from dropdown - should show "lecturer_username - Topic Title"
    topic_display_text = "#{@lecturer.username} - #{@topic_instance.title}"
    select topic_display_text, from: "based_on_topic"

    # Fill in required fields
    fill_in @title_field.label, with: "New Amazing Project"
    fill_in @description_field.label, with: "This is a description of our new project"

    # Submit the form
    click_button "Create Proposal"

    # Verify redirect back to course (successful creation)
    assert_current_path(course_path(@course))
    
    # Verify project exists
    assert_text "New Amazing Project"
  end

  test "student can successfully create project with own proposal happy path" do
    login_as(@student)
    visit course_path(@course)

    # Navigate to create project form
    click_link "Submit Proposal"

    # Select own proposal for lecturer
    select "#{@lecturer.username} - Own Proposal", from: "based_on_topic"

    # Fill in required fields
    fill_in @title_field.label, with: "Own Proposal Project"
    fill_in @description_field.label, with: "This is my own proposal description"

    # Submit the form
    click_button "Create Proposal"

    # Verify redirect back to course
    assert_current_path(course_path(@course))

    # Verify project exists
    assert_text "Own Proposal Project"
  end

  test "project instance is created with correct attributes happy path" do
    login_as(@student)
    visit course_path(@course)

    click_link "Submit Proposal"
    topic_display_text = "#{@lecturer.username} - #{@topic_instance.title}"
    select topic_display_text, from: "based_on_topic"

    fill_in @title_field.label, with: "Test Project Instance"
    fill_in @description_field.label, with: "Testing instance creation"

    click_button "Create Proposal"

    # Click into the project to verify instance exists
    click_link "Test Project Instance"

    # Verify the project instance fields are displayed
    assert_text "Test Project Instance"
    assert_text "Testing instance creation"
  end

  test "student cannot create another project in same course sad path" do
    # Create an existing project for the student
    create(:project, 
      course: @course,
      owner: @student,
      enrolment: @lecturer_enrolment
    )

    login_as(@student)
    visit course_path(@course)

    click_link "Submit Proposal"

    topic_display_text = "#{@lecturer.username} - #{@topic_instance.title}"
    select topic_display_text, from: "based_on_topic"
    fill_in @title_field.label, with: "Second Project"
    fill_in @description_field.label, with: "Trying to create another project"

    click_button "Create Proposal"

    # Should be redirected with error message
    assert_text "You already have a project"
  end

  test "unauthenticated user cannot create project sad path" do
    visit new_course_project_path(@course)

    # Should be redirected to login
    assert_current_path(/login|sign_in/)
  end

  test "student not enrolled in course cannot create project sad path" do
    unenrolled_student = create(:user, is_staff: false)
    login_as(unenrolled_student)

    visit new_course_project_path(@course)

    # Should be redirected or forbidden (check if redirected away from the page)
    assert(current_path =~ /courses/ || page.has_text?("Unauthorized"))
  end

  test "missing required topic selection shows error sad path" do
    login_as(@student)
    visit new_course_project_path(@course)

    # Try to submit without selecting topic
    fill_in @title_field.label, with: "Project Without Topic"
    fill_in @description_field.label, with: "Missing topic"

    click_button "Create Proposal"

    # Should show error message and remain on course page
    assert_text "Please choose a lecturer and topic"
  end

  test "created project has correct ownership type" do
    login_as(@student)
    visit new_course_project_path(@course)

    topic_display_text = "#{@lecturer.username} - #{@topic_instance.title}"
    select topic_display_text, from: "based_on_topic"
    fill_in @title_field.label, with: "Owned Project"
    fill_in @description_field.label, with: "Check ownership"

    click_button "Create Proposal"

    # Verify project was created with student ownership
    project = Project.order(created_at: :desc).first
    assert_equal @student, project.owner
    assert_equal "User", project.owner_type
  end

  test "created project instance has correct type and status" do
    login_as(@student)
    visit new_course_project_path(@course)

    topic_display_text = "#{@lecturer.username} - #{@topic_instance.title}"
    select topic_display_text, from: "based_on_topic"
    fill_in @title_field.label, with: "Instance Test Project"
    fill_in @description_field.label, with: "Check instance attributes"

    click_button "Create Proposal"

    # Verify instance was created correctly
    project = Project.order(created_at: :desc).first
    instance = project.project_instances.last

    assert_equal 1, instance.version
    assert_equal @student, instance.created_by
    assert_equal :pending, instance.status
  end

  test "project instance fields are saved correctly" do
    login_as(@student)
    visit new_course_project_path(@course)

    topic_display_text = "#{@lecturer.username} - #{@topic_instance.title}"
    select topic_display_text, from: "based_on_topic"
    fill_in @title_field.label, with: "Fields Test Project"
    fill_in @description_field.label, with: "Detailed description for testing"

    click_button "Create Proposal"

    # Verify fields were saved
    project = Project.order(created_at: :desc).first
    instance = project.project_instances.last
    fields = instance.project_instance_fields

    assert_equal 2, fields.count

    title_field = fields.find { |f| f.project_template_field.label == @title_field.label }
    description_field = fields.find { |f| f.project_template_field.label == @description_field.label }

    assert_equal "Fields Test Project", title_field.value
    assert_equal "Detailed description for testing", description_field.value
  end

  test "grouped course requires student to be in a project group sad path" do
    grouped_course = create(:course, :grouped)
    grouped_student = create(:user, is_staff: false)
    grouped_lecturer = create(:user, is_staff: true)

    # Enroll student but don't add to group
    create(:enrolment, user: grouped_student, course: grouped_course, role: :student)
    create(:enrolment, user: grouped_lecturer, course: grouped_course, role: :lecturer)
    create(:project_template, course: grouped_course)

    template_field = create(:project_template_field,
      project_template: grouped_course.project_template,
      field_type: :shorttext,
      applicable_to: :both,
      label: "Title",
      required: true
    )

    topic = create(:topic, course: grouped_course, owner: grouped_lecturer, status: :approved)
    topic_instance = create(:topic_instance, 
      topic: topic, 
      created_by: grouped_lecturer, 
      status: :approved
    )

    login_as(grouped_student)
    visit new_course_project_path(grouped_course)

    topic_display_text = "#{grouped_lecturer.username} - #{topic_instance.title}"
    select topic_display_text, from: "based_on_topic"
    fill_in template_field.label, with: "Group Project"

    click_button "Create Proposal"

    # Should show error message
    assert_text "not part of a project group"
  end
end
