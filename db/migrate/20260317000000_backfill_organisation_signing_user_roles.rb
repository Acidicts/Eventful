class BackfillOrganisationSigningUserRoles < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Ensure every organisation has the two expected roles (Member + Signing User)
    # and that the signing user is assigned the Signing User role.
    Organisation.find_each do |org|
      org.give_all_users_roles
    rescue StandardError => e
      Rails.logger.error("BackfillOrganisationSigningUserRoles: failed for org \\#{org.id}: #{e.message}")
    end
  end

  def down
    # no-op: this migration is for data correction only.
  end
end
