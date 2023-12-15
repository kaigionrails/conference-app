require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { FactoryBot.create(:user) }

  describe "#mark_all_announcement_unread!" do
    context "there is no published announcement" do
      let(:event) { FactoryBot.create(:event) }
      let!(:announcements) { FactoryBot.create_list(:announcement, 3, event: event) }
      it "should not create any UnreadAnnouncement" do
        expect { user.mark_all_announcement_unread!(event) }.not_to change { UnreadAnnouncement.where(user: user).count }
      end
    end

    context "there is some published announcement" do
      let(:event) { FactoryBot.create(:event) }
      let!(:announcements_published) { FactoryBot.create_list(:announcement, 3, :published, event: event) }
      let!(:announcements_draft) { FactoryBot.create_list(:announcement, 2, event: event) }
      it "should create UnreadAnnouncement for number of published announcements" do
        expect { user.mark_all_announcement_unread!(event) }.to change { UnreadAnnouncement.where(user: user).count }.by(3)
      end
    end

    context "there is some published announcement but another event" do
      let(:event1) { FactoryBot.create(:event) }
      let(:event2) { FactoryBot.create(:event) }
      let!(:announcements_published) { FactoryBot.create_list(:announcement, 3, :published, event: event1) }
      it "should create UnreadAnnouncement for number of published announcements" do
        expect { user.mark_all_announcement_unread!(event2) }.not_to change { UnreadAnnouncement.where(user: user).count }
      end
    end
  end
end
