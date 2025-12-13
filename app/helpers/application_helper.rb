module ApplicationHelper
  def format_timestamp(datetime)
    return '-' if datetime.blank?

    datetime.strftime('%I:%M %p, %d %b %Y')
  end

  def sidebar_link(label, path)
    base_classes = 'group flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors duration-150 ease-in-out w-full'

    # convert path to a string
    path_str = path.to_s
    is_active = if path_str.start_with?('#')
                  false
                else
                  # Returns true if you are on the page OR a sub-page.
                  # e.g. Link '/projects' stays active when viewing '/projects/1'
                  request.path.start_with?(path_str) && path_str != '/'
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
