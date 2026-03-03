class AddOrganisationRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :organisation_role, :string, null: false, default: "member"
    add_index :users, :organisation_role
  end
end
