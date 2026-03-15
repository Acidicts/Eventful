class AddDeafultStartEndTimeAndEventLengthToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :default_event_start_time, :time, default: "10:00:00"
    add_column :organisations, :default_event_end_time, :time, default: "15:00:00"
    add_column :organisations, :default_event_length, :integer, default: 2
  end
end
