class HomescreenController < ApplicationController
  def show
    @courses = Current.user.courses.uniq
  end
end
