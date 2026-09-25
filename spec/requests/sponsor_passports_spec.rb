require "rails_helper"

RSpec.describe "Sponsor passports", type: :request do
  let!(:event) do
    FactoryBot.create(
      :event,
      :make_ongoing,
      name: "Kaigi on Rails 2026",
      slug: "2026"
    )
  end
  let(:user) { FactoryBot.create(:user) }
  let(:primary_sponsor) { sponsors.first }
  let(:non_booth_sponsor_key) { "non-booth-sponsor.example" }
  let(:sponsors) do
    [
      {key: "sponsor.example", name: "Example Sponsor", plan: "ruby", logo: "example-sponsor", booth: true}
    ]
  end
  let(:stamp_code) { SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: primary_sponsor[:key]) }

  before do
    allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return(sponsors)
  end

  describe "GET /sponsor_passports/:event_slug" do
    it "returns success for a logged-in user with visits" do
      sign_in(user)
      FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: primary_sponsor[:key])

      get sponsor_passport_path(event_slug: event.slug)

      expect(response).to have_http_status(:success)
    end

    it "returns success for a logged-in user without visits" do
      sign_in(user)

      get sponsor_passport_path(event_slug: event.slug)

      expect(response).to have_http_status(:success)
    end

    it "returns not found for a past event" do
      past_event = FactoryBot.create(:event, name: "Kaigi on Rails 2025", slug: "2025")
      sign_in(user)

      get sponsor_passport_path(event_slug: past_event.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "redirects a logged-out user to login" do
      get sponsor_passport_path(event_slug: event.slug)

      expect(response).to redirect_to(login_path(return_to: sponsor_passport_path(event_slug: event.slug)))
    end
  end

  describe "GET /sponsor_passports/:event_slug/stamps/new" do
    it "returns not found for a past event" do
      past_event = FactoryBot.create(:event, slug: "2025")
      code = SponsorVisitToken.generate(event_slug: past_event.slug, sponsor_key: primary_sponsor[:key])
      sign_in(user)

      get new_sponsor_passport_stamp_path(past_event.slug, code: code)

      expect(response).to have_http_status(:not_found)
    end

    it "shows a confirmation without recording a visit" do
      sign_in(user)

      expect {
        get new_sponsor_passport_stamp_path(event.slug, code: stamp_code)
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:success)
    end

    it "redirects an existing visit to its result" do
      sign_in(user)
      visit = FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: primary_sponsor[:key])

      expect {
        get new_sponsor_passport_stamp_path(event.slug, code: stamp_code)
      }.not_to change(SponsorVisit, :count)

      expect(response).to redirect_to(sponsor_passport_stamp_path(event.slug, visit))
    end

    it "redirects a logged-out user to login" do
      stamp_path = new_sponsor_passport_stamp_path(event.slug, code: stamp_code)

      get stamp_path

      expect(response).to redirect_to(login_path(return_to: stamp_path))
      expect(SponsorVisit).not_to exist
    end
  end

  describe "POST /sponsor_passports/:event_slug/stamps" do
    it "does not record a visit for a past event" do
      past_event = FactoryBot.create(:event, slug: "2025")
      code = SponsorVisitToken.generate(event_slug: past_event.slug, sponsor_key: primary_sponsor[:key])
      sign_in(user)

      expect {
        post sponsor_passport_stamps_path(past_event.slug), params: {code: code}
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "records a visit for a logged-in user" do
      sign_in(user)

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}, headers: {"Accept" => "text/vnd.turbo-stream.html, text/html"}
      }.to change(SponsorVisit, :count).by(1)

      expect(SponsorVisit.last).to have_attributes(
        user: user,
        event: event,
        sponsor_key: primary_sponsor[:key]
      )
      visit = SponsorVisit.last
      expect(response).to redirect_to(sponsor_passport_stamp_path(event.slug, visit))
      expect(response.location).not_to include(stamp_code)
      expect(response).to have_http_status(:see_other)
    end

    it "does not duplicate an existing visit" do
      sign_in(user)

      post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}
      }.not_to change(SponsorVisit, :count)

      expect(response).to redirect_to(sponsor_passport_stamp_path(event.slug, SponsorVisit.last))
      expect(response).to have_http_status(:see_other)
    end

    it "returns not found for an unknown sponsor" do
      sign_in(user)

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: "x" * SponsorVisitToken::TOKEN_LENGTH}
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not record a visit for a sponsor without a booth" do
      sign_in(user)
      code = SponsorVisitToken.generate(event_slug: event.slug, sponsor_key: non_booth_sponsor_key)

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: code}
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "redirects a logged-out user to login" do
      post sponsor_passport_stamps_path(event.slug), params: {code: stamp_code}

      expect(response).to redirect_to(login_path)
      expect(SponsorVisit).not_to exist
    end

    it "does not accept a code generated for another event" do
      sign_in(user)
      other_event_code = SponsorVisitToken.generate(event_slug: "2025", sponsor_key: primary_sponsor[:key])

      expect {
        post sponsor_passport_stamps_path(event.slug), params: {code: other_event_code}
      }.not_to change(SponsorVisit, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not expose the old sponsor-key URL" do
      expect {
        Rails.application.routes.recognize_path("/sponsors/sponsor.example/visit", method: :get)
      }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "GET /sponsor_passports/:event_slug/stamps/:id" do
    it "returns success for the user's visit" do
      sign_in(user)
      visit = FactoryBot.create(:sponsor_visit, user: user, event: event, sponsor_key: primary_sponsor[:key])

      get sponsor_passport_stamp_path(event.slug, visit)

      expect(response).to have_http_status(:success)
    end

    it "does not show another user's visit" do
      sign_in(user)
      another_users_visit = FactoryBot.create(
        :sponsor_visit,
        user: FactoryBot.create(:user),
        event: event,
        sponsor_key: primary_sponsor[:key]
      )

      get sponsor_passport_stamp_path(event.slug, another_users_visit)

      expect(response).to have_http_status(:not_found)
    end

    it "does not show the user's visit from another event" do
      sign_in(user)
      other_event = FactoryBot.create(:event, name: "Kaigi on Rails 2025", slug: "2025")
      visit = FactoryBot.create(:sponsor_visit, user: user, event: other_event, sponsor_key: primary_sponsor[:key])

      get sponsor_passport_stamp_path(event.slug, visit)

      expect(response).to have_http_status(:not_found)
    end
  end
end
