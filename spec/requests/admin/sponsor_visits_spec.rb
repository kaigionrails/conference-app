require "rails_helper"

RSpec.describe "Admin::SponsorVisits", type: :request do
  let(:organizer) { FactoryBot.create(:user, role: :organizer) }
  let(:target_user) { FactoryBot.create(:user, role: :organizer) }
  let(:event) { FactoryBot.create(:event) }

  describe "DELETE /admin/users/:user_id/sponsor_visits" do
    let(:request_params) { {event_id: event.id} }

    subject(:reset_stamps) { delete admin_user_sponsor_visits_path(target_user), params: request_params }

    let!(:visit) { FactoryBot.create(:sponsor_visit, user: target_user, event: event) }

    context "when the acting and target users are organizers" do
      let!(:another_visit) { FactoryBot.create(:sponsor_visit, user: target_user, event: event, sponsor_key: "another.example") }
      let!(:other_event_visit) { FactoryBot.create(:sponsor_visit, user: target_user) }
      let!(:other_user_visit) { FactoryBot.create(:sponsor_visit, event: event) }

      before { sign_in(organizer) }

      it "resets visits even without a completion record" do
        expect { reset_stamps }.to change(SponsorVisit, :count).by(-2)

        expect(target_user.sponsor_visits.where(event: event)).not_to exist
        expect(SponsorVisit.where(id: [other_event_visit.id, other_user_visit.id]).count).to eq(2)
        expect(response).to redirect_to(admin_user_path(target_user))
        expect(response).to have_http_status(:see_other)
        expect(flash[:success]).to eq("Reset succeeded for #{event.name}.")
      end

      context "with completion records" do
        let!(:completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user: target_user, event:) }
        let!(:other_event_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user: target_user, event: other_event_visit.event) }
        let!(:other_user_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user: other_user_visit.user, event:) }

        it "deletes visits and completion only for the specified organizer and event" do
          expect { reset_stamps }.to change(SponsorVisit, :count).by(-2)
            .and change(SponsorStampRallyCompletion, :count).by(-1)

          expect(target_user.sponsor_visits.where(event:)).not_to exist
          expect(target_user.sponsor_stamp_rally_completions.where(event:)).not_to exist
          expect(SponsorVisit.where(id: [other_event_visit.id, other_user_visit.id]).count).to eq(2)
          expect(SponsorStampRallyCompletion.where(id: [other_event_completion.id, other_user_completion.id]).count).to eq(2)
          expect(response).to redirect_to(admin_user_path(target_user))
          expect(response).to have_http_status(:see_other)
          expect(flash[:success]).to eq("Reset succeeded for #{event.name}.")
        end

        context "when deleting completion raises an exception" do
          before do
            allow_any_instance_of(SponsorStampRallyCompletion).to receive(:destroy).and_raise("completion deletion failed")
          end

          it "rolls back visit deletion" do
            expect { reset_stamps }.to raise_error(RuntimeError, "completion deletion failed")

            expect(SponsorVisit.where(id: [visit.id, another_visit.id]).count).to eq(2)
            expect(SponsorStampRallyCompletion.exists?(completion.id)).to be(true)
          end
        end
      end
    end

    context "when the acting user is a participant" do
      let(:participant) { FactoryBot.create(:user, role: :participant) }

      before { sign_in(participant) }

      it "does not delete stamps and redirects to the root page" do
        expect { reset_stamps }.not_to change(SponsorVisit, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the target user is a participant" do
      let(:target_user) { FactoryBot.create(:user, role: :participant) }

      before { sign_in(organizer) }

      it "does not delete stamps and returns not found" do
        expect { reset_stamps }.not_to change(SponsorVisit, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the acting user is an operator" do
      let(:operator) { FactoryBot.create(:user, role: :operator) }

      before { sign_in(operator) }

      it "does not delete stamps and redirects to the root page" do
        expect { reset_stamps }.not_to change(SponsorVisit, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the target user is an operator" do
      let(:target_user) { FactoryBot.create(:user, role: :operator) }

      before { sign_in(organizer) }

      it "does not delete stamps and returns not found" do
        expect { reset_stamps }.not_to change(SponsorVisit, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    it "rejects a logged-out user" do
      expect { reset_stamps }.not_to change(SponsorVisit, :count)

      expect(response).to redirect_to(root_path)
    end

    context "when the event ID is missing" do
      let(:request_params) { {} }

      before { sign_in(organizer) }

      it "does not delete stamps and returns not found" do
        expect { reset_stamps }.not_to change(SponsorVisit, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
