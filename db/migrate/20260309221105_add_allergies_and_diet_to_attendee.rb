class AddAllergiesAndDietToAttendee < ActiveRecord::Migration[8.1]
  def change
    add_column :attendees, :allergies, :string
    add_column :attendees, :diet, :integer
  end
end
