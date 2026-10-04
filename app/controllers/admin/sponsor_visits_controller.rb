class Admin::SponsorVisitsController < AdminController
  def destroy
    user = User.organizer.find(params[:user_id])
    event = Event.find(params[:event_id])
    user.sponsor_visits.where(event: event).destroy_all

    flash[:success] = "Reset succeeded for #{event.name}."
    redirect_to admin_user_path(user), status: :see_other
  end
end
