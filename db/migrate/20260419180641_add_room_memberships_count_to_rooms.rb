class AddRoomMembershipsCountToRooms < ActiveRecord::Migration[7.2]
  def change
    add_column :rooms, :room_memberships_count, :integer, default: 0, null: false
    Room.find_each { |room| Room.reset_counters(room.id, :room_memberships) }
  end
end
