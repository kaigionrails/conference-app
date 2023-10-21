# frozen_string_literal: true

module SpeakerDecorator
  def sanitized_bio
    markdown = Commonmarker.to_html(bio)
    sanitizer.sanitize(markdown).html_safe
  end

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
