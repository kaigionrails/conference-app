require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe "status" do
    context "already published" do
      let(:announcement) { FactoryBot.create(:announcement, status: "published", published_at: Time.current) }
      it "shouldn't change status to draft" do
        announcement.status = "draft"
        expect(announcement).to be_invalid
     end
    end

    context "when publish" do
      let(:announcement) { FactoryBot.create(:announcement, status: "draft") }
      it "should fill published_at timestamp" do
        announcement.published!
        expect(announcement.published_at).to be_a Time
        expect(announcement.published_at).to be <= Time.current
      end
    end
  end
end
