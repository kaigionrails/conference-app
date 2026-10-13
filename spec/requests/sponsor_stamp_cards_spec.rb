require "rails_helper"

RSpec.describe "Sponsor stamp cards", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, slug: "2026") }
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:other_event) { FactoryBot.create(:event) }
  let(:primary_sponsor) { sponsors.first }
  let(:last_sponsor) { {key: "last.example", name: "Last", plan: "gold", booth: true} }
  let(:sponsors) { [{key: "sponsor.example", name: "Example Sponsor", plan: "ruby", logo: "example-sponsor", booth: true}] }
  let(:stamp_code) { SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: primary_sponsor[:key]) }
  let(:other_event_code) { SponsorVisitToken.generate(event_slug: other_event.slug, sponsor_key: primary_sponsor[:key]) }
  let(:non_booth_code) { SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: "non-booth.example") }
  let(:visit) { FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: primary_sponsor[:key]) }
  let(:collected_visit) { user.sponsor_visits.find_by!(event:, sponsor_key: primary_sponsor[:key]) }

  before { allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return(sponsors) }

  describe "completion collection" do
    let(:collection_params) { {code: stamp_code} }

    subject(:collect_stamp) { post sponsor_stamp_card_stamps_path(event.slug), params: collection_params }

    before { sign_in(user) }

    it "saves completion on the final visit" do
      expect { collect_stamp }.to change(SponsorStampRallyCompletion, :count).by(1)
      expect(user.sponsor_stamp_rally_completions.sole).to have_attributes(event:, completed_at: collected_visit.created_at)
    end

    it "passes the visit ID and collection outcome through flash" do
      collect_stamp
      expect(flash[:stamp_collection]).to eq(visit_id: collected_visit.id, newly_visited: true, newly_completed: true)
    end

    context "with an unvisited final booth" do
      let(:sponsors) { super() + [last_sponsor] }

      it "does not award completion on an intermediate visit" do
        expect { collect_stamp }.not_to change(SponsorStampRallyCompletion, :count)
        expect(flash[:stamp_collection]).to eq(visit_id: collected_visit.id, newly_visited: true, newly_completed: false)
      end
    end

    context "with an existing completion" do
      let!(:existing_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user:, event:, completed_at: visit.created_at) }

      it "does not report a new visit or completion on a repeat scan" do
        collect_stamp
        expect(response).to redirect_to(sponsor_stamp_card_stamp_path(event.slug, visit))
        expect(flash[:stamp_collection]).to eq(visit_id: visit.id, newly_visited: false, newly_completed: false)
      end
    end

    context "with supplied user and event IDs" do
      let(:collection_params) { {code: stamp_code, user_id: other_user.id, event_id: other_event.id} }

      it "does not trust the supplied IDs" do
        collect_stamp
        expect(SponsorStampRallyCompletion.sole).to have_attributes(user:, event:)
      end
    end
  end

  describe "GET /sponsor_stamp_cards/:event_slug" do
    context "when logged in" do
      before { sign_in(user) }

      it "returns success without visits" do
        get sponsor_stamp_card_path(event_slug: event.slug)
        expect(response).to have_http_status(:success)
      end

      context "with visits" do
        before { visit }

        it "returns success without awarding completion" do
          expect { get sponsor_stamp_card_path(event_slug: event.slug) }.not_to change(SponsorStampRallyCompletion, :count)
          expect(response).to have_http_status(:success)
        end
      end

      it "returns not found for a past event" do
        get sponsor_stamp_card_path(event_slug: other_event.slug)
        expect(response).to have_http_status(:not_found)
      end
    end

    it "redirects a logged-out user to login" do
      get sponsor_stamp_card_path(event_slug: event.slug)
      expect(response).to redirect_to(login_path(return_to: sponsor_stamp_card_path(event_slug: event.slug)))
    end
  end

  describe "GET /sponsor_stamp_cards/:event_slug/stamps/new" do
    let(:confirmation_path) { new_sponsor_stamp_card_stamp_path(event.slug, code: stamp_code) }

    context "when logged in" do
      before { sign_in(user) }

      it "returns not found for a past event" do
        get new_sponsor_stamp_card_stamp_path(other_event.slug, code: other_event_code)
        expect(response).to have_http_status(:not_found)
      end

      it "does not record a visit on GET" do
        expect { get confirmation_path }.not_to change(SponsorVisit, :count)
        expect(response).to have_http_status(:success)
      end

      context "with an existing visit" do
        before { visit }

        it "redirects to its result without recording a visit" do
          expect { get confirmation_path }.not_to change(SponsorVisit, :count)
          expect(response).to redirect_to(sponsor_stamp_card_stamp_path(event.slug, visit))
        end
      end
    end

    it "redirects a logged-out user to login" do
      get confirmation_path
      expect(response).to redirect_to(login_path(return_to: confirmation_path))
      expect(SponsorVisit).not_to exist
    end
  end

  describe "POST /sponsor_stamp_cards/:event_slug/stamps" do
    context "when logged in" do
      before { sign_in(user) }

      it "does not record a visit for a past event" do
        expect {
          post sponsor_stamp_card_stamps_path(other_event.slug), params: {code: other_event_code}
        }.not_to change(SponsorVisit, :count)
        expect(response).to have_http_status(:not_found)
      end

      it "records a visit and redirects to the result" do
        expect {
          post sponsor_stamp_card_stamps_path(event.slug), params: {code: stamp_code}, headers: {"Accept" => "text/vnd.turbo-stream.html, text/html"}
        }.to change(SponsorVisit, :count).by(1)
        expect(collected_visit).to have_attributes(user:, event:, sponsor_key: primary_sponsor[:key])
        expect(response).to redirect_to(sponsor_stamp_card_stamp_path(event.slug, collected_visit))
        expect(response.location).not_to include(stamp_code)
        expect(response).to have_http_status(:see_other)
      end

      context "with an existing visit" do
        before { visit }

        it "does not duplicate the visit" do
          expect {
            post sponsor_stamp_card_stamps_path(event.slug), params: {code: stamp_code}
          }.not_to change(SponsorVisit, :count)
          expect(response).to redirect_to(sponsor_stamp_card_stamp_path(event.slug, visit))
          expect(response).to have_http_status(:see_other)
        end
      end

      it "returns not found for an unknown code" do
        expect {
          post sponsor_stamp_card_stamps_path(event.slug), params: {code: "x" * SponsorVisitToken::TOKEN_LENGTH}
        }.not_to change(SponsorVisit, :count)
        expect(response).to have_http_status(:not_found)
      end

      it "does not record a visit for a sponsor without a booth" do
        expect {
          post sponsor_stamp_card_stamps_path(event.slug), params: {code: non_booth_code}
        }.not_to change(SponsorVisit, :count)
        expect(response).to have_http_status(:not_found)
      end

      it "does not accept a code generated for another event" do
        expect {
          post sponsor_stamp_card_stamps_path(event.slug), params: {code: other_event_code}
        }.not_to change(SponsorVisit, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    it "redirects a logged-out user to login" do
      post sponsor_stamp_card_stamps_path(event.slug), params: {code: stamp_code}
      expect(response).to redirect_to(login_path)
      expect(SponsorVisit).not_to exist
    end

    it "does not expose the old sponsor-key URL" do
      expect {
        Rails.application.routes.recognize_path("/sponsors/sponsor.example/visit", method: :get)
      }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "GET /sponsor_stamp_cards/:event_slug/stamps/:id" do
    before { sign_in(user) }

    context "with the user's visit" do
      before { visit }

      it "returns success without awarding completion" do
        expect { get sponsor_stamp_card_stamp_path(event.slug, visit) }.not_to change(SponsorStampRallyCompletion, :count)
        expect(response).to have_http_status(:success)
      end
    end

    context "with another user's visit" do
      let!(:visit) { FactoryBot.create(:sponsor_visit, user: other_user, event:, sponsor_key: primary_sponsor[:key]) }

      it "returns not found" do
        get sponsor_stamp_card_stamp_path(event.slug, visit)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a visit from another event" do
      let!(:visit) { FactoryBot.create(:sponsor_visit, user:, event: other_event, sponsor_key: primary_sponsor[:key]) }

      it "returns not found" do
        get sponsor_stamp_card_stamp_path(event.slug, visit)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with collection flash" do
      before { post sponsor_stamp_card_stamps_path(event.slug), params: {code: stamp_code} }

      it "consumes the flash on the result request" do
        get sponsor_stamp_card_stamp_path(event.slug, collected_visit)
        expect(response).to have_http_status(:success)
        expect(flash[:stamp_collection]).to be_nil
      end
    end
  end
end
