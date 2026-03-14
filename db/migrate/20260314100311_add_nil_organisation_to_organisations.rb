class AddNilOrganisationToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :nil_org, :boolean, default: false, null: false
  end
end
