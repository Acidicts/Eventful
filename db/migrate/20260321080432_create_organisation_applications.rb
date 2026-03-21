class CreateOrganisationApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :organisation_applications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
