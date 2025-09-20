class TitoTicket < ApplicationRecord
  belongs_to :event
  belongs_to :user, optional: true
end
