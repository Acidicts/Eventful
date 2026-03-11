class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[8.1]
  def change
    # ensure the column exists for the current database; previous migration may
    # have been run before we added the field to the migration file and thus
    # the column might be missing.
    unless column_exists?(:active_storage_blobs, :service_name)
      add_column :active_storage_blobs, :service_name, :string, null: false, default: "local"
    end
  end
end
