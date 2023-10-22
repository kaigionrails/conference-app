class WebpushSubscriptionController < ApplicationController
  def create
    WebpushSubscription.create!(
      user: current_user,
      endpoint: subscription_params[:endpoint],
      auth_key: subscription_params[:keys][:auth],
      p256dh_key: subscription_params[:keys][:p256dh],
    )
  end

  private def subscription_params
    params.require(:subscription).permit(:endpoint, keys: [:auth, :p256dh])
  end
end
