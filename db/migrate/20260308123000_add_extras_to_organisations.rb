class AddExtrasToOrganisations < ActiveRecord::Migration[8.1]
  def change
    # these are all optional metadata that were referenced in views
    # but hadn't been persisted yet. adding them now keeps the
    # database in sync with the UI and prevents `NoMethodError`
    # when templates attempt to read the attributes.
    add_column :organisations, :img, :string
    add_column :organisations, :description, :text
    add_column :organisations, :self_found, :boolean, default: false, null: false
  end
end
