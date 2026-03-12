class RemoveInvalidMessageForeignKeys < ActiveRecord::Migration[8.1]
  def change
    # the original messages migration added foreign keys to tables that never
    # existed (`senders` and `recievers`). SQLite enforces these by looking up
    # the table names and throws errors when they are missing, so drop them.
    # SQLite rebuilds the table when removing FKs which still triggers the
    # missing-table error; temporarily create empty stub tables to satisfy the
    # reconstructor and then remove them afterwards.

    # ensure dummy tables exist so the foreign key removal can proceed
    create_table :senders, force: :cascade do |t|
      # no columns needed
    end unless table_exists?(:senders)

    create_table :recievers, force: :cascade do |t|
      # no columns needed
    end unless table_exists?(:recievers)

    remove_foreign_key :messages, :senders if foreign_key_exists?(:messages, :senders)
    remove_foreign_key :messages, :recievers if foreign_key_exists?(:messages, :recievers)

    # drop the stub tables now that they are no longer needed
    drop_table :senders, if_exists: true
    drop_table :recievers, if_exists: true
  end
end
