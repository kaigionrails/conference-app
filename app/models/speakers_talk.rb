class SpeakersTalk < ApplicationRecord
  belongs_to :speaker
  belongs_to :talk
end
