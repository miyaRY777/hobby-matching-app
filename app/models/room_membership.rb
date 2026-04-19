class RoomMembership < ApplicationRecord
  belongs_to :room, counter_cache: true
  belongs_to :profile

  validates :profile_id, uniqueness: { scope: :room_id }
end
