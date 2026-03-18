class RenameDefaultRoleInOrganisationRoles < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:organisation_roles, :default_role) && !column_exists?(:organisation_roles, :is_default_role)
      rename_column :organisation_roles, :default_role, :is_default_role
    end
  end
end
