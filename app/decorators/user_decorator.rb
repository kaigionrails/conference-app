# frozen_string_literal: true

# @rbs module-self User
module UserDecorator
  # @rbs return: Integer
  def number_of_friends(event = nil)
    if event
      profile_exchanges.where(event_id: event.id).count
    else
      friends.present? ? friends.size : 0
    end
  end
end
