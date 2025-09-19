require "faraday"

class TitoApiClient
  # @rbs return: void
  def initialize(event_slug:, account_slug: nil)
    @api_token = Rails.configuration.x.tito.api_token
    @account_slug = account_slug || Rails.configuration.x.tito.account_slug
    @event_slug = event_slug
  end

  # @rbs return: Hash["tickets", [Hash[String, untyped]]]
  # @see https://ti.to/docs/api/admin/3.1#tickets-get-all-tickets
  def tickets
    client.get("/v3/#{@account_slug}/#{@event_slug}/tickets").body
  end

  # @rbs ticket_slug: String
  # @rbs return: Hash["ticket", Hash[String, untyped]]
  # @see https://ti.to/docs/api/admin/3.1#tickets-get-a-ticket
  def ticket(ticket_slug)
    client.get("/v3/#{@account_slug}/#{@event_slug}/tickets/#{ticket_slug}").body
  end

  private def client
    @client ||= Faraday.new(
      url: "https://api.tito.io",
      headers: {Authorization: "Token token=#{@api_token}", Accept: "application/json"}
    ) do |builder|
      builder.response :json
    end
  end
end
