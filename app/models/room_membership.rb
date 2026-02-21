class RoomMembership < ApplicationRecord
  belongs_to :room
  belongs_to :profile

  validates :profile_id, uniqueness: { scope: :room_id }
end
