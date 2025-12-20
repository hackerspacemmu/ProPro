module SidebarHelper
  def render_sidebar(&block)
    content_for :sidebar do
      tag.div(
        class: [
          'h-[calc(100vh-70px)] sticky top-[70px] left-0 z-20',
          'bg-[#f8f9fa] border-r border-gray-200',
          'overflow-x-hidden overflow-y-auto',

          'transition-all duration-300 ease-in-out',

          'w-0 opacity-0',
          'lg:w-64 lg:opacity-100'
        ],
        data: { sidebar_target: 'container' } # connect to stimulus controller (js)
      ) do
        tag.div(class: 'w-50 lg:w-64 p-4 space-y-1 font-medium text-sm text-gray-600') do
          capture(&block)
        end
      end
    end
  end

  def sidebar_link(label, path)
    link_to(
      label,
      path,
      class: 'block px-3 py-2 rounded-md hover:bg-gray-200 hover:text-gray-900 transition-colors'
    )
  end
end
