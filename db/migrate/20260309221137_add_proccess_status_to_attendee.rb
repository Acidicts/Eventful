class AddProccessStatusToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :status, :integer
  end
end
