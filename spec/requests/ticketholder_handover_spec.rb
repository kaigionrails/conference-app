require "rails_helper"

# Checking in before logging in leaves the ticket in the session. Logging in
# calls reset_session, which used to drop it and bounce the viewer back to
# check-in.
RSpec.describe "Ticketholder handover", type: :request do
  let!(:event) { FactoryBot.create(:event, slug: "2025", end_date: 1.minute.since) }
  let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }
  let(:user) { FactoryBot.create(:user) }

  def check_in!(ticket)
    post "/2025/live/checkin", params: {tito_ticket_reference: ticket.reference}
  end

  context "when the ticket is still unclaimed" do
    let!(:ticket) { FactoryBot.create(:tito_ticket, event: event, user: nil, reference: "ABCD-1") }

    it "carries the ticket across login and claims it for the user" do
      check_in!(ticket)
      expect(session[:ticketholder]).to eq ticket.id

      sign_in_through_github(user)

      expect(session[:user_id]).to eq user.id
      expect(session[:ticketholder]).to eq ticket.id
      expect(ticket.reload.user).to eq user
    end

    it "keeps access to the stream after logging in" do
      check_in!(ticket)
      sign_in_through_github(user)

      get "/2025/live"
      expect(response).to have_http_status(:success)
    end
  end

  context "when someone else claimed the ticket between check-in and login" do
    let!(:ticket) { FactoryBot.create(:tito_ticket, event: event, user: nil, reference: "ABCD-2") }
    let(:other) { FactoryBot.create(:user) }

    it "leaves the ticket alone but keeps the session entry" do
      check_in!(ticket)
      ticket.update!(user: other)

      sign_in_through_github(user)

      expect(ticket.reload.user).to eq other
      expect(session[:ticketholder]).to eq ticket.id
    end
  end

  # A session entry only proved that some ticket with that id existed, so a
  # ticket for another event, or one that never completed, let its holder in.
  context "when the ticket in the session stops qualifying" do
    let!(:other_event) { FactoryBot.create(:event, slug: "2024", end_date: 1.minute.since) }
    let!(:ticket) { FactoryBot.create(:tito_ticket, event: event, user: nil, reference: "ABCD-3") }

    before do
      check_in!(ticket)
      # Guards against the rest of the example passing because check-in itself
      # failed and left no session entry.
      expect(session[:ticketholder]).to eq ticket.id
    end

    it "turns it away once it belongs to another event" do
      ticket.update!(event: other_event)

      get "/2025/live"
      expect(response).to redirect_to("/2025/live/checkin")
    end

    it "turns it away once it is no longer complete" do
      ticket.update!(state: "reminder")

      get "/2025/live"
      expect(response).to redirect_to("/2025/live/checkin")
    end
  end

  context "when checking in with a ticket that never completed" do
    let!(:ticket) { FactoryBot.create(:tito_ticket, event: event, user: nil, reference: "ABCD-4", state: "reminder") }

    it "refuses the check-in rather than letting it fail later at the stream" do
      check_in!(ticket)

      expect(session[:ticketholder]).to be_nil
      expect(response).to redirect_to("/2025/live/checkin")
    end
  end

  context "when the user logs in without checking in" do
    it "sets no ticketholder" do
      sign_in_through_github(user)

      expect(session[:user_id]).to eq user.id
      expect(session[:ticketholder]).to be_nil
    end
  end
end
