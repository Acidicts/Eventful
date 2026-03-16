class OrganisationRole < ApplicationRecord
  belongs_to :organisation

  has_and_belongs_to_many :users
  has_and_belongs_to_many :role_permissions
end
