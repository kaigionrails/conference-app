module ApplicationHelper
  def vapid_public_key_bytes
    @vapid_public_key_bytes ||= Base64.urlsafe_decode64(Rails.configuration.x.webpush.vapid_public_key).bytes
  end

  def current_event
    @current_event ||= Event.find_by(slug: Event::ONGOING_EVENT_SLUG)
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
      "bg-[#d4edda]"
    when "alert"
      "bg-[#f8d7da]"
    else
      ""
    end
  end
end
