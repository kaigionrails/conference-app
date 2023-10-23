module ApplicationHelper
  def vapid_public_key_bytes
    @vapid_public_key_bytes ||= Base64.urlsafe_decode64(Rails.configuration.x.webpush.vapid_public_key).bytes
  end

  def current_event
    @current_event ||= Event.find_by(slug: Event::ONGOING_EVENT_SLUG)
  end
end
