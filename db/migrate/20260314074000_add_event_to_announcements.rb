class AddEventToAnnouncements < ActiveRecord::Migration[8.1]
  def change
    # In some environments the announcements table was created with an invalid
    # foreign key to a non-existent "creators" table. Remove that constraint
    # before altering the table so SQLite can rebuild it cleanly.
    if foreign_key_exists?(:announcements, :creators, column: :creator_id)
      remove_foreign_key :announcements, :creators, column: :creator_id
    end

    # Some environments may already have an `event_id` column on announcements (for
    # example, from a schema load or a partial schema migration). Only add the
    # column/index/foreign-key if it doesn't already exist.
    unless column_exists?(:announcements, :event_id)
      add_reference :announcements, :event, foreign_key: true, index: true
    else
      add_index :announcements, :event_id unless index_exists?(:announcements, :event_id)
      add_foreign_key :announcements, :events unless foreign_key_exists?(:announcements, :events)
    end

    # Ensure creator_id points to users (not creators) in all environments.
    unless foreign_key_exists?(:announcements, :users, column: :creator_id)
      add_foreign_key :announcements, :users, column: :creator_id
    end
  end
end
