class AddAnswererToMessage < ActiveRecord::Migration[8.1]
  def change
    # answerer should reference the users table (organiser or staff) and be
    # optional so old messages aren’t required to have one.  don’t let AR
    # generate a separate "answerers" table:
    add_reference :messages, :answerer, foreign_key: { to_table: :users }
  end
end
