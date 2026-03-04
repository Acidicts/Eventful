class AddSigningUserToOrganisation < ActiveRecord::Migration[8.1]
  def change
    # add a separate reference to a User who will sign for the organisation
    # this avoids clashing with the existing `user_id` column already present
    add_reference :organisations, :signing_user,
                  foreign_key: { to_table: :users },
                  null: true
  end
end
