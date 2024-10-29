class OngoingEvent < ApplicationRecord
  belongs_to :event

  # @rbs!
  #   def self.count: -> Integer
  #   def self.first: -> OngoingEvent
  #                 | ...

  # OngoingEvent record should be at most one
  before_create do
    throw(:abort) if OngoingEvent.exists?
  end

  before_destroy do
    throw(:abort) if OngoingEvent.count == 1
  end
end
