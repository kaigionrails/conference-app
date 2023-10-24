class WebpushSubscription < ApplicationRecord
  belongs_to :user

  def send_webpush!(message)
    WebPush.payload_send(
      endpoint: endpoint,
      message: JSON.generate(message),
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: {
        subject: Rails.configuration.x.webpush.vapid_subject_mailto,
        public_key: Rails.configuration.x.webpush.vapid_public_key,
        private_key: Rails.configuration.x.webpush.vapid_private_key,
      }
    )
  end
end
