class CreateHobbyParentTags < ActiveRecord::Migration[7.2]
  def up
    create_table :hobby_parent_tags do |t|
      t.references :hobby, null: false, foreign_key: true
      t.references :parent_tag, null: false, foreign_key: true
      t.integer :room_type, null: false
      t.timestamps
    end

    add_index :hobby_parent_tags, [ :hobby_id, :parent_tag_id ], unique: true
    add_index :hobby_parent_tags, [ :hobby_id, :room_type ], unique: true

    execute <<~SQL
      INSERT INTO hobby_parent_tags (hobby_id, parent_tag_id, room_type, created_at, updated_at)
      SELECT h.id, pt.id, pt.room_type, NOW(), NOW()
      FROM hobbies h
      JOIN parent_tags pt ON h.parent_tag_id = pt.id
      WHERE h.parent_tag_id IS NOT NULL
        AND pt.slug != 'uncategorized'
        AND pt.room_type IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE hobbies SET parent_tag_id = NULL
      WHERE parent_tag_id IN (
        SELECT id FROM parent_tags WHERE slug = 'uncategorized' AND room_type IS NULL
      )
    SQL

    execute "DELETE FROM parent_tags WHERE slug = 'uncategorized' AND room_type IS NULL"

    [ 0, 1, 2 ].each do |room_type|
      execute <<~SQL
        INSERT INTO parent_tags (name, slug, room_type, position, created_at, updated_at)
        VALUES ('未分類', 'uncategorized', #{room_type}, 999, NOW(), NOW())
        ON CONFLICT (room_type, slug) DO NOTHING
      SQL
    end
  end

  def down
    drop_table :hobby_parent_tags
  end
end
