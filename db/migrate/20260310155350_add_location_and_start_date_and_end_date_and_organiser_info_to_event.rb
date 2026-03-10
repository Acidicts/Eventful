class AddLocationAndStartDateAndEndDateAndOrganiserInfoToEvent < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :location, :string, default: "TBA"
    # SQLite doesn’t support non‑constant defaults on ALTER TABLE; remove them here
    add_column :events, :start_date, :datetime
    add_column :events, :end_date, :datetime
    # organisers are actually users, so point the FK at the users table
    add_reference :events, :organiser, null: true, foreign_key: { to_table: :users }
  end
end
