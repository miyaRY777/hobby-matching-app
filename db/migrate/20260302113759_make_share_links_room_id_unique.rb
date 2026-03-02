class MakeShareLinksRoomIdUnique < ActiveRecord::Migration[7.2]
  def change
    # 既存の通常indexを外して、unique indexに差し替える
    remove_index :share_links, :room_id if index_exists?(:share_links, :room_id)

    add_index :share_links, :room_id, unique: true
  end
end
