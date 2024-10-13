# frozen_string_literal: true

module UserDecorator
  def number_of_friends(event = nil)
    if event
      c = profile_exchanges.where(event_id: event.id).count
      c.zero? ? "" : "(#{c}人)"
    else
      friends.present? ? "(#{friends.size}人)" : ""
    end
  end
end
