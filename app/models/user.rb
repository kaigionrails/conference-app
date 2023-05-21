class User < ApplicationRecord
  enum :role, [:organizer, :participant]
end
