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

  def update_stream
    client = CloudflareApiClient.new
    live_response = client.retrieve_live_input(uid)
    if !live_response["success"]
      # maybe the live input has gone.
      destroy
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

  def url
    stream_videos_raw_response.dig("result", 0, "playback", "hls")
  end
end
