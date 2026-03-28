class AddRoomTypeToRooms < ActiveRecord::Migration[7.2]
  def change
    add_column :rooms, :room_type, :integer, null: false, default: 0
  end
end
