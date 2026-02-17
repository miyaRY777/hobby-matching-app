class CreateRooms < ActiveRecord::Migration[7.2]
  def change
    create_table :rooms do |t|
      t.references :issuer_profile,
                   null: false,
                   foreign_key: { to_table: :profiles}
      t.string :label

      t.timestamps
    end
  end
end
