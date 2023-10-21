# frozen_string_literal: true

module TalkDecorator
  def sanitized_abstract
    markdown = Commonmarker.to_html(abstract)
    # Allow style attribute for fenced code blocks
    sanitizer.sanitize(markdown, attributes: %w(href style)).html_safe
  end

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
