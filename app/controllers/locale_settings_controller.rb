class LocaleSettingsController < ApplicationController
  # @rbs return: void
  def update
    path = safe_return_to_path(params[:return_to], default: root_path)

    if logged_in?
      locale_setting = LocaleSetting.find_or_initialize_by(user: current_user!)
      locale_setting.preferred_locale = params[:locale]
      locale_setting.save! if locale_setting.changed?
    end

    redirect_to "#{path}?locale=#{CGI.escape(params[:locale].to_s)}"
  end
end
