module BreadcrumbHelper
  def render_custom_breadcrumbs
    return unless breadcrumbs.present? && breadcrumbs.any?

    content_for(:breadcrumbs) do
      elements = breadcrumbs.map.with_index do |crumb, index|
        is_last = index == breadcrumbs.count - 1

        if is_last
          tag.span(crumb.text, class: 'text-gray-900 font-medium truncate')
        else
          link = link_to(
            crumb.text,
            crumb.url,
            class: 'text-gray-500 hover:text-gray-900 font-medium transition-colors no-underline'
          )
          separator = tag.span('>', class: 'mx-3 text-gray-400')

          safe_join([link, separator])
        end
      end

      safe_join(elements)
    end
  end
end
