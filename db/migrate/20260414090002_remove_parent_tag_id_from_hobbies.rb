class RemoveParentTagIdFromHobbies < ActiveRecord::Migration[7.2]
  def up
    remove_foreign_key :hobbies, :parent_tags
    remove_column :hobbies, :parent_tag_id
  end

  def down
    add_column :hobbies, :parent_tag_id, :bigint
    add_foreign_key :hobbies, :parent_tags
    add_index :hobbies, :parent_tag_id
  end
end
