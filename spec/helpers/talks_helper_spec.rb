require "rails_helper"

RSpec.describe TalksHelper, type: :helper do
  describe "#time_with_zone_to_anchor" do
    it "converts a TimeWithZone object to an anchor string" do
      expect(helper.time_with_zone_to_anchor(Time.zone.parse("2023-10-27 12:34:56 JST +09:00"))).to eq("1027-1234")
    end
  end
end
