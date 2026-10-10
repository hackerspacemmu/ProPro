require 'test_helper'

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course      = create(:course, require_coordinator_approval: true)
    @lecturer    = create(:user, :staff)
    @coordinator = create(:user, :staff)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    create(:enrolment, :student, user: create(:user), course: @course)

    @topic    = create(:topic, course: @course, owner: @lecturer)
    @instance = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
  end

  test 'lecturer cannot update topic status' do
    sign_in @lecturer
    patch change_status_course_topic_path(@course, @topic), params: { status: 'approved' }

    assert_redirected_to root_path
    assert_equal 'You are not authorized to view this page.', flash[:alert]
    assert_equal 'pending', @topic.current_instance.reload.status
  end

  test 'coordinator can update topic status' do
    sign_in @coordinator
    patch change_status_course_topic_path(@course, @topic), params: { status: 'approved' }

    assert_redirected_to course_topic_path(@course, @topic)
    assert_equal 'Status updated.', flash[:notice]
    assert_equal 'approved', @topic.current_instance.reload.status
  end

  test 'compare tab diffs the latest version against the previous one' do
    field = create(:project_template_field, project_template: @course.project_template, field_type: :textarea)
    @instance.project_instance_fields.create!(project_template_field_id: field.id, value: 'First draft')
    second = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 2, status: :pending)
    second.project_instance_fields.create!(project_template_field_id: field.id, value: 'Polished draft')

    sign_in @coordinator
    get course_topic_path(@course, @topic)

    assert_response :success
    assert_match 'Version 1', response.body
    assert_match 'Version 2 (Latest)', response.body
    assert_no_match 'Only one version exists', response.body
  end

  test 'compare tab keeps the empty state for a single-version topic' do
    sign_in @coordinator
    get course_topic_path(@course, @topic)

    assert_response :success
    assert_match 'Only one version exists', response.body
  end

  # --- copy-topic provenance (restore of the write half deleted in 67117099) ---

  test 'copying a topic records its source topic and per-field provenance' do
    fix = build_source_fixture(title: 'Origin Title', value: 'Original text')

    sign_in @lecturer
    post course_topics_path(@course),
         params: copy_params(fix, title: 'Origin Title', value: 'Original text')

    copy = Topic.order(:id).last
    assert_equal fix[:source].id, copy.source_topic_id
    assert_equal 'pending', copy.current_instance.status

    title_field = copy.current_instance.project_instance_fields
                      .find_by(project_template_field_id: fix[:title_field].id)
    assert_equal fix[:title_pif].id, title_field.source_field_id

    description_field = copy.current_instance.project_instance_fields
                            .find_by(project_template_field_id: fix[:description_field].id)
    assert_equal fix[:description_pif].id, description_field.source_field_id
  end

  test 'auto-approves an unchanged copy when the course setting is on' do
    @course.update!(auto_approve_copied_topics_without_changes: true)
    fix = build_source_fixture(title: 'Shared title', value: 'Identical')

    sign_in @lecturer
    post course_topics_path(@course),
         params: copy_params(fix, title: 'Shared title', value: 'Identical')

    assert_equal 'approved', Topic.order(:id).last.current_instance.status
  end

  test 'keeps a changed copy pending even when auto-approve is on' do
    @course.update!(auto_approve_copied_topics_without_changes: true)
    fix = build_source_fixture(title: 'Shared title', value: 'Identical')

    sign_in @lecturer
    post course_topics_path(@course),
         params: copy_params(fix, title: 'Shared title', value: 'Different')

    assert_equal 'pending', Topic.order(:id).last.current_instance.status
  end

  test 'does not auto-approve an unchanged copy when the course setting is off' do
    @course.update!(auto_approve_copied_topics_without_changes: false)
    fix = build_source_fixture(title: 'Shared title', value: 'Identical')

    sign_in @lecturer
    post course_topics_path(@course),
         params: copy_params(fix, title: 'Shared title', value: 'Identical')

    assert_equal 'pending', Topic.order(:id).last.current_instance.status
  end

  test 'compare tab renders the source comparison for a copied topic on version 1' do
    copied = build_copied_topic(source_value: 'Original text', copy_value: 'Edited text')

    sign_in @coordinator
    get course_topic_path(@course, copied)

    assert_response :success
    assert_match 'Copied from', response.body
    assert_match 'Version 1 (Latest)', response.body
    assert_match 'Source Title', response.body
    assert_match %r{<del[^>]*>Original</del>}, response.body
    assert_match %r{<ins[^>]*>Edited</ins>}, response.body
  end

  test 'compare tab hides the source comparison for a topic with earlier versions' do
    copied = build_copied_topic(source_value: 'Original text', copy_value: 'Edited text')
    description_field_id = copied.current_instance.project_instance_fields
                                 .first.project_template_field_id
    second = create(:topic_instance, topic: copied, created_by: @lecturer,
                                     version: 2, status: :pending)
    second.project_instance_fields.create!(
      project_template_field_id: description_field_id,
      value: 'Third version'
    )

    sign_in @coordinator
    get course_topic_path(@course, copied)

    assert_response :success
    assert_match 'Version 2 (Latest)', response.body
    assert_no_match 'Version 1 (Latest)', response.body
  end

  test 'compare tab hides the source comparison from viewers who are not the owner or a coordinator' do
    other_lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: other_lecturer, course: @course)
    fix = build_source_fixture(title: 'Source Title', value: 'Original text')
    copied = create(:topic, course: @course, owner: @lecturer, source_topic: fix[:source])
    create(:topic_instance, topic: copied, created_by: @lecturer, version: 1,
                            status: :approved, title: 'Copy Title')

    sign_in other_lecturer
    get course_topic_path(@course, copied)

    assert_response :success
    assert_match 'Only one version exists', response.body
    assert_no_match 'Version 1 (Latest)', response.body
  end

  private

  # A source topic whose approved instance carries a title and a description
  # value, plus the two template fields the copy's values land on. Returns the
  # topic and the field / instance-field pairs the assertions and the POST
  # params both need.
  def build_source_fixture(title:, value:)
    title_field = @course.project_template.project_template_fields
                         .find_by(is_project_title: true)
    description_field = create(:project_template_field,
                               project_template: @course.project_template,
                               label: 'Description',
                               field_type: :textarea)
    source = create(:topic, course: @course, owner: @lecturer)
    source_instance = create(:topic_instance, topic: source, created_by: @lecturer,
                                              version: 1, status: :approved, title: title)
    title_pif = source_instance.project_instance_fields.create!(
      project_template_field: title_field,
      value: title
    )
    description_pif = source_instance.project_instance_fields.create!(
      project_template_field: description_field,
      value: value
    )

    {
      source: source,
      title_field: title_field,
      title_pif: title_pif,
      description_field: description_field,
      description_pif: description_pif
    }
  end

  # The POST body create expects: the topic's source plus every field value and
  # its matching source field id, exactly as copy_topic_controller.js submits.
  def copy_params(fixture, title:, value:)
    {
      source_topic_id: fixture[:source].id,
      fields: {
        fixture[:title_field].id.to_s => title,
        fixture[:description_field].id.to_s => value
      },
      source_fields: {
        fixture[:title_field].id.to_s => fixture[:title_pif].id,
        fixture[:description_field].id.to_s => fixture[:description_pif].id
      }
    }
  end

  # A topic whose version 1 already carries provenance: `source_topic_id` on
  # the topic and `source_field_id` on the description field, as `create`
  # would record it.
  def build_copied_topic(source_value:, copy_value:)
    fix = build_source_fixture(title: 'Source Title', value: source_value)
    copied = create(:topic, course: @course, owner: @lecturer, source_topic: fix[:source])
    instance = create(:topic_instance, topic: copied, created_by: @lecturer,
                                       version: 1, status: :pending)
    instance.project_instance_fields.create!(
      project_template_field: fix[:description_field],
      value: copy_value,
      source_field_id: fix[:description_pif].id
    )

    copied
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
