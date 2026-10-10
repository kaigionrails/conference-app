# The YOYO Translate (subtitle service) pages linked from the live stream page, one per hall.
# One per event; organizers set them from the admin Live page.
class YoyoTranslateSetting < ApplicationRecord
  belongs_to :event

  normalizes :magenta_hall_url, :lime_hall_url, with: ->(url) { url.strip.presence }

  validates :event_id, uniqueness: true
  # The URLs go into an href on the live stream page, so only https is allowed.
  validates :magenta_hall_url, :lime_hall_url, format: {with: %r{\Ahttps://\S+\z}}, allow_nil: true
end
