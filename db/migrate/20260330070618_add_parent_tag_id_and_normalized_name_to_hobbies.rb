class AddParentTagIdAndNormalizedNameToHobbies < ActiveRecord::Migration[7.2]
  def change
    add_reference :hobbies, :parent_tag, null: true, foreign_key: true
    add_column :hobbies, :normalized_name, :string
    add_index :hobbies, :normalized_name
  end
end
