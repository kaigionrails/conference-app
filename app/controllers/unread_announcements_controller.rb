class UnreadAnnouncementsController < ApplicationController
  # @rbs return: void
  def destroy
    unless logged_in?
      head :unauthorized
      return
    end

    UnreadAnnouncement.find_by!(user: current_user!, id: params[:id]).destroy!
    head :ok
  end
end
