class CreateEmailLoginOtps < ActiveRecord::Migration[8.1]
  def change
    create_table :email_login_otps do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :code, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :email_login_otps, :token, unique: true
    add_index :email_login_otps, :code
  end
end
