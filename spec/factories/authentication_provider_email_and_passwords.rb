FactoryBot.define do
  factory :authentication_provider_email_and_password do
    user { user }
    sequence(:email) { "test-#{n}@example.invalid" }
    password_digest { "$2a$12$oe5xxIyc9rviB4fofkJztOxFFz7925l3ubjDu2WuYcYKwo1AeN0Ju" } # BCrypt::Password.create("password")
  end
end
