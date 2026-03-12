class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.string :message
      t.references :sender, null: false, foreign_key: true
      t.string :answer
      t.references :reciever, null: false, foreign_key: true

      t.timestamps
    end
  end
end
