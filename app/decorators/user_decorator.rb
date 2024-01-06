# frozen_string_literal: true

module UserDecorator
  def number_of_friends
    friends.present? ? "(#{friends.size}人)" : ""
  end
end
