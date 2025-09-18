module ApplicationHelper
  # @rbs @vapid_public_key_bytes: Array[Integer]
  # @rbs @current_event: Event?

  def vapid_public_key_bytes
    @vapid_public_key_bytes ||= Base64.urlsafe_decode64(Rails.configuration.x.webpush.vapid_public_key).bytes
  end

  def current_event
    @current_event ||= (OngoingEvent.exists? ? OngoingEvent.first.event : Event.find_by(slug: Event::ONGOING_EVENT_SLUG))
  end

  def application_url
    Rails.configuration.application_url
  end

  def page_title(title = "")
    base_title = "ConferenceApp"
    title.empty? ? base_title : "#{base_title} - #{title}"
  end

  def message_type_style(message_type)
    case message_type
    when "success"
      "bg-theme-success"
    when "alert"
      "bg-theme-alert"
    else
      ""
    end
  end
end
