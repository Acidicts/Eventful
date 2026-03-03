class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name
      t.string :description
      t.integer :capacity
      t.integer :applied
      t.references :attendee, null: false, foreign_key: true
      t.references :organisation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
