class AddIndexToRoomMembershipsByProfileIdAndCreatedAt < ActiveRecord::Migration[7.2]
  def change
    add_index :room_memberships, [:profile_id, :created_at]
  end
end
