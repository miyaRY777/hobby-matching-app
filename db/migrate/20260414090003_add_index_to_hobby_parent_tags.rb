class AddIndexToHobbyParentTags < ActiveRecord::Migration[7.2]
  def change
    add_index :hobby_parent_tags, [ :parent_tag_id, :room_type ]
  end
end
