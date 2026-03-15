class AddTimezoneToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :timezone, :string, default: "UTC"
    add_column :organisations, :time_utc_offset, :integer, default: 0
  end
end
