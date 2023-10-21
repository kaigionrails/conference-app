class TalkBookmarksController < ApplicationController
  def create
    unless logged_in?
      render status: :unauthorized
      return
    end

    TalkBookmark.create!(user: current_user, **talk_bookmark_params)
  end

  def destroy
    unless logged_in?
      render status: :unauthorized
      return
    end

    talk_bookmark = TalkBookmark.find_by(id: params[:id])
  end

  private def talk_bookmark_params
    params.require(:talk_bookmark).permit(:talk_id)
  end
end
