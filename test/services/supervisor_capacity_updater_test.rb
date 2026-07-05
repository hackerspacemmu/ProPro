require "test_helper"

class SupervisorCapacityUpdaterTest < ActiveSupport::TestCase
  setup do
    @course = FactoryBot.create(:course,
      supervisor_projects_limit: 10,
      supervisor_auto_calculate_enabled: false,
      grouped: false
    )

    @lecturer1 = FactoryBot.create(:enrolment, :lecturer, course: @course)
    @lecturer2 = FactoryBot.create(:enrolment, :lecturer, course: @course)
    @lecturer3 = FactoryBot.create(:enrolment, :lecturer, course: @course)

    @service = SupervisorCapacityUpdater.new(@course)
  end

  # --- HAPPY PATH ---

  test "updates offsets for multiple lecturers against the manual base" do
    offsets = {
      @lecturer1.id.to_s => "5",
      @lecturer2.id.to_s => "3"
    }

    result = @service.update_capacities(offsets: offsets, excluded_ids: [])

    assert result.updated?
    assert result.errors.empty?

    @lecturer1.reload
    @lecturer2.reload
    @lecturer3.reload

    assert_equal 5, @lecturer1.supervisor_capacity_offset
    assert_equal 3, @lecturer2.supervisor_capacity_offset
    assert_equal 0, @lecturer3.supervisor_capacity_offset
    assert_not @lecturer1.supervisor_capacity_excluded
  end

  test "handles an empty batch as a no-op success" do
    result = @service.update_capacities(offsets: {}, excluded_ids: [])

    assert result.updated?
    assert result.errors.empty?
  end

  test "exclusion bypasses the capacity check even with an otherwise-invalid offset" do
    offsets = { @lecturer1.id.to_s => "-10" }
    excluded_ids = [@lecturer1.id.to_s]

    result = @service.update_capacities(offsets: offsets, excluded_ids: excluded_ids)

    assert result.updated?
    @lecturer1.reload
    assert @lecturer1.supervisor_capacity_excluded
    assert_equal(-10, @lecturer1.supervisor_capacity_offset)
  end

  test "clears a previously set offset back to zero" do
    @lecturer1.update!(supervisor_capacity_offset: 5)

    result = @service.update_capacities(offsets: { @lecturer1.id.to_s => "0" }, excluded_ids: [])

    assert result.updated?
    @lecturer1.reload
    assert_equal 0, @lecturer1.supervisor_capacity_offset
  end

  test "uses the live auto-calculated base, not the manual limit, when enabled" do
    @course.update!(supervisor_auto_calculate_enabled: true)
    create_solo_projects(@course, 21)

    result = @service.update_capacities(offsets: { @lecturer1.id.to_s => "-3" }, excluded_ids: [])

    assert result.updated?
    @lecturer1.reload
    assert_equal(-3, @lecturer1.supervisor_capacity_offset)
  end

  test "applies exclusion for a lecturer even when no offset is present in the same batch" do
    result = @service.update_capacities(offsets: {}, excluded_ids: [@lecturer3.id.to_s])

    assert result.updated?
    @lecturer3.reload
    assert @lecturer3.supervisor_capacity_excluded
    assert_equal 0, @lecturer3.supervisor_capacity_offset
  end

  test "preserves an existing offset, dormant, when excluding a lecturer whose offset is not in this batch" do
    @lecturer3.update!(supervisor_capacity_offset: 4)

    result = @service.update_capacities(offsets: {}, excluded_ids: [@lecturer3.id.to_s])

    assert result.updated?
    @lecturer3.reload
    assert @lecturer3.supervisor_capacity_excluded
    assert_equal 4, @lecturer3.supervisor_capacity_offset
  end

  # --- INVALID INPUT / REJECTED OFFSETS ---

  test "rejects an offset that brings capacity to exactly zero" do
    result = @service.update_capacities(offsets: { @lecturer1.id.to_s => "-10" }, excluded_ids: [])

    assert_not result.updated?
    assert_includes result.errors.first, @lecturer1.user.name
    assert_includes result.errors.first, "zero or negative capacity"
  end

  test "rejects an offset that brings capacity below zero" do
    result = @service.update_capacities(offsets: { @lecturer1.id.to_s => "-11" }, excluded_ids: [])

    assert_not result.updated?
    assert_includes result.errors.first, "zero or negative capacity"
  end

  test "collects an error per invalid enrolment in the same batch" do
    offsets = {
      @lecturer1.id.to_s => "-10",
      @lecturer2.id.to_s => "-11",
      @lecturer3.id.to_s => "5"
    }

    result = @service.update_capacities(offsets: offsets, excluded_ids: [])

    assert_not result.updated?
    assert_equal 2, result.errors.length
    assert result.errors.any? { |e| e.include?(@lecturer1.user.name) }
    assert result.errors.any? { |e| e.include?(@lecturer2.user.name) }
  end

  test "rejects using the live auto-calculated base, not the manual limit, when enabled" do
    @course.update!(supervisor_auto_calculate_enabled: true)
    create_solo_projects(@course, 21)

    result = @service.update_capacities(offsets: { @lecturer1.id.to_s => "-7" }, excluded_ids: [])

    assert_not result.updated?
    assert_includes result.errors.first, "zero or negative capacity"
  end

  # --- ATOMICITY ---

  test "does not persist any changes, including otherwise-valid ones, when one enrolment in the batch is invalid" do
    original_updated_ats = [@lecturer1, @lecturer2, @lecturer3].map(&:updated_at)

    offsets = {
      @lecturer1.id.to_s => "-10", # invalid
      @lecturer2.id.to_s => "3"    # otherwise valid
    }

    result = @service.update_capacities(offsets: offsets, excluded_ids: [])

    assert_not result.updated?

    [@lecturer1, @lecturer2, @lecturer3].each(&:reload)

    assert_equal 0, @lecturer1.supervisor_capacity_offset
    assert_equal 0, @lecturer2.supervisor_capacity_offset
    assert_equal 0, @lecturer3.supervisor_capacity_offset
    assert_equal original_updated_ats, [@lecturer1, @lecturer2, @lecturer3].map(&:updated_at)
  end

  # --- EDGE CASES ---

  test "silently ignores an enrolment id that does not exist" do
    offsets = {
      "999999" => "5",
      @lecturer1.id.to_s => "3"
    }

    result = @service.update_capacities(offsets: offsets, excluded_ids: [])

    assert result.updated?
    @lecturer1.reload
    assert_equal 3, @lecturer1.supervisor_capacity_offset
  end

  test "ignores non-lecturer enrolments (student and coordinator roles)" do
    student = FactoryBot.create(:enrolment, :student, course: @course)
    coordinator = FactoryBot.create(:enrolment, :coordinator, course: @course)

    offsets = {
      student.id.to_s => "5",
      coordinator.id.to_s => "5"
    }

    result = @service.update_capacities(offsets: offsets, excluded_ids: [])

    assert result.updated?
    student.reload
    coordinator.reload
    assert_equal 0, student.supervisor_capacity_offset
    assert_equal 0, coordinator.supervisor_capacity_offset
  end

  private

  def create_solo_projects(course, count)
    count.times do
      student_user = FactoryBot.create(:user)
      FactoryBot.create(:enrolment, :student, course: course, user: student_user)
      FactoryBot.create(:project, course: course, owner_type: "User", owner_id: student_user.id)
    end
  end
end