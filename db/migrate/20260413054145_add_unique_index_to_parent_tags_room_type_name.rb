class AddUniqueIndexToParentTagsRoomTypeName < ActiveRecord::Migration[7.2]
  def change
    add_index :parent_tags, [ :room_type, :name ], unique: true
  end
end
