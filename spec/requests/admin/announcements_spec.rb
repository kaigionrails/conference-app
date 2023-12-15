require "rails_helper"

RSpec.describe "Admin::Announcements", type: :request do
  let(:admin) { FactoryBot.create(:user, role: "organizer") }

  describe "PATCH /announcement/:id" do
    before { sign_in(admin) }

    context "when status will change from draft to published" do
      let(:announcement) { FactoryBot.create(:announcement, status: "draft") }
      it "should enqueue broadcast job" do
        expect {
          patch admin_announcement_path(announcement), params: {
            announcement: {status: "published"}
          }
        }.to have_enqueued_job(BroadcastAnnouncementJob)
      end
    end

    context "when status not changed" do
      let(:announcement) { FactoryBot.create(:announcement, status: "draft") }
      it "should enqueue broadcast job" do
        expect {
          patch admin_announcement_path(announcement), params: {
            announcement: {title: "Test2"}
          }
        }.not_to have_enqueued_job(BroadcastAnnouncementJob)
      end
    end
  end
end
