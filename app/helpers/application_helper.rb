module ApplicationHelper

  def format_timestamp(datetime)
    return '-' if datetime.blank?
    datetime.strftime("%I:%M %p, %d %b %Y")
  end
end