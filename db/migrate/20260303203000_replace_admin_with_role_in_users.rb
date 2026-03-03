class ReplaceAdminWithRoleInUsers < ActiveRecord::Migration[8.1]
  def up
    # add the new role column first so we can migrate data
    add_column :users, :role, :string, null: false, default: "user"

    # copy existing admin values to role
    execute <<~SQL.squish
      UPDATE users
      SET role = 'admin'
      WHERE admin = 1
    SQL

    remove_column :users, :admin, :boolean
  end

  def down
    add_column :users, :admin, :boolean, null: false, default: false
    execute <<~SQL.squish
      UPDATE users
      SET admin = 1
      WHERE role = 'admin'
    SQL
    remove_column :users, :role
  end
end
