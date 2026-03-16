class CreateOrganisationRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :organisation_roles do |t|
      t.references :organisation, null: false, foreign_key: true
      t.references :users, null: true, foreign_key: true
      t.references :permissions, null: true, foreign_key: true

      t.timestamps
    end
  end
end
