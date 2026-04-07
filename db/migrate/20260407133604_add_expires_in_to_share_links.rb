class AddExpiresInToShareLinks < ActiveRecord::Migration[7.2]
  def change
    add_column :share_links, :expires_in, :string
  end
end
