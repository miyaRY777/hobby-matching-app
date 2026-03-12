class AddDescriptionToProfileHobbies < ActiveRecord::Migration[7.2]
  def change
    add_column :profile_hobbies, :description, :string, limit: 200
  end
end
