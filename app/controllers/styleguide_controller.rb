class StyleguideController < ApplicationController
  def show
    head :not_found unless Rails.env.development?
  end
end
