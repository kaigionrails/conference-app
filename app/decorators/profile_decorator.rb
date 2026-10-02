# frozen_string_literal: true

# @rbs module-self Profile
module ProfileDecorator
  def sanitized_description
    markdown = Commonmarker.to_html(description)
    sanitizer.sanitize(markdown).html_safe
  end

  # The first image as the header shows it, or nil without one.
  #
  # @rbs return: ActiveStorage::VariantWithRecord | ActiveStorage::Attachment | nil
  def icon_image
    first_image_as(:icon)
  end

  # The first image as friend lists show it, or nil without one.
  #
  # @rbs return: ActiveStorage::VariantWithRecord | ActiveStorage::Attachment | nil
  def thumb_image
    first_image_as(:thumb)
  end

  # @rbs @sanitizer: Rails::Html::SafeListSanitizer

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end

  # Uploads are not restricted to formats a variant can be made from (an SVG,
  # say), and asking for one raises. Those are shown as they are.
  #
  # @rbs variant: Symbol
  # @rbs return: ActiveStorage::VariantWithRecord | ActiveStorage::Attachment | nil
  private def first_image_as(variant)
    image = images.first
    return if image.nil?

    image.variable? ? image.variant(variant) : image
  end
end
