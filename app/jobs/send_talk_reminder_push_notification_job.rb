class SendTalkReminderPushNotificationJob < ApplicationJob
  include Rails.application.routes.url_helpers
  queue_as :default

  def perform(*args)
    will_send_reminders = TalkReminder
      .eager_load(talk: :event, user: :webpush_subscriptions).where(sent_at: nil, scheduled_at: 5.minutes.ago..Time.current)

    assets_resolver = DigestedAssetsPathResolver.new

    will_send_reminders.each do |reminder|
      message = {
        title: "もうすぐブックマークしたトークが始まります",
        body: reminder.talk.title,
        icon: URI.join(
          Rails.configuration.application_url, assets_resolver.digested_asset_path("icons/2024/512.png")
        ).to_s,
        data: {
          url: event_talk_url(
            event_slug: reminder.talk.event.slug,
            id: reminder.talk,
            host: Rails.configuration.application_url
          )
        }
      }

      ApplicationRecord.transaction do
        reminder.user.send_push_notification(message)
        reminder.update!(sent_at: Time.current)
      end
    end
  end
end
