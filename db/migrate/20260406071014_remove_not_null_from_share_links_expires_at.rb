class RemoveNotNullFromShareLinksExpiresAt < ActiveRecord::Migration[7.2]
  def change
    change_column_null :share_links, :expires_at, true
  end
end
