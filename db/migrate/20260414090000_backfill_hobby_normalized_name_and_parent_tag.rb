class BackfillHobbyNormalizedNameAndParentTag < ActiveRecord::Migration[7.2]
  class MigrationParentTag < ApplicationRecord
    self.table_name = "parent_tags"
  end

  class MigrationHobby < ApplicationRecord
    self.table_name = "hobbies"
  end

  def up
    uncategorized = MigrationParentTag.find_or_create_by!(slug: "uncategorized", room_type: nil) do |parent_tag|
      parent_tag.name = "未分類"
      parent_tag.position = 0
    end

    MigrationHobby.where(normalized_name: nil).find_each do |hobby|
      hobby.update_columns(normalized_name: normalize_name(hobby.name))
    end

    MigrationHobby.where(parent_tag_id: nil).find_each do |hobby|
      hobby.update_columns(parent_tag_id: uncategorized.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def normalize_name(name)
    name.to_s.unicode_normalize(:nfkc).strip.downcase
  end
end
