class AddNameToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :name, :string, default: "Unamed Organisation", null: false
  end
end
