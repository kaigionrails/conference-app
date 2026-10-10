class Admin::SpeakersController < AdminController
  # @rbs @talk: Talk
  # @rbs @speaker: Speaker

  # @rbs return: void
  def edit
    @talk = Talk.find(params[:talk_id])
    @speaker = @talk.speakers.find(params[:id])
  end

  # @rbs return: void
  def update
    @talk = Talk.find(params[:talk_id])
    @speaker = @talk.speakers.find(params[:id])
    if @speaker.update(**speaker_params)
      flash[:success] = "Update succeeded"
      redirect_to admin_talk_path(@talk)
    else
      flash.now[:alert] = "Update failed"
      # Turbo Drive renders a response to a form submission only when it is an error.
      render :edit, status: :unprocessable_content
    end
  end

  private def speaker_params
    params.require(:speaker).permit(:name, :github_username, :gravatar_hash, :bio)
  end
end
