class AddFinishedToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :finished, :boolean, default: false, null: false
  end
end
