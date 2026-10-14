class CloudflareStreamLiveStream < ApplicationRecord
  belongs_to :event

  # @rbs uid: String
  # @rbs return: boolish
  def self.create_by_stream_uid(uid)
    response = CloudflareApiClient.new.retrieve_live_input(uid)
    return unless response["errors"].empty?

    live_stream = CloudflareStreamLiveStream.new
    live_stream.event_id = OngoingEvent.first.event.id
    live_stream.uid = response["result"]["uid"]
    live_stream.name = response["result"]["meta"]["name"]
    live_stream.stream_raw_response = response
    live_stream.save
  end

  # @rbs destroy_when_gone: bool
  def update_stream(destroy_when_gone: true)
    client = CloudflareApiClient.new
    live_response = client.retrieve_live_input(uid)
    if !live_response["success"]
      # maybe the live input has gone.
      destroy if destroy_when_gone
      return false
    end

    live_videos_response = client.retrieve_live_input_videos(uid)
    return false unless live_videos_response["success"]

    self.name = live_response["result"]["meta"]["name"]
    self.stream_raw_response = live_response
    self.stream_videos_raw_response = live_videos_response
    save
  end

  def retrieve_videos
    response = CloudflareApiClient.new.retrieve_live_input_videos(uid)
    return unless response["errors"].empty?

    self.stream_videos_raw_response = response
    save
  end

  # The HLS URL of the live input itself, which plays only the ongoing broadcast.
  # The URL of a video from the videos API plays its recording once the broadcast ends.
  def url
    stream_raw_response&.dig("result", "playback", "hls")
  end

  # A live input cannot be renamed after it is created, so the live stream page
  # assigns it to a hall and an audio by the keys of its meta instead of its name.
  # @rbs return: Hash[String, untyped]
  def meta
    stream_raw_response&.dig("result", "meta") || {}
  end

  # @rbs return: String?
  def hall
    meta["hall"]
  end

  # @rbs return: String?
  def lang
    meta["lang"]
  end

  # Any value in the test key, such as "true" or "1", makes it the stream of #test.
  # @rbs return: bool
  def test?
    meta["test"].present?
  end
end
