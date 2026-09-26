class Admin::SponsorBoothQrCardTemplatesController < AdminController
  # Creates the template of the ongoing event on the first upload and replaces its image afterwards.
  # @rbs return: void
  def update
    template = SponsorBoothQrCardTemplate.find_or_initialize_by(event: OngoingEvent.first!.event)
    # Assign even when no file was sent, so that the presence validation reports it instead of a 400
    # and an existing template is not saved unchanged as if it had been uploaded.
    template.image = template_params[:image]
    if template.save
      flash[:success] = "Booth QR card template uploaded"
    else
      flash[:alert] = template.errors.full_messages.join(", ")
    end
    redirect_to admin_sponsor_qr_codes_path
  end

  private def template_params
    no_params = {} #: Hash[Symbol, untyped]
    params.fetch(:sponsor_booth_qr_card_template, no_params).permit(:image)
  end
end
