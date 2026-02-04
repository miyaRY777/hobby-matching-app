class CreateProfileHobbies < ActiveRecord::Migration[7.2]
  def change
    create_table :profile_hobbies do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :hobby, null: false, foreign_key: true

      t.timestamps
    end

    add_index :profile_hobbies, [:profile_id, :hobby_id], unique: true
  end
end
