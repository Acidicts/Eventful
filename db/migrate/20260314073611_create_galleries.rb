class CreateGalleries < ActiveRecord::Migration[8.1]
  def change
    create_table :galleries do |t|
      t.references :organisation, null: false, foreign_key: true
      t.boolean :public

      t.timestamps
    end
  end
end
