class AddIpAndAttendenceToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :ip, :string, default: nil, null: true
    add_column :attendees, :attendence, :integer, default: 0
  end
end
