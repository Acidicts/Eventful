class AddAttendingToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :attending, :boolean, default: false, null: false
  end
end
