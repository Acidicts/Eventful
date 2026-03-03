class CreateAttendees < ActiveRecord::Migration[8.1]
  def change
    create_table :attendees do |t|
      t.string :name
      t.integer :age
      t.string :code

      t.timestamps
    end
  end
end
