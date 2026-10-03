require "rails_helper"

RSpec.describe "Admin::SponsorVisits", type: :request do
  let(:organizer) { FactoryBot.create(:user, role: :organizer) }
  let(:target_user) { FactoryBot.create(:user, role: :organizer) }
  let(:event) { FactoryBot.create(:event) }

  describe "DELETE /admin/users/:user_id/sponsor_visits" do
    let!(:visit) { FactoryBot.create(:sponsor_visit, user: target_user, event: event) }

    context "when the acting and target users are organizers" do
      let!(:another_visit) { FactoryBot.create(:sponsor_visit, user: target_user, event: event, sponsor_key: "another.example") }
      let!(:other_event_visit) { FactoryBot.create(:sponsor_visit, user: target_user) }
      let!(:other_user_visit) { FactoryBot.create(:sponsor_visit, event: event) }

      before { sign_in(organizer) }

      it "deletes all stamps only for the specified organizer and event" do
        expect {
          delete admin_user_sponsor_visits_path(target_user), params: {event_id: event.id}
        }.to change(SponsorVisit, :count).by(-2)

        expect(target_user.sponsor_visits.where(event: event)).not_to exist
        expect(SponsorVisit.where(id: [other_event_visit.id, other_user_visit.id]).count).to eq(2)
        expect(response).to redirect_to(admin_user_path(target_user))
        expect(response).to have_http_status(:see_other)
        expect(flash[:success]).to eq("Reset succeeded for #{event.name}.")
      end
    end

    context "when the acting user is a participant" do
      let(:participant) { FactoryBot.create(:user, role: :participant) }

      before { sign_in(participant) }

      it "does not delete stamps and redirects to the root page" do
        expect {
          delete admin_user_sponsor_visits_path(target_user), params: {event_id: event.id}
        }.not_to change(SponsorVisit, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the target user is a participant" do
      let(:target_user) { FactoryBot.create(:user, role: :participant) }

      before { sign_in(organizer) }

      it "does not delete stamps and returns not found" do
        expect {
          delete admin_user_sponsor_visits_path(target_user), params: {event_id: event.id}
        }.not_to change(SponsorVisit, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the acting user is an operator" do
      let(:operator) { FactoryBot.create(:user, role: :operator) }

      before { sign_in(operator) }

      it "does not delete stamps and redirects to the root page" do
        expect {
          delete admin_user_sponsor_visits_path(target_user), params: {event_id: event.id}
        }.not_to change(SponsorVisit, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the target user is an operator" do
      let(:target_user) { FactoryBot.create(:user, role: :operator) }

      before { sign_in(organizer) }

      it "does not delete stamps and returns not found" do
        expect {
          delete admin_user_sponsor_visits_path(target_user), params: {event_id: event.id}
        }.not_to change(SponsorVisit, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    it "rejects a logged-out user" do
      expect {
        delete admin_user_sponsor_visits_path(target_user), params: {event_id: event.id}
      }.not_to change(SponsorVisit, :count)

      expect(response).to redirect_to(root_path)
    end

    context "when the event ID is missing" do
      before { sign_in(organizer) }

      it "does not delete stamps and returns not found" do
        expect {
          delete admin_user_sponsor_visits_path(target_user)
        }.not_to change(SponsorVisit, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
