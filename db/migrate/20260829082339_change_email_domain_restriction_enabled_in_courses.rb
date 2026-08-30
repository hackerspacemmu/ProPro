class ChangeEmailDomainRestrictionEnabledInCourses < ActiveRecord::Migration[8.0]
  def change
    change_column_default :courses, :email_domain_restriction_enabled, from: nil, to: false
  end
end
