class TopicVersionComparisonsController < ApplicationController
  include VersionBrowsing

  before_action :set_course
  before_action :set_topic
  before_action :toggle_topics

  def show
    authorize @topic, :show?

    @instances = @topic.topic_instances.order(version: :asc)
    load_versions(@instances)

    @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)
    @is_student = @course.enrolments.exists?(user: current_user, role: :student)

    @owner = @topic.owner
    @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]

    @comments = @topic.comments.order(created_at: :asc)
    @new_comment = Comment.new(user: current_user, location: @current_instance)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_topic
    @topic = @course.topics.find_by(id: params[:topic_id])
    return if @topic

    redirect_to course_path(@course), alert: 'Topic not found.'
  end

  def toggle_topics
    return if @course.toggle_topics

    redirect_to course_path(@course), alert: 'Topics are Disabled for this Course'
  end
end
