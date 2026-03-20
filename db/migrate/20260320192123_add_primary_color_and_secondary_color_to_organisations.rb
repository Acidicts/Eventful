class AddPrimaryColorAndSecondaryColorToOrganisations < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :primary_color, :string
    add_column :organisations, :secondary_color, :string
  end
end
