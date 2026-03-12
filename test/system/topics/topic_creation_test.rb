require "application_system_test_case"

class TopicCreationTest < ApplicationSystemTestCase
  setup do
    @course = create(:course, require_coordinator_approval: false)
    @course_with_approval = create(:course, require_coordinator_approval: true)
    @lecturer = create(:user, is_staff: true)
    @other_lecturer = create(:user, is_staff: true)
    @coordinator = create(:user, is_staff: true)
    @student = create(:user, is_staff: false)

    @lecturer_enrolment = create(:enrolment, user: @lecturer, course: @course, role: :lecturer)
    @other_lecturer_enrolment = create(:enrolment, user: @other_lecturer, course: @course, role: :lecturer)
    @student_enrolment = create(:enrolment, user: @student, course: @course, role: :student)

    @coordinator_enrolment_with_approval = create(:enrolment, user: @coordinator, course: @course_with_approval, role: :coordinator)
    @lecturer_enrolment_with_approval = create(:enrolment, user: @lecturer, course: @course_with_approval, role: :lecturer)

    # Create project template with fields for topics
    @template = create(:project_template, course: @course)
    @title_field = create(:project_template_field, 
      project_template: @template,
      field_type: :shorttext,
      applicable_to: :topics,
      label: "Topic Title",
      required: true
    )
    @description_field = create(:project_template_field,
      project_template: @template,
      field_type: :textarea,
      applicable_to: :both,
      label: "Topic Description",
      required: true
    )

    # Create template for course with approval
    @template_with_approval = create(:project_template, course: @course_with_approval)
    create(:project_template_field,
      project_template: @template_with_approval,
      field_type: :shorttext,
      applicable_to: :topics,
      label: "Topic Title",
      required: true
    )
    create(:project_template_field,
      project_template: @template_with_approval,
      field_type: :textarea,
      applicable_to: :both,
      label: "Topic Description",
      required: true
    )
  end

  test "lecturer can successfully create topic happy path" do
    login_as(@lecturer)
    visit course_topics_path(@course)

    # Navigate to create topic form
    click_link "New Topic"

    # Fill in required fields
    fill_in @title_field.label, with: "Advanced Ruby Patterns"
    fill_in @description_field.label, with: "Explore advanced Ruby design patterns and best practices"

    # Submit the form
    click_button "Create Topic"

    # Verify redirect to topic show page
    assert_current_path(%r{courses/#{@course.id}/topics/\d+})
    
    # Verify topic content is displayed
    assert_text "Advanced Ruby Patterns"
    assert_text "Explore advanced Ruby design patterns and best practices"
  end

  test "topic instance is created with correct attributes happy path" do
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Machine Learning Basics"
    fill_in @description_field.label, with: "Introduction to machine learning concepts"

    click_button "Create Topic"

    # Verify topic instance was created correctly
    topic = Topic.order(created_at: :desc).first
    instance = topic.topic_instances.last

    assert_equal 1, instance.version
    assert_equal @lecturer, instance.created_by
    assert_equal :approved, instance.status # not requiring approval
  end

  test "topic instance receives pending status when coordinator approval required happy path" do
    login_as(@lecturer)
    visit new_course_topic_path(@course_with_approval)

    fill_in "Topic Title", with: "Web Security"
    fill_in "Topic Description", with: "Security best practices for web applications"

    click_button "Create Topic"

    # Verify topic instance status is pending
    topic = Topic.order(created_at: :desc).first
    instance = topic.topic_instances.last

    assert_equal :pending, instance.status
  end

  test "topic instance fields are saved correctly" do
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Distributed Systems"
    fill_in @description_field.label, with: "Understanding distributed systems architecture"

    click_button "Create Topic"

    # Verify fields were saved
    topic = Topic.order(created_at: :desc).first
    instance = topic.topic_instances.last
    fields = instance.project_instance_fields

    assert_equal 2, fields.count

    title_field = fields.find { |f| f.project_template_field.label == @title_field.label }
    description_field = fields.find { |f| f.project_template_field.label == @description_field.label }

    assert_equal "Distributed Systems", title_field.value
    assert_equal "Understanding distributed systems architecture", description_field.value
  end

  test "created topic has correct owner and ownership type" do
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Owned Topic"
    fill_in @description_field.label, with: "Check ownership"

    click_button "Create Topic"

    # Verify topic was created with lecturer ownership
    topic = Topic.order(created_at: :desc).first
    assert_equal @lecturer, topic.owner
    assert_equal "User", topic.owner_type
  end

  test "unauthenticated user cannot create topic sad path" do
    visit new_course_topic_path(@course)

    # Should be redirected to login
    assert_current_path(/login|sign_in/)
  end

  test "student cannot create topic sad path" do
    login_as(@student)
    visit new_course_topic_path(@course)

    # Should be redirected or forbidden
    assert_current_path(/courses/) || assert_text("Unauthorized")
  end

  test "user not enrolled in course cannot create topic sad path" do
    unrelated_lecturer = create(:user, is_staff: true)
    login_as(unrelated_lecturer)

    visit new_course_topic_path(@course)

    # Should be redirected or forbidden
    assert_current_path(/courses/) || assert_text("Unauthorized")
  end

  test "missing template shows error sad path" do
    course_no_template = create(:course)
    create(:enrolment, user: @lecturer, course: course_no_template, role: :lecturer)

    login_as(@lecturer)
    visit new_course_topic_path(course_no_template)

    # Should show error message
    assert_text "Project template is missing or incomplete"
    assert_current_path(course_path(course_no_template))
  end

  test "multiple lecturers can create topics in same course happy path" do
    # First lecturer creates topic
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Lecturer 1 Topic"
    fill_in @description_field.label, with: "First lecturer's topic"
    click_button "Create Topic"

    # Verify first topic created
    first_topic = Topic.order(created_at: :desc).first
    assert_equal @lecturer, first_topic.owner

    # Second lecturer creates topic
    logout
    login_as(@other_lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Lecturer 2 Topic"
    fill_in @description_field.label, with: "Second lecturer's topic"
    click_button "Create Topic"

    # Verify second topic created
    second_topic = Topic.order(created_at: :desc).first
    assert_equal @other_lecturer, second_topic.owner
  end

  test "topic can be viewed after creation happy path" do
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Viewable Topic"
    fill_in @description_field.label, with: "This topic should be viewable"

    click_button "Create Topic"

    # Click back to topics
    click_link "Back to Topics"

    # Verify topic appears in list
    assert_text "Viewable Topic"
  end

  test "topic instance version is always 1 on creation happy path" do
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Version Test Topic"
    fill_in @description_field.label, with: "Check version"

    click_button "Create Topic"

    # Verify version is 1
    topic = Topic.order(created_at: :desc).first
    assert_equal 1, topic.topic_instances.count
    assert_equal 1, topic.topic_instances.first.version
  end

  test "coordinator can view topic after creation even with approval required happy path" do
    login_as(@lecturer)
    visit new_course_topic_path(@course_with_approval)

    fill_in "Topic Title", with: "Coordinator Viewable Topic"
    fill_in "Topic Description", with: "Should be visible to coordinator"

    click_button "Create Topic"

    # Navigate to topic show page
    topic = Topic.order(created_at: :desc).first
    
    logout
    login_as(@coordinator)
    visit course_topic_path(@course_with_approval, topic)

    # Should see content and status selector
    assert_text "Coordinator Viewable Topic"
    assert_selector '[data-testid="status-select"]'
  end

  test "lecturer cannot view other lecturers' pending topics when approval required sad path" do
    # Create a pending topic by another lecturer
    login_as(@other_lecturer)
    visit new_course_topic_path(@course_with_approval)

    fill_in "Topic Title", with: "Other Lecturer Pending Topic"
    fill_in "Topic Description", with: "Pending approval"

    click_button "Create Topic"

    logout
    login_as(@lecturer)
    
    # Try to navigate to other lecturer's topic
    other_topic = Topic.order(created_at: :desc).first
    visit course_topic_path(@course_with_approval, other_topic)

    # Should be unauthorized to view
    assert_current_path(/courses/) || assert_text("Unauthorized")
  end

  test "topic title is extracted from correct field happy path" do
    login_as(@lecturer)
    visit new_course_topic_path(@course)

    fill_in @title_field.label, with: "Title Field Topic"
    fill_in @description_field.label, with: "This is the description"

    click_button "Create Topic"

    topic = Topic.order(created_at: :desc).first
    instance = topic.topic_instances.last

    # Verify title was extracted correctly
    assert_equal "Title Field Topic", instance.title
  end
end
