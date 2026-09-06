require "rails_helper"

RSpec.describe SocialAnnouncementMedia, type: :model do
  let(:announcement) { FactoryBot.create(:social_announcement) }

  def build_with(content_type:, byte_size: 100)
    medium = FactoryBot.build(:social_announcement_media, social_announcement: announcement)
    medium.file.attach(io: StringIO.new("x" * byte_size), filename: "f", content_type: content_type)
    medium
  end

  it "allows up to 4 media per announcement" do
    4.times { |i| FactoryBot.create(:social_announcement_media, social_announcement: announcement, position: i) }
    fifth = FactoryBot.build(:social_announcement_media, social_announcement: announcement)
    expect(fifth).not_to be_valid
    expect(fifth.errors[:base].first).to match(/max 4/)
  end

  it "accepts jpeg/png/webp/gif" do
    %w[image/jpeg image/png image/webp image/gif].each do |ct|
      expect(build_with(content_type: ct)).to be_valid
    end
  end

  it "rejects video" do
    medium = build_with(content_type: "video/mp4")
    expect(medium).not_to be_valid
    expect(medium.errors[:file].first).to match(/not allowed/)
  end

  it "rejects files over 2MB" do
    medium = build_with(content_type: "image/png", byte_size: 2.megabytes + 1)
    expect(medium).not_to be_valid
    expect(medium.errors[:file].first).to match(/2MB/)
  end

  it "requires a file" do
    medium = described_class.new(social_announcement: announcement)
    expect(medium).not_to be_valid
  end

  it "changes the announcement media digest when either locale's alt text changes" do
    medium = FactoryBot.create(:social_announcement_media, social_announcement: announcement, alt_text_ja: "a", alt_text_en: "a")
    before = announcement.current_media_digest
    medium.update!(alt_text_ja: "b")
    middle = announcement.reload.current_media_digest
    expect(middle).not_to eq(before)
    medium.update!(alt_text_en: "b")
    expect(announcement.reload.current_media_digest).not_to eq(middle)
  end

  it "returns the alt text for the given locale" do
    medium = FactoryBot.build(:social_announcement_media, alt_text_ja: "説明", alt_text_en: nil)
    expect(medium.alt_text_for("ja")).to eq("説明")
    expect(medium.alt_text_for("en")).to eq("")
    expect { medium.alt_text_for("fr") }.to raise_error(ArgumentError)
  end

  it "changes the digest when order changes" do
    m1 = FactoryBot.create(:social_announcement_media, social_announcement: announcement, position: 0)
    FactoryBot.create(:social_announcement_media, social_announcement: announcement, position: 1)
    before = announcement.current_media_digest
    m1.update!(position: 5)
    expect(announcement.reload.current_media_digest).not_to eq(before)
  end
end
