# frozen_string_literal: true

# @rbs module-self Speaker
module SpeakerDecorator
  def sanitized_bio
    markdown = Commonmarker.to_html(bio)
    sanitizer.sanitize(markdown).html_safe
  end

  def avatar_image_url
    avatar.attached? ? avatar : "https://www.gravatar.com/avatar/#{gravatar_hash}?s=100"
  end

  # @rbs @sanitizer: Rails::Html::SafeListSanitizer

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
