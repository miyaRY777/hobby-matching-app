class CreateParentTags < ActiveRecord::Migration[7.2]
  def change
    create_table :parent_tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :room_type
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :parent_tags, %i[room_type slug], unique: true
  end
end
