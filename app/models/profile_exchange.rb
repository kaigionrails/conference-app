class ProfileExchange < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :friend, class_name: "User"
end
