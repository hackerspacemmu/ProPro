# Service Extraction Candidates

This document maps high fan-in business logic in the repo to service-object candidates, using the conventions you described.

## Why this is a good refactor direction

- `app/controllers` currently contains large, transactional imperative flows. These are strong service-object candidates because they represent use-cases rather than request/response plumbing.
- `app/models/course.rb` contains business rules and calculations that are specific enough to be extracted as domain services or value objects.
- There is currently no `app/services` directory in the repo, so a new service layer is a clean addition.

## Naming conventions

Use nouns for service classes and explicit verb methods:
- `CourseCreator#create`
- `ProjectCreator#create`
- `CourseStudentImporter#import`

Avoid:
- generic names like `Service` or `call`
- class methods on service objects
- heavy dependency-injection patterns in the first pass

Return rich result objects instead of raw booleans or bare models.
For example:
- `ServiceResult.new(success: true, entity: course)`
- `ServiceResult.new(success: false, errors: [...])`

---

## Candidate services

### 1. `CourseCreator#create`
**Source:** `CoursesController#create`

**Why:**
- encapsulates course creation plus coordinator/lecturer enrolments and default template creation
- currently lives in controller with transaction and validation logic
- a service makes the action easier to test and keeps the controller thin

**What it would need:**
- the current user
- `course_name`, `grouped`, and any initial course attributes

**Returns:**
- rich result containing created course or errors

---

### 2. `CourseStudentImporter#import`
**Source:** `CoursesController#handle_add_students`, `Course#parse_csv_grouped`, `Course#parse_csv_solo`, `CoursesController#create_db_entries_grouped`, `CoursesController#create_db_entries_solo`

**Why:**
- this is a complex, multi-step import flow with CSV parsing, validation, user lookup/creation, enrolments, groups, OTP generation, and notification preparation
- it is a classic case for a service object because it is a single domain use-case
- it currently leaks into the controller and the course model

**What it would need:**
- course instance
- uploaded CSV file / parsed CSV data
- current user or request context only if needed for notifications

**Returns:**
- import result object with `success`, `created_users`, `registered_emails`, `invite_emails`, `errors`

---

### 3. `CourseLecturerImporter#import`
**Source:** `CoursesController#handle_add_lecturers`, `CoursesController#create_lecturer_enrolments`

**Why:**
- the controller currently handles email parsing, user creation, otp generation, enrolment creation, and notification queuing
- this is another concrete business flow that should be isolated from web-specific behavior

**What it would need:**
- course instance
- raw lecturer emails

**Returns:**
- `success`, `unregistered_lecturers`, `registered_lecturers`, `errors`

---

### 4. `CourseSettingsUpdater#update`
**Source:** `CoursesController#handle_settings`, `Course#disable_grouping!`, `Course#revert_to_default_mode!`

**Why:**
- updates multiple related course flags and performs grouped state transitions
- it currently contains transaction logic and conditional side effects in the controller
- extraction would reduce controller complexity and centralize update semantics

**What it would need:**
- course instance
- permitted params hash

**Returns:**
- `success`, `course`, `errors`

---

### 5. `ProjectCreator#create`
**Source:** `ProjectsController#create`

**Why:**
- creates a new project and its first project instance, handles grouped vs solo ownership, topic-based or lecturer-based proposal selection, field persistence, and email notification
- the controller currently mixes validation, business rules, object creation, and presentation logic
- a service can consume plain params and the course/project context and return a result

**What it would need:**
- course instance
- current user
- `based_on_topic` or supervisor choice
- field values

**Returns:**
- `success`, `project`, `project_instance`, `errors`

---

### 6. `TopicCreator#create`
**Source:** `TopicsController#create`

**Why:**
- topic creation requires topic and topic instance creation, title extraction, status selection, and field persistence
- the current controller has a transaction and low-level persistence details
- this is well-suited to a service object

**What it would need:**
- course instance
- current user
- field values

**Returns:**
- `success`, `topic`, `topic_instance`, `errors`

---

### 7. `TopicUpdater#update`
**Source:** `TopicsController#update`

**Why:**
- updates a topic version, handles coordinator comment state, title selection, field upserts, and status rules
- current logic is procedural and belongs in a dedicated domain flow

**What it would need:**
- topic instance or topic
- current user
- field values
- `has_coordinator_comment`

**Returns:**
- `success`, `topic_instance`, `errors`

---

### 8. `ProjectStatusUpdater#update_status`
**Source:** `ProjectsController#change_status`

**Why:**
- status change is a discrete business operation with side effects (mailer delivery)
- currently the controller updates the latest instance directly and sends mail
- a service provides a cleaner place for rules and notifications

**What it would need:**
- project instance or project
- new status
- current user

**Returns:**
- `success`, `project_instance`, `errors`

---

### 9. `TopicStatusUpdater#update_status`
**Source:** `TopicsController#change_status`

**Why:**
- same pattern as project status change: status update plus notification side effects
- extraction makes controllers slimmer and gives a location for future approval rules

**What it would need:**
- topic instance or topic
- new status
- current user

**Returns:**
- `success`, `topic_instance`, `errors`

---

### 10. `CourseCsvExporter#export`
**Source:** `CoursesController#export_csv` and private CSV builder helpers

**Why:**
- export logic is isolated, deterministic, and useful as a plain service or presenter
- they already have a natural boundary: course, template fields, participants

**What it would need:**
- course instance
- optional `student_list` / `group_list`

**Returns:**
- raw CSV text or structured rows

---

### 11. `SupervisorCapacityCalculator#calculate`
**Source:** `Course#lecturer_capacity`, `Course#auto_calculate_capacity`, and `Course#max_capacity_for`

**Why:**
- this is business logic that belongs in a domain service or value object rather than the model if the rules grow more complex
- it can be made explicit: `SupervisorCapacityCalculator.new(course, lecturer).calculate`

**What it would need:**
- course instance
- lecturer enrolment

**Returns:**
- capacity details hash or result object

---

## Suggested folder structure

- `app/services/course_creator.rb`
- `app/services/course_student_importer.rb`
- `app/services/course_lecturer_importer.rb`
- `app/services/course_settings_updater.rb`
- `app/services/project_creator.rb`
- `app/services/topic_creator.rb`
- `app/services/topic_updater.rb`
- `app/services/project_status_updater.rb`
- `app/services/topic_status_updater.rb`
- `app/services/course_csv_exporter.rb`
- `app/services/supervisor_capacity_calculator.rb`

## How to wire it in controllers

Controller actions should become thin orchestrators:
- authorize
- build input params
- call service instance method with the necessary objects/data
- handle result success/failure

Example:
```ruby
result = CourseStudentImporter.new(course: @course, csv: params[:csv_file]).import
if result.success?
  redirect_to course_path(@course)
else
  redirect_back_or_to '/', alert: result.errors.join(', ')
end
```

## Why I chose these specific spots

- `CoursesController` has the largest file and highest concentration of domain logic combined with transaction handling.
- `Course` model has business rules and calculations that are already more than simple persistence behavior.
- `ProjectsController#create` and `TopicsController#create/update` each contain complete domain use-cases suitable for single-responsibility services.
- status-change actions and export generation are compact but still real domain behaviors worth isolating.

---

## Notes

- Keep service classes instance-based and explicit.
- Pass the data/context needed for the operation rather than passing controllers or many other service objects.
- Return structured results so callers can handle failure details cleanly.
- If you want, I can next sketch the exact service class signatures and sample implementations for the top 3 candidates.
