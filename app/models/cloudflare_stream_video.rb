# A video on Cloudflare Stream, which the Stream API returns as a Hash.
# The recording of each broadcast to a live input is a video that has the live input in liveInput,
# and it stays on Stream even after the live input is deleted.
class CloudflareStreamVideo
  PER_PAGE = 50

  # @rbs @attributes: Hash[String, untyped]

  # The newest videos that are ready to stream, created before the given time, up to one more than PER_PAGE,
  # so that the 51st tells whether older ones exist.
  # They include the videos uploaded without a live input. The caller picks the recordings out of the page
  # after taking the cursor of the next page from the 50th, so that no video is skipped or repeated.
  # @rbs before: ActiveSupport::TimeWithZone?
  # @rbs return: Array[CloudflareStreamVideo]?
  def self.ready_videos(before: nil)
    cursor = before&.utc&.iso8601(6)
    response = CloudflareApiClient.new.list_streams(status: "ready", before: cursor, limit: PER_PAGE + 1)
    unless succeeded?(response)
      Rails.logger.warn("CloudflareStreamVideo: failed to list ready videos before=#{cursor.inspect} errors=#{errors_of(response).inspect}")
      return
    end

    response["result"].map { |attributes| new(attributes) }
  end

  # Any video, whether it is a recording that is ready or not; the caller checks #archive?.
  # @rbs uid: String
  # @rbs return: CloudflareStreamVideo?
  def self.find(uid)
    response = CloudflareApiClient.new.retrieve_stream(uid)
    unless succeeded?(response)
      Rails.logger.warn("CloudflareStreamVideo: failed to retrieve uid=#{uid} errors=#{errors_of(response).inspect}")
      return
    end

    new(response["result"])
  end

  # The JSON middleware leaves an HTML page of an error as a String,
  # whose String#[] returns "success" when the page contains the word.
  # @rbs response: untyped
  # @rbs return: bool
  private_class_method def self.succeeded?(response)
    response.is_a?(Hash) && response["success"] == true
  end

  # @rbs response: untyped
  # @rbs return: untyped
  private_class_method def self.errors_of(response)
    response["errors"] if response.is_a?(Hash)
  end

  # @rbs attributes: Hash[String, untyped]
  # @rbs return: void
  def initialize(attributes)
    @attributes = attributes
  end

  # @rbs return: String
  def uid
    @attributes.fetch("uid")
  end

  # Stream names a recording after the live input and the time it started, such as
  # "kaigionrails-2026-magenta-raw 17 Oct 26 00:29 UTC". The hall and the lang in the meta of the live input
  # do not come along.
  # @rbs return: String?
  def name
    @attributes.dig("meta", "name")
  end

  # @rbs return: String
  def display_name
    name.presence || uid
  end

  # @rbs return: String?
  def state
    @attributes.dig("status", "state")
  end

  # @rbs return: String?
  def live_input_uid
    @attributes["liveInput"]
  end

  # A recording of a live input that is ready to stream, which is what the archive pages deal with.
  # An ongoing broadcast is in "live-inprogress", and an uploaded video has no live input.
  # @rbs return: bool
  def archive?
    live_input_uid.present? && state == "ready"
  end

  # @rbs return: ActiveSupport::TimeWithZone?
  def created_at
    created = @attributes["created"]
    Time.zone.parse(created) if created
  end

  # Stream resizes the thumbnail to the height, but crops it to the default width of 640 unless fit is clip.
  # @rbs height: Integer
  # @rbs return: String?
  def thumbnail_url(height:)
    thumbnail = @attributes["thumbnail"]
    return unless thumbnail

    uri = URI.parse(thumbnail)
    resizing = [["height", height.to_s], ["fit", "clip"]] #: Array[[String, String]]
    uri.query = URI.encode_www_form(URI.decode_www_form(uri.query.to_s) + resizing)
    uri.to_s
  end

  # Whole seconds, or nil while Stream does not know the duration, which it returns as -1.
  # @rbs return: Integer?
  def duration
    seconds = @attributes["duration"]
    seconds.to_i if seconds && seconds >= 0
  end

  # @rbs return: String?
  def duration_text
    seconds = duration
    return unless seconds

    format("%d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
  end

  # The Stream Player, which lives on the customer subdomain of the preview URL.
  # The preview URL comes only after the encoding completes.
  # @rbs return: String?
  def player_url
    preview = @attributes["preview"]
    return unless preview

    "https://#{URI.parse(preview).host}/#{uid}/iframe"
  end
end
