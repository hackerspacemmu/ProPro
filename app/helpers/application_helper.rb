module ApplicationHelper
  def format_timestamp(datetime)
    return '-' if datetime.blank?
    datetime.in_time_zone("Asia/Singapore").strftime("%I:%M %p, %d %b %Y")
  end
end
