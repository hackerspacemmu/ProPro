require 'test_helper'
require 'tempfile'

class SoloImportTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @course = create(:course)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @student = create(:user, email_address: 'existing-student@example.com')
    create(:enrolment, user: @student, course: create(:course))
    sign_in @coordinator
  end

  test 'an existing student is invited using their email address' do
    perform_enqueued_jobs do
      import_csv <<~CSV
        Last name,ID number,Email address
        Student,S-1001,existing-student@example.com
      CSV
    end

    assert_emails 1
    assert_equal [@student.email_address], ActionMailer::Base.deliveries.last.to
  end

  private

  def import_csv(csv)
    post handle_add_students_course_path(@course), params: { csv_file: csv_upload(csv) }
  end

  def csv_upload(csv)
    file = Tempfile.new(['students', '.csv'])
    file.write(csv)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: 'students.csv')
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
