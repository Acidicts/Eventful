class AddNameToOrganisationRoles < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:organisation_roles, :name)
      add_column :organisation_roles, :name, :string, null: false, default: ""
    end

    unless index_exists?(:organisation_roles, [ :organisation_id, :name ], name: "index_organisation_roles_on_organisation_and_name")
      add_index :organisation_roles, [ :organisation_id, :name ], unique: true, name: "index_organisation_roles_on_organisation_and_name"
    end
  end
end
