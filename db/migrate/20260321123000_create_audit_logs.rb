class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :request_method, null: false
      t.string :path, null: false
      t.integer :status_code
      t.string :ip_address
      t.text :details, null: false, default: "{}"

      t.timestamps
    end

    add_index :audit_logs, :created_at
    add_index :audit_logs, :action
  end
end
