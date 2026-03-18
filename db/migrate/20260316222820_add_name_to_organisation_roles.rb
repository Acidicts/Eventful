class AddNameToOrganisationRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :organisation_roles, :name, :string, null: false, default: ""
    add_index :organisation_roles, [ :organisation_id, :name ], unique: true, name: "index_organisation_roles_on_organisation_and_name"
  end
end
