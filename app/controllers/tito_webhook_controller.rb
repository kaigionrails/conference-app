# heavily inspired by https://github.com/ruby-no-kai/takeout-app/blob/master/app/controllers/tito_webhook_controller.rb
# @see https://ti.to/docs/api/admin/3.1#webhooks

class TitoWebhookController < ApplicationController
  before_action :verify_payload
  skip_before_action :verify_authenticity_token

  def create
    tito_event_name = request.headers["x-webhook-name"]
    return render(status: 400, json: {status: :unknown_type}) unless tito_event_name&.start_with?("ticket.")

    event = Event.find_by(slug: params[:event_slug])
    return render(status: 400, json: {status: :unknown_event}) unless event

    ticket = TitoTicket.find_or_initialize_by(tito_id: params[:id]&.to_i)
    ticket.assign_attributes(
      event: event,
      slug: params[:slug],
      reference: params[:reference],
      state: params[:state_name],
      unique_url: params[:url]
    )

    ApplicationRecord.transaction do
      if ticket.save
        render(status: 200, json: {status: :ok})
      else
        Sentry.capture_message("Failed to save TitoTicket", level: :error)
        render(status: 400, json: {status: :invalid_record})
      end
    end
  end

  private def verify_payload
    request.body.rewind
    body = request.body.read

    secret = Rails.application.config.x.tito.webhook_secret
    return unless secret

    given_signature = request.headers["tito-signature"] || ""
    signature = [OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), secret, body)].pack("m0").strip

    unless Rack::Utils.secure_compare(signature, given_signature)
      Rails.logger.warn "tito-signature: mismatch; given=#{given_signature.inspect}, expected:#{signature.inspect}"
      Sentry.capture_message("Failed to verify Tito webhook signature", level: :error)
      render(status: 406, json: {status: :signature_invalid})
    end
  end
end
