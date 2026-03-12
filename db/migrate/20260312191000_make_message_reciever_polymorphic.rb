class MakeMessageRecieverPolymorphic < ActiveRecord::Migration[8.1]
  def up
    add_column :messages, :reciever_type, :string
    add_index :messages, [ :reciever_type, :reciever_id ]

    # existing rows reference attendees; mark them accordingly
    execute <<-SQL.squish
      UPDATE messages
      SET reciever_type = 'Attendee'
      WHERE reciever_id IS NOT NULL
    SQL
  end

  def down
    remove_index :messages, column: [ :reciever_type, :reciever_id ]
    remove_column :messages, :reciever_type
  end
end
