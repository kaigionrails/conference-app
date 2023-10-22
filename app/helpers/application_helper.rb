module ApplicationHelper
  def vapid_public_key_bytes
    @vapid_public_key_bytes ||= Base64.urlsafe_decode64(Rails.configuration.x.webpush.vapid_public_key).bytes
  end
end
