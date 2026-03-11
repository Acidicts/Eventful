class AddHasEventfulBrandingToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :eventful_branding, :boolean, default: true, null: false
  end
end
