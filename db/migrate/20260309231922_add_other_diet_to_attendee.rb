class AddOtherDietToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :other_diet, :string, default: "", null: false
  end
end
