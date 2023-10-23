require 'rails_helper'

RSpec.describe BroadcastAnnouncementJob, type: :job do
  describe "#perform_now" do
    let(:announcement) { FactoryBot.create(:announcement, status: "published") }
    let!(:users) { FactoryBot.create_list(:user, 10) }

    it "should create UnreadAnnouncement per users" do
      expect { BroadcastAnnouncementJob.perform_now(announcement.id) }.to change {
        UnreadAnnouncement.count
      }.by(10)
    end
  end
end
