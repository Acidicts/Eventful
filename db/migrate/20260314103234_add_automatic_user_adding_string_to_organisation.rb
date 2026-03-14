class AddAutomaticUserAddingStringToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :join_requirements, :string
  end
end
