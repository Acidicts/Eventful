class AddDefaultEventTitleToOrganisations < ActiveRecord::Migration[7.0]
  def change
    add_column :organisations, :default_event_title, :string
  end
end
