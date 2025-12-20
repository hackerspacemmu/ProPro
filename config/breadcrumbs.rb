crumb :root do
  link 'Dashboard', root_path
end

crumb :about do
  link 'About', about_path
  parent :root
end

crumb :privacy_policy do
  link 'Privacy Policy', privacy_policy_path
  parent :root
end

crumb :terms_of_service do
  link 'Terms of Service', terms_of_service_path
  parent :root
end

crumb :user_profile do
  link 'Profile', user_profile_path
  parent :root
end

crumb :course do |course|
  link course.course_name, course_path(course)
  parent :root
end

crumb :new_course do
  link 'New Course', new_course_path
  parent :root
end

crumb :course_settings do |course|
  link 'Settings', settings_course_path(course)
  parent :course, course
end

crumb :course_add_students do |course|
  link 'Add Students', add_students_course_path(course)
  parent :course, course
end

crumb :course_add_lecturers do |course|
  link 'Add Lecturers', add_lecturers_course_path(course)
  parent :course, course
end

crumb :course_participant_profile do |course, participant_name|
  link participant_name, '#'
  parent :course, course # change to :course_participants later
end

crumb :edit_project_template do |course|
  link 'Edit Template', edit_course_project_template_path(course)
  parent :course, course
end

crumb :topics do |course|
  link 'Topics', course_topics_path(course)
  parent :course, course
end

crumb :topic do |topic|
  link topic.topic_instances.last&.title
  parent :topics, topic.course
end

crumb :new_topic do |course|
  link 'New Topic', new_course_topic_path(course)
  parent :topics, course
end

crumb :edit_topic do |topic|
  link 'Edit', edit_course_topic_path(topic.course, topic)
  parent :topic, topic
end

crumb :project do |project|
  link project.project_instances.last&.title, course_project_path(project.course, project)

  if params[:lecturer_id]
    lecturer = ::User.find(params[:lecturer_id])
    parent :lecturer, project.course, lecturer

  elsif params[:from_participant] && params[:participant_type]
    participant_name = if params[:participant_type] == 'group'
                         ::ProjectGroup.find(params[:from_participant]).group_name
                       else
                         ::User.find(params[:from_participant]).username
                       end
    parent :course_participant_profile, project.course, participant_name
  else
    parent :course, project.course
  end
end

crumb :new_project do |course|
  link 'New Project', new_course_project_path(course)
  parent :course, course
end

crumb :edit_project do |project|
  link 'Edit', edit_course_project_path(project.course, project)
  parent :project, project
end

crumb :progress_update do |progress_update|
  project = progress_update.project
  link 'Progress Update', course_project_progress_update_path(project.course, project, progress_update)
  parent :project, project
end

crumb :new_progress_update do |project|
  link 'New Progress Update', new_course_project_progress_update_path(project.course, project)
  parent :project, project
end

crumb :edit_progress_update do |progress_update|
  project = progress_update.project
  link 'Edit Progress Update', edit_course_project_progress_update_path(project.course, project, progress_update)
  parent :progress_update, progress_update
end

crumb :lecturer do |course, lecturer|
  link lecturer.username, course_lecturer_path(course, lecturer)
  parent :course, course
end

crumb :topic do |topic|
  link topic.topic_instances.last&.title

  if params[:lecturer_id]
    # From lecturer/show
    lecturer = ::User.find(params[:lecturer_id])
    parent :lecturer, topic.course, lecturer
  else
    # From topics/index
    parent :topics, topic.course
  end
end
