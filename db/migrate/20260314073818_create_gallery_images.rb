class CreateGalleryImages < ActiveRecord::Migration[8.1]
  def change
    create_table :gallery_images do |t|
      t.references :attendee, null: false, foreign_key: true
      t.string :caption
      t.datetime :day_from
      t.references :gallery, null: false, foreign_key: true

      t.timestamps
    end
  end
end
