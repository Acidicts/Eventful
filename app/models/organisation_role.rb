class OrganisationRole < ApplicationRecord
  DEFAULT_ROLE_NAMES = [ "Signing User", "Member" ].freeze

  belongs_to :organisation

  has_and_belongs_to_many :users
  has_and_belongs_to_many :role_permissions

  after_destroy_commit :restore_default_roles_if_needed

  private

  def restore_default_roles_if_needed
    return unless DEFAULT_ROLE_NAMES.include?(name)
    return if destroyed_by_association.present?

    org = Organisation.find_by(id: organisation_id)
    return unless org

    org.ensure_default_roles
    org.give_all_users_roles
  end
end
