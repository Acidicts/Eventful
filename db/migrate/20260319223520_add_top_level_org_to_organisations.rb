class AddTopLevelOrgToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :top_level_org, :boolean, default: true, null: false
  end
end
