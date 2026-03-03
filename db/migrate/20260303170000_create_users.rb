class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :name
      t.string :email
      t.string :slack_id
      t.string :verification_status
      t.boolean :admin, default: false, null: false
      t.references :organisation, foreign_key: true

      t.timestamps
    end

    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, :email
  end
end
