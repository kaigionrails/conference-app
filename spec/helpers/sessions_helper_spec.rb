require "rails_helper"

RSpec.describe SessionsHelper, type: :helper do
  describe "#omniauth_request_path" do
    %i[github google_oauth2].each do |provider|
      context "with #{provider}" do
        it "preserves the return path and query as one parameter" do
          return_to = "/sponsor_passports/2026/stamps/new?code=stamp-code&locale=en"

          uri = URI.parse(helper.omniauth_request_path(provider, return_to:))

          expect(uri.path).to eq("/auth/#{provider}")
          expect(Rack::Utils.parse_query(uri.query)).to eq("return_to" => return_to)
        end

        it "omits a blank return location" do
          expect(helper.omniauth_request_path(provider, return_to: nil)).to eq("/auth/#{provider}")
          expect(helper.omniauth_request_path(provider, return_to: "")).to eq("/auth/#{provider}")
        end
      end
    end
  end
end
