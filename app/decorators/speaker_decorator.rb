# frozen_string_literal: true

# @rbs module-self Speaker
module SpeakerDecorator
  def sanitized_bio
    markdown = Commonmarker.to_html(bio)
    sanitizer.sanitize(markdown).html_safe
  end

  # An avatar that a variant cannot be made from is shown as it is.
  #
  # @rbs return: ActiveStorage::VariantWithRecord | ActiveStorage::Attached::One | String
  def avatar_image_url
    return "https://www.gravatar.com/avatar/#{gravatar_hash}?s=100" unless avatar.attached?

    avatar.variable? ? avatar.variant(:thumb) : avatar
  end

  # @rbs @sanitizer: Rails::Html::SafeListSanitizer

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
