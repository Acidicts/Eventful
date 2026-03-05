class Organisation < ApplicationRecord
  # each organisation is "owned" by a user; this corresponds to the
  # `user_id` foreign key added in the original migration.  the bidirectional
  # association makes it easy to build new records from a user instance.
  belongs_to :user

  # the application also keeps a list of members via the reverse
  # relationship on `User` (see `User#organisations`).
  has_many :users
  has_many :events

  # optional reference to the user who "signs" for the organisation
  # optional reference to the user who "signs" for the organisation
  belongs_to :signing_user, class_name: "User"

  # validations -----------------------------------------------------------
  validates :signing_user, presence: true
  validate  :signing_user_must_be_member

  private

  # ensure the signing user is also part of the organisation's members.
  # previously this method attempted to mutate and save the record during
  # validation, which caused surprising side‑effects; instead we add an
  # error and let controllers decide how to handle it.  callers can still
  # populate the membership list manually if desired (the controller create
  # action already adds the creator).
  def signing_user_must_be_member
    return unless signing_user

    unless users.include?(signing_user)
      errors.add(:signing_user, "must belong to this organisation")
    end
  end
end
