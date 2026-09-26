class HomescreenController < ApplicationController
  def show
    @courses = Current.user.courses_by_earliest_enrolment
  end
end
