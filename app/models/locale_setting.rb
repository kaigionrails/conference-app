class LocaleSetting < ApplicationRecord
  belongs_to :user

  enum :preferred_locale, en: "en", ja: "ja"
end
