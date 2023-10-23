class TalkBookmarksController < ApplicationController
  def create
    unless logged_in?
      head :unauthorized
      return
    end

    talk_bookmark = TalkBookmark.create!(user: current_user, **talk_bookmark_params)
    render json: talk_bookmark, status: :ok
  end

  def destroy
    unless logged_in?
      render status: :unauthorized
      return
    end

    talk_bookmark = TalkBookmark.find_by(id: params[:id])
    if talk_bookmark&.destroy
      head :ok
    else
      head :internal_server_error
    end
  end

  private def talk_bookmark_params
    params.require(:talk_bookmark).permit(:talk_id)
  end
end
