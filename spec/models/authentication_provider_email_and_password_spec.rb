require "rails_helper"

RSpec.describe AuthenticationProviderEmailAndPassword, type: :model do
  let(:user) { FactoryBot.create(:user) }

  def build(email)
    FactoryBot.build(
      :authentication_provider_email_and_password,
      user: user, email: email, password: "password", password_confirmation: "password"
    )
  end

  it "rejects a blank email" do
    expect(build("")).not_to be_valid
  end

  # Without this the duplicate only surfaces as RecordNotUnique from the
  # index, which the admin screen can only report as a bare failure.
  it "rejects an email that is already registered" do
    FactoryBot.create(
      :authentication_provider_email_and_password,
      user: FactoryBot.create(:user), email: "taken@example.invalid",
      password: "password", password_confirmation: "password"
    )

    duplicate = build("taken@example.invalid")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors).to be_of_kind(:email, :taken)
  end
end
