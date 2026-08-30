class AddEmailDomainRestrictionToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :email_domain_restriction, :string
    add_column :courses, :email_domain_restriction_enabled, :boolean
  end
end
