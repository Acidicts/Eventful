class AddUnderageParentSignatureToAttendees < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:attendees, :under_18)
      add_column :attendees, :under_18, :boolean, default: false, null: false
    end

    unless column_exists?(:attendees, :parent_signature)
      add_column :attendees, :parent_signature, :string
    end
  end
end
