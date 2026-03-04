class Organisation < ApplicationRecord
  has_many :users
  has_many :events

  # optional reference to the user who "signs" for the organisation
  belongs_to :signing_user, class_name: "User", optional: true
end
