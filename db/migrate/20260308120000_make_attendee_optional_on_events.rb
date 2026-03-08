class MakeAttendeeOptionalOnEvents < ActiveRecord::Migration[8.1]
  def change
    # allow events to be created without an attendee assigned
    change_column_null :events, :attendee_id, true
  end
end
