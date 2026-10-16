class SendTalkReminderPushNotificationJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(*args)
    will_send_reminders = TalkReminder
      .eager_load(talk: :event, user: :webpush_subscriptions).where(sent_at: nil, scheduled_at: 5.minutes.ago..Time.current)

    icon = ActionController::Base.helpers.image_url("icons/2026/512.png", host: Rails.configuration.application_url) # MEMO: change every year

    will_send_reminders.each do |reminder|
      message = {
        title: I18n.t("talk_reminder.bookmarked_talk_will_start_soon"),
        body: reminder.talk.title,
        icon: icon,
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
