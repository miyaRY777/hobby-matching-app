class AddLockedToRooms < ActiveRecord::Migration[7.2]
  def change
    add_column :rooms, :locked, :boolean, default: false, null: false
  end
end
