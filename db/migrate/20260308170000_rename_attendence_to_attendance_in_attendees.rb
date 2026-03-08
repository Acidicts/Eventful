class RenameAttendenceToAttendanceInAttendees < ActiveRecord::Migration[8.1]
  def change
    # column name was misspelled in earlier migration; correct it for enums
    rename_column :attendees, :attendence, :attendance
  end
end
