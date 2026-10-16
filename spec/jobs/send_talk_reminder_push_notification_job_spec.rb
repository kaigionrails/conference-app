require "rails_helper"

RSpec.describe SendTalkReminderPushNotificationJob, type: :job do
  let(:talk) { FactoryBot.create(:talk, start_at: 2.minutes.from_now) }

  it "sends the reminder with the digested icon URL and marks it sent" do
    subscription = FactoryBot.create(:webpush_subscription)
    reminder = FactoryBot.create(:talk_reminder, user: subscription.user, talk: talk, scheduled_at: 1.minute.ago)
    push = stub_request(:post, subscription.endpoint).to_return(status: 201)
    allow(WebPush).to receive(:payload_send).and_call_original

    described_class.perform_now

    expect(push).to have_been_requested
    expect(WebPush).to have_received(:payload_send) { |options|
      message = JSON.parse(options[:message])
      expect(message["body"]).to eq(talk.title)
      expect(message["icon"]).to match(%r{\Ahttp://localhost:3000/assets/icons/2026/512-\h+\.png\z})
    }
    expect(reminder.reload.sent_at).to be_present
  end

  it "marks the reminder sent when the user has no push subscription" do
    reminder = FactoryBot.create(:talk_reminder, talk: talk, scheduled_at: 1.minute.ago)

    described_class.perform_now

    expect(reminder.reload.sent_at).to be_present
  end

  it "leaves reminders outside the last 5 minutes alone" do
    missed = FactoryBot.create(:talk_reminder, talk: talk, scheduled_at: 10.minutes.ago)
    upcoming = FactoryBot.create(:talk_reminder, talk: talk, scheduled_at: 1.minute.from_now)

    described_class.perform_now

    expect(missed.reload.sent_at).to be_nil
    expect(upcoming.reload.sent_at).to be_nil
  end
end
