require "rails_helper"

RSpec.describe Speaker, type: :model do
  it "is valid as the factory builds it" do
    expect(FactoryBot.build(:speaker)).to be_valid
  end

  it "rejects a blank name" do
    speaker = FactoryBot.build(:speaker, name: "")

    expect(speaker).not_to be_valid
    expect(speaker.errors).to be_of_kind(:name, :blank)
  end

  it "rejects a blank github_username" do
    speaker = FactoryBot.build(:speaker, github_username: "")

    expect(speaker).not_to be_valid
    expect(speaker.errors).to be_of_kind(:github_username, :blank)
  end
end
