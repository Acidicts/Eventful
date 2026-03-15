class AddDefaultEventLocationToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :default_event_location, :string, default: "", null: false
  end
end
