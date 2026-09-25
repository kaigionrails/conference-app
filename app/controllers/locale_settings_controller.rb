class LocaleSettingsController < ApplicationController
  # @rbs return: void
  def update
    uri = URI.parse(safe_return_to(params[:return_to], default: root_path))
    query = URI.decode_www_form(uri.query.to_s).delete_if { |key, _value| key == "locale" }
    query << ["locale", params[:locale].to_s]
    uri.query = URI.encode_www_form(query)

    if logged_in?
      locale_setting = LocaleSetting.find_or_initialize_by(user: current_user!)
      locale_setting.preferred_locale = params[:locale]
      locale_setting.save! if locale_setting.changed?
    end

    redirect_to uri.to_s
  end
end
