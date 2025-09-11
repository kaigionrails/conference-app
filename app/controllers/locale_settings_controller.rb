class LocaleSettingsController < ApplicationController
  def update
    uri = URI.parse(params[:return_to])
    uri.host = nil # Prevent open redirect
    uri.query = "locale=#{params[:locale]}"

    if logged_in?
      locale_setting = LocaleSetting.find_or_initialize_by(user: current_user!)
      locale_setting.preferred_locale = params[:locale]
      locale_setting.save! if locale_setting.changed?
    end

    redirect_to uri.to_s
  end
end
