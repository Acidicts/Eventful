class AddDefaultRoleToOrganisationRole < ActiveRecord::Migration[8.1]
  def change
    add_column :organisation_roles, :default_role, :boolean, default: false, null: false
  end
end
