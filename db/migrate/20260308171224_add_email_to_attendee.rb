class AddEmailToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :email, :string
  end
end
