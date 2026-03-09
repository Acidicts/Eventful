class ChangeDietDefaultOnAttendees < ActiveRecord::Migration[8.1]
  def change
    # give a default and disallow nulls (optional)
    change_column_default :attendees, :diet, from: nil, to: 0
    change_column_null    :attendees, :diet, false, 0
  end
end