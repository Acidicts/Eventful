class AddBanReasonToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :ban_reason, :string
  end
end
