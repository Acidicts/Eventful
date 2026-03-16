class RenameDefaultRoleInOrganisationRoles < ActiveRecord::Migration[7.0]
  def change
    rename_column :organisation_roles, :default_role, :is_default_role
  end
end
