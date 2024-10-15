class TalkBookmarksController < ApplicationController
  def create
    unless logged_in?
      head :unauthorized
      return
    end

    talk_bookmark = TalkBookmark.find_or_create_by!(user: current_user!, **talk_bookmark_params)
    talk = talk_bookmark.talk
    TalkReminder.create_or_find_by!(user: current_user!, talk: talk, scheduled_at: (talk.start_at - 3.minutes))
    render json: talk_bookmark, status: :ok
  end

  def destroy
    unless logged_in?
      render status: :unauthorized
      return
    end

    current_user!.destroy_talk_bookmark_with_reminder!(params[:id])
    head :ok
  end

  private def talk_bookmark_params
    params.require(:talk_bookmark).permit(:talk_id)
  end
end
