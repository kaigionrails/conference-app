require 'rails_helper'

RSpec.describe "WebpushSubscriptions", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/webpush_subscription/create"
      expect(response).to have_http_status(:success)
    end
  end

end
