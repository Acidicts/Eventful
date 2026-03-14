class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :event, foreign_key: true
      t.string :content
      t.boolean :public
      t.references :organisation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
