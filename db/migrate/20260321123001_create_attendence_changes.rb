class CreateAttendenceChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :attendence_changes do |t|
      t.integer :attendence
      t.references :attendee, null: false, foreign_key: true

      t.timestamps
    end
  end
end
