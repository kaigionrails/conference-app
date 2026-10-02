require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "image variants" do
    let(:image) { FactoryBot.create(:profile, :with_image).images.first }

    # The header asked for these transformations inline before :icon existed.
    # A different key would orphan every icon generated so far.
    it "keeps the key of the header icon generated before :icon was named" do
      expect(image.variant(:icon).variation.key).to eq(image.variant(resize_to_limit: [50, 50]).variation.key)
    end
  end
end
