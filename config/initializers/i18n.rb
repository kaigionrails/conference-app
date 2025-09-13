# frozen_string_literal: true

# See also https://github.com/fnando/i18n-js?tab=readme-ov-file#using-listen
Rails.application.config.after_initialize do
  if Rails.env.local?
    require "i18n-js/listen"
    I18nJS.listen
  end
end
