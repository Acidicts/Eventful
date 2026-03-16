class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions do |t|
      t.references :organisation_roles, null: true, foreign_key: true
      t.string :name, default: "", null: false

      t.timestamps
    end
  end
end
