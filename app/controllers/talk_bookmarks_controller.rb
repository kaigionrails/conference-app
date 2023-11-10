class TalkBookmarksController < ApplicationController
  def create
    unless logged_in?
      head :unauthorized
      return
    end

    talk_bookmark = TalkBookmark.create!(user: current_user!, **talk_bookmark_params)
    talk = talk_bookmark.talk
    TalkReminder.create_or_find_by!(user: current_user!, talk: talk, scheduled_at: (talk.start_at - 3.minutes))
    render json: talk_bookmark, status: :ok
  end

  def destroy
    unless logged_in?
      render status: :unauthorized
      return
    end

    talk_bookmark = current_user!.talk_bookmarks.find_by(id: params[:id])
    talk = talk_bookmark&.talk
    if talk_bookmark&.destroy
      current_user!.talk_reminders.find_by(talk: talk)&.destroy
      head :ok
    else
      head :internal_server_error
    end
  end

  private def talk_bookmark_params
    params.require(:talk_bookmark).permit(:talk_id)
  end
end
