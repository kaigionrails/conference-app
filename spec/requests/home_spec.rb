require 'rails_helper'

RSpec.describe "Homes", type: :request do
  before { prepare_current_event }
  describe "GET /index" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

end
