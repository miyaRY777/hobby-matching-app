class AddLockedIndexToRooms < ActiveRecord::Migration[7.2]
  def change
    add_index :rooms, :locked
  end
end
