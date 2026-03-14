class AddEventToAnnouncements < ActiveRecord::Migration[8.1]
  def change
    # In some environments the announcements table was created with an invalid
    # foreign key to a non-existent "creators" table. Remove that constraint
    # before altering the table so SQLite can rebuild it cleanly.
    if foreign_key_exists?(:announcements, :creators, column: :creator_id)
      remove_foreign_key :announcements, :creators, column: :creator_id
    end

    add_reference :announcements, :event, foreign_key: true, index: true

    # Ensure creator_id points to users (not creators) in all environments.
    unless foreign_key_exists?(:announcements, :users, column: :creator_id)
      add_foreign_key :announcements, :users, column: :creator_id
    end
  end
end
