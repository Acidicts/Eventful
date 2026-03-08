class Organisation < ApplicationRecord
  # each organisation is "owned" by a user; this corresponds to the
  # `user_id` foreign key added in the original migration.  the bidirectional
  # association makes it easy to build new records from a user instance.
  belongs_to :user

  # the application also keeps a list of members via the reverse
  # relationship on `User` (see `User#organisations`).
  has_many :users
  has_many :events
  # convenience association to access all attendees across an organisation's events
  has_many :attendees, through: :events

  # optional reference to the user who "signs" for the organisation
  belongs_to :signing_user, class_name: "User"

  # ---------------------------------------------------------------
  # scopes
  # ---------------------------------------------------------------

  # returns organisations that are relevant to the given user.  a
  # regular member is included as soon as they appear in `organisations.users`;
  # signing users also need access even if they have been removed from the
  # membership list (existing data may fall out of sync during edits).  the
  # `left_joins`/`distinct` combination keeps the generated SQL from
  # duplicating rows when a user belongs to multiple organisations.
  scope :for_user, ->(user) {
    left_joins(:users)
      .where("users.id = :id OR organisations.signing_user_id = :id", id: user.id)
      .distinct
  }

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
