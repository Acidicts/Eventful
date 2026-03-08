class AddApplyTokenToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :apply_token, :string
    add_index :events, :apply_token, unique: true
  end
end
