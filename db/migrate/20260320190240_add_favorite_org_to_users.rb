class AddFavoriteOrgToUsers < ActiveRecord::Migration[8.1]
  def change
    # Make this optional at first so existing users with no default organisation
    # don't break the migration.  It's safe to make non-null later once data is
    # backfilled if required.
    add_reference :users, :favorite_org, null: true, foreign_key: { to_table: :organisations }
  end
end
