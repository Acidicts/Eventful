class AddWaiverFieldsToAttendees < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:attendees, :waiver_signed_at)
      add_column :attendees, :waiver_signed_at, :datetime
    end

    unless column_exists?(:attendees, :waiver_signature)
      add_column :attendees, :waiver_signature, :string
    end
  end
end
