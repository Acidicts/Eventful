class AddBannedToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :banned, :boolean, default: false, null: false
  end
end
