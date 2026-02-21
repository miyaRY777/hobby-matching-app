class CreateRoomMemberships < ActiveRecord::Migration[7.2]
  def change
    create_table :room_memberships do |t|
      t.references :room, null: false, foreign_key: true
      t.references :profile, null: false, foreign_key: true

      t.timestamps
    end

    add_index :room_memberships, %i[room_id profile_id], unique: true
  end
end
