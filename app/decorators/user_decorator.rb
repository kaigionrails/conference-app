# frozen_string_literal: true

# @rbs module-self User
module UserDecorator
  # @rbs return: String
  def number_of_friends(event = nil)
    if event
      c = profile_exchanges.where(event_id: event.id).count
      c.zero? ? "" : "(#{c}人)"
    else
      friends.present? ? "(#{friends.size}人)" : ""
    end
  end
end
