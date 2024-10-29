# frozen_string_literal: true

# @rbs module-self Profile
module ProfileDecorator
  def sanitized_description
    markdown = Commonmarker.to_html(description)
    sanitizer.sanitize(markdown).html_safe
  end

  # @rbs @sanitizer: Rails::Html::SafeListSanitizer

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
