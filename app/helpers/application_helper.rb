module ApplicationHelper
  def format_timestamp(datetime)
    return '-' if datetime.blank?

    datetime.strftime('%I:%M %p, %d %b %Y')
  end

  def sidebar_link(label, path)
    base_classes = 'group flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-150 ease-in-out w-full'
    #  Check if this is the current page (Only works for standard paths, not anchors like '#')
    #  use 'rescue false' because checking current_page? on '#' sometimes throws errors
    is_active = begin
      (path.to_s.start_with?('/') || path.to_s.include?('_path')) && current_page?(path)
    rescue StandardError
      false
    end

    if is_active
      active_classes = 'bg-blue-50 text-blue-700'
      css_class = "#{base_classes} #{active_classes}"
    else
      inactive_classes = 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
      css_class = "#{base_classes} #{inactive_classes}"
    end

    link_to label, path, class: css_class
  end
end

