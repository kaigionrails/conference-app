require "faraday"

class CloudflareApiClient
  # @rbs @account_id: String
  # @rbs @api_token: String

  # @rbs return: void
  def initialize
    @account_id = Rails.configuration.x.cloudflare.account_id
    @api_token = Rails.configuration.x.cloudflare.api_token
  end

  # @rbs return: Hash[untyped, untyped]
  def list_live_inputs
    client.get("/client/v4/accounts/#{@account_id}/stream/live_inputs").body
  end

  # @see https://developers.cloudflare.com/api/operations/stream-live-inputs-create-a-live-input
  # @rbs name: String
  # @rbs return: Hash[untyped, untyped]
  def create_live_input(name:)
    # param = {
    #   meta: {
    #     name: name
    #   },
    #   recording: {
    #     mode: "automatic"
    #   }
    # }
    client.post("/client/v4/accounts/#{@account_id}/stream/live_inputs")
  end

  # @param [String] uid
  # @see https://developers.cloudflare.com/api/operations/stream-live-inputs-retrieve-a-live-input
  # @rbs uid: String
  # @rbs return: Hash[untyped, untyped]
  def retrieve_live_input(uid)
    client.get("/client/v4/accounts/#{@account_id}/stream/live_inputs/#{uid}").body
  end

  # @rbs uid: String
  # @rbs return: Hash[untyped, untyped]
  def retrieve_live_input_videos(uid)
    client.get("/client/v4/accounts/#{@account_id}/stream/live_inputs/#{uid}/videos").body
  end

  # The recordings of live inputs come as type=vod, not type=live, so this takes no type.
  # It neither takes include_counts, which turns the result into an object holding the videos.
  # @see https://developers.cloudflare.com/api/resources/stream/methods/list/
  # @rbs status: String?
  # @rbs before: String?
  # @rbs limit: Integer?
  # @rbs return: Hash[untyped, untyped]
  def list_streams(status: nil, before: nil, limit: nil)
    client.get("/client/v4/accounts/#{@account_id}/stream", {status:, before:, limit:}.compact).body
  end

  # @see https://developers.cloudflare.com/api/resources/stream/methods/get/
  # @rbs uid: String
  # @rbs return: Hash[untyped, untyped]
  def retrieve_stream(uid)
    client.get("/client/v4/accounts/#{@account_id}/stream/#{uid}").body
  end

  # The admin pages call the API while rendering, so a slow API must not hold them
  # for the 60 seconds that Net::HTTP waits by default.
  private def client
    @client ||= Faraday.new(
      url: "https://api.cloudflare.com",
      headers: {Authorization: "Bearer #{@api_token}", "Content-Type": "application/json"},
      request: {open_timeout: 5, timeout: 10}
    ) do |builder|
      builder.response :json
    end
  end
end
