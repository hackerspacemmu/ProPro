module BreadcrumbHelper
  def render_custom_breadcrumbs
    return unless breadcrumbs.present? && breadcrumbs.any?

    content_for(:breadcrumbs) do
      tag.nav(class: 'flex flex-wrap items-center text-sm text-gray-500 w-full min-w-0 my-2') do
        elements = breadcrumbs.map.with_index do |crumb, index|
          is_last = index == breadcrumbs.count - 1

          if is_last
            tag.span(crumb.text, class: 'text-gray-900 font-semibold break-all')
          else
            link = link_to(
              crumb.text,
              crumb.url,
              class: 'hover:text-gray-900 font-medium transition-colors no-underline whitespace-nowrap'
            )

            separator = tag.span('>', class: 'px-2 text-gray-500 text-xs select-none')

            safe_join([link, separator])
          end
        end

        safe_join(elements)
      end
    end
  end
end
