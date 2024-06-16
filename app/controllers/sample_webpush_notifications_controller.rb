class SampleWebpushNotificationsController < ApplicationController
  before_action :require_logged_in

  def create
    subscriptions = current_user!.webpush_subscriptions
    message = {
      title: "プッシュ通知のサンプルです",
      body: "このようなプッシュ通知が届きます。",
      icon: view_context.image_url("icons/2023/512.png"),
      data: {
        url: URI.join(Rails.configuration.application_url, setting_path)
      }
    }
    subscriptions.each do |subscription|
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
    rescue WebPush::ExpiredSubscription
      # endpoint was expired
      subscription.destroy!
    end
  end
end
