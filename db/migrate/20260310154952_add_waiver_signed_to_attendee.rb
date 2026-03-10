class AddWaiverSignedToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :waiver_signed, :boolean, default: false, null: false
  end
end
