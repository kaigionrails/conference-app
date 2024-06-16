require "rails_helper"

RSpec.describe "Announcements", type: :request do
  before { prepare_current_event }

  let(:event) { FactoryBot.create(:event) }

  describe "GET /announcements" do
    let!(:announcement) { FactoryBot.create(:announcement, :published, title: "FooBar", event: event) }
    let!(:draft_announcement) { FactoryBot.create(:announcement, title: "FizzBuzz", event: event) }

    context "not logged in" do
      it "can access to announcements list" do
        get event_announcements_path(event_slug: event.slug)
        expect(response.body).to include("FooBar")
        expect(response.body).not_to include("FizzBuzz")
        expect(response.body).not_to include("未読")
        expect(response.body).not_to include("既読")
      end
    end

    context "logged in" do
      let(:user) { FactoryBot.create(:user) }
      let!(:another_announcement) { FactoryBot.create(:announcement, :published, title: "FooBar2", event: event) }
      let!(:unread_announcement) { FactoryBot.create(:unread_announcement, user: user, announcement: announcement) }
      before { sign_in(user) }
      it "can access to announcements list, read/unread badge" do
        get event_announcements_path(event_slug: event.slug)
        expect(response.body).to include("FooBar")
        expect(response.body).not_to include("FizzBuzz")
        expect(response.body).to include("未読")
        expect(response.body).to include("既読")
      end
    end
  end
end
