class RolePermission < ApplicationRecord
  has_and_belongs_to_many :organisation_roles

  validates :permission, presence: true
end
