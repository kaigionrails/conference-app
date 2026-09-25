class SponsorVisitToken
  TOKEN_LENGTH = 43

  def self.stamp_url(event_slug:, sponsor_key:)
    uri = URI.parse(Rails.configuration.application_url)
    Rails.application.routes.url_helpers.new_sponsor_passport_stamp_url(
      event_slug,
      code: generate(event_slug:, sponsor_key:),
      host: uri.host,
      protocol: uri.scheme,
      port: uri.port,
      script_name: uri.path.to_s.delete_suffix("/")
    )
  end

  def self.generate(event_slug:, sponsor_key:)
    digest = OpenSSL::HMAC.digest(
      "SHA256",
      Rails.configuration.x.sponsor_visit_token_secret,
      "#{event_slug}:#{sponsor_key}"
    )
    Base64.urlsafe_encode64(digest, padding: false)
  end

  def self.find_sponsor(event_slug:, sponsors:, token:)
    return if token.blank? || token.bytesize != TOKEN_LENGTH

    sponsors.find do |sponsor|
      expected_token = generate(event_slug: event_slug, sponsor_key: sponsor.fetch(:key))
      ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
    end
  end
end
