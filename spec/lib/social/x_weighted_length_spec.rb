require "rails_helper"

RSpec.describe Social::XWeightedLength do
  def length(text) = described_class.new(text).to_i

  it "counts basic latin as 1" do
    expect(length("a" * 280)).to eq(280)
    expect(described_class.new("a" * 280)).to be_valid
    expect(described_class.new("a" * 281)).not_to be_valid
  end

  it "counts Japanese as 2 (140 chars = 280)" do
    expect(length("あ" * 140)).to eq(280)
    expect(described_class.new("あ" * 140)).to be_valid
    expect(described_class.new("あ" * 141)).not_to be_valid
  end

  it "counts URL as 23 regardless of its length" do
    expect(length("https://example.com/" + "a" * 100)).to eq(23)
    expect(length("see https://x.com")).to eq(4 + 23)
    expect(length("www.example.com")).to eq(23)
  end

  it "counts emoji as 2 including ZWJ sequences" do
    expect(length("😀")).to eq(2)
    expect(length("👨‍👩‍👧")).to eq(2)
    expect(length("a😀")).to eq(3)
  end

  it "treats nil as empty" do
    expect(length(nil)).to eq(0)
  end
end
