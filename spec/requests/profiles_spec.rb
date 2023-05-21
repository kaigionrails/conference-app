require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/profiles/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/profiles/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/profiles/create"
      expect(response).to have_http_status(:success)
    end
  end

end
