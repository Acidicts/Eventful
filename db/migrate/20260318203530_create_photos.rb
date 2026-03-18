class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :event, null: false, foreign_key: true
      t.references :attendee, null: false, foreign_key: true
      t.string :caption

      t.timestamps
    end
  end
end
