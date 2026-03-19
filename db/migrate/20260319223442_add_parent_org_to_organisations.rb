class AddParentOrgToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_reference :organisations, :parent_org, null: true, foreign_key: { to_table: :organisations }
  end
end
