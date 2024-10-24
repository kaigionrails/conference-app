class SendAnnouncementPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(announcement_id, message)
    # TODO: DRY
    WebpushSubscription.all.find_each do |subscription|
      WebPush.payload_send(
        endpoint: subscription.endpoint,
        message: JSON.generate(message),
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {
          subject: Rails.configuration.x.webpush.vapid_subject_mailto,
          public_key: Rails.configuration.x.webpush.vapid_public_key,
          private_key: Rails.configuration.x.webpush.vapid_private_key
        }
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      # endpoint was expired or invalid
      subscription.destroy!
    end
  end
end
