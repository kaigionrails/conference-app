require "rails_helper"

RSpec.describe ProfileExchange, type: :model do
  let(:event) { FactoryBot.create(:event) }
  let(:user) { FactoryBot.create(:user) }
  let(:friend) { FactoryBot.create(:user) }

  it "cannot be stored twice for the same event, user and friend" do
    ProfileExchange.create!(event:, user:, friend:)

    expect { ProfileExchange.create!(event:, user:, friend:) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
