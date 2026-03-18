class FixOrganisationRoleAndRolePermissions < ActiveRecord::Migration[8.1]
  def up
    # Fix the incorrectly pluralised foreign keys created by earlier migrations.

    # SQLite rebuilds the whole table when removing FKs/columns. If the legacy
    # permissions FK is still present but the permissions table does not exist,
    # that rebuild fails. Drop this FK first to unblock subsequent changes.
    if column_exists?(:organisation_roles, :permissions_id) && foreign_key_exists?(:organisation_roles, column: :permissions_id)
      remove_foreign_key :organisation_roles, column: :permissions_id
    end

    # org role <-> user is a many-to-many relationship.
    create_table :organisation_roles_users, id: false, if_not_exists: true do |t|
      t.references :organisation_role, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
    end
    add_index :organisation_roles_users, %i[organisation_role_id user_id], unique: true, name: "index_organisation_roles_users_on_org_role_and_user"

    if column_exists?(:organisation_roles, :users_id)
      if foreign_key_exists?(:organisation_roles, column: :users_id)
        remove_foreign_key :organisation_roles, column: :users_id
      end

      execute <<~SQL
        INSERT INTO organisation_roles_users (organisation_role_id, user_id)
        SELECT id, users_id FROM organisation_roles WHERE users_id IS NOT NULL
      SQL

      remove_column :organisation_roles, :users_id
    end

    if column_exists?(:organisation_roles, :user_id)
      execute <<~SQL
        INSERT INTO organisation_roles_users (organisation_role_id, user_id)
        SELECT id, user_id FROM organisation_roles WHERE user_id IS NOT NULL
      SQL

      remove_column :organisation_roles, :user_id
    end

    # role_permission <-> organisation_role is a many-to-many relationship.
    create_table :organisation_roles_role_permissions, id: false, if_not_exists: true do |t|
      t.references :organisation_role, null: false, foreign_key: true, index: false
      t.references :role_permission, null: false, foreign_key: true, index: false
    end
    add_index :organisation_roles_role_permissions, %i[organisation_role_id role_permission_id], unique: true, name: "index_org_roles_role_perms_on_role_and_perm"

    if column_exists?(:role_permissions, :organisation_roles_id)
      if foreign_key_exists?(:role_permissions, column: :organisation_roles_id)
        remove_foreign_key :role_permissions, column: :organisation_roles_id
      end

      execute <<~SQL
        INSERT INTO organisation_roles_role_permissions (organisation_role_id, role_permission_id)
        SELECT organisation_roles_id, id FROM role_permissions WHERE organisation_roles_id IS NOT NULL
      SQL

      remove_column :role_permissions, :organisation_roles_id
    end

    if column_exists?(:role_permissions, :organisation_role_id)
      if foreign_key_exists?(:role_permissions, column: :organisation_role_id)
        remove_foreign_key :role_permissions, column: :organisation_role_id
      end

      execute <<~SQL
        INSERT INTO organisation_roles_role_permissions (organisation_role_id, role_permission_id)
        SELECT organisation_role_id, id FROM role_permissions WHERE organisation_role_id IS NOT NULL
      SQL

      remove_column :role_permissions, :organisation_role_id
    end

    if column_exists?(:role_permissions, :name)
      rename_column :role_permissions, :name, :permission
    end

    if column_exists?(:organisation_roles, :permissions_id)
      remove_column :organisation_roles, :permissions_id
    end
  end

  def down
    # Revert to a simple belongs_to structure for backwards compatibility.
    unless column_exists?(:organisation_roles, :user_id)
      add_reference :organisation_roles, :user, foreign_key: true
    end

    if table_exists?(:organisation_roles_users)
      execute <<~SQL
        UPDATE organisation_roles
        SET user_id = (
          SELECT user_id
          FROM organisation_roles_users
          WHERE organisation_roles_users.organisation_role_id = organisation_roles.id
          LIMIT 1
        )
      SQL

      drop_table :organisation_roles_users
    end

    unless column_exists?(:role_permissions, :organisation_role_id)
      add_reference :role_permissions, :organisation_role, foreign_key: true
    end

    if table_exists?(:organisation_roles_role_permissions)
      execute <<~SQL
        UPDATE role_permissions
        SET organisation_role_id = (
          SELECT organisation_role_id
          FROM organisation_roles_role_permissions
          WHERE organisation_roles_role_permissions.role_permission_id = role_permissions.id
          LIMIT 1
        )
      SQL

      drop_table :organisation_roles_role_permissions
    end

    if column_exists?(:role_permissions, :permission)
      rename_column :role_permissions, :permission, :name
    end

    if column_exists?(:organisation_roles, :permissions_id)
      remove_column :organisation_roles, :permissions_id
    end
  end
end
