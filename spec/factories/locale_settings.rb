FactoryBot.define do
  factory :locale_setting do
    user
    preferred_locale { "ja" }
  end
end
