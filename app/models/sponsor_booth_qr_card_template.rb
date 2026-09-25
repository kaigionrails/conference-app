# The background image that SponsorBoothQrCard composites a sponsor logo and a stamp QR code onto.
# One per event; organizers upload it from the admin Sponsor QR Codes page.
class SponsorBoothQrCardTemplate < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze #: Array[String]
  # width / height of A5 portrait. Templates with bleed (154:216 mm) fall outside the tolerance.
  A5_ASPECT_RATIO = 148.0 / 210.0 #: Float
  ASPECT_RATIO_TOLERANCE = 0.01 #: Float

  belongs_to :event
  has_one_attached :image

  validates :event_id, uniqueness: true
  validates :image, presence: true
  validate :image_content_type
  validate :image_aspect_ratio

  private def image_content_type
    return unless image.attached?
    return if ALLOWED_CONTENT_TYPES.include?(image.content_type)

    errors.add(:image, "content type #{image.content_type} is not allowed")
  end

  # Active Storage analyzes blobs in a background job, so the dimensions are read from the upload itself.
  # Only a newly assigned image is read; a stored one was validated when it was uploaded.
  private def image_aspect_ratio
    change = attachment_changes["image"]
    return if change.nil?
    return unless ALLOWED_CONTENT_TYPES.include?(image.content_type)

    width, height = read_dimensions(change.attachable)
    return if ((width.to_f / height) - A5_ASPECT_RATIO).abs <= A5_ASPECT_RATIO * ASPECT_RATIO_TOLERANCE

    errors.add(:image, "must be A5 portrait (148:210), got #{width}x#{height}")
  rescue Vips::Error
    errors.add(:image, "could not be read as an image")
  end

  # @rbs attachable: untyped
  # @rbs return: [Integer, Integer]
  private def read_dimensions(attachable)
    case attachable
    when Hash
      io = attachable.fetch(:io)
      data = io.read
      io.rewind
      dimensions_of(Vips::Image.new_from_buffer(data, ""))
    when ActiveStorage::Blob, String
      dimensions_of(Vips::Image.new_from_buffer(image.blob.download, ""))
    else
      # ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile and File
      dimensions_of(Vips::Image.new_from_file(attachable.path))
    end
  end

  # @rbs vips_image: Vips::Image
  # @rbs return: [Integer, Integer]
  private def dimensions_of(vips_image)
    rotated = vips_image.autorot
    [rotated.width, rotated.height]
  end
end
