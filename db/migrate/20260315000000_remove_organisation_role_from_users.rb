class RemoveOrganisationRoleFromUsers < ActiveRecord::Migration[8.1]
  def change
    # remove index first to avoid schema loader warnings during rollback
    remove_index :users, :organisation_role if index_exists?(:users, :organisation_role)

    remove_column :users, :organisation_role, :string
  end
end
