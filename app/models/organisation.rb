class Organisation < ApplicationRecord
  # each organisation is "owned" by a user; this corresponds to the
  # `user_id` foreign key added in the original migration.  the bidirectional
  # association makes it easy to build new records from a user instance.
  belongs_to :user

  # the application also keeps a list of members via the reverse
  # relationship on `User` (see `User#organisations`).
  #
  # When an organisation is deleted we don't want to delete user accounts, so
  # simply nullify their association.
  has_many :users, dependent: :nullify

  # deleting an organisation should remove its events and any related data
  # (galleries/announcements are also tied directly to the org).
  has_many :events, dependent: :destroy
  has_many :galleries, dependent: :destroy
  has_many :announcements, dependent: :destroy

  # roles within the organisation (e.g., `Member`, `Signing User`)
  has_many :organisation_roles, dependent: :destroy

  # convenience association to access all attendees across an organisation's events
  has_many :attendees, through: :events

  # optional reference to the user who "signs" for the organisation
  belongs_to :signing_user, class_name: "User"

  # stored in the DB as `nil_org`; this boolean flags a placeholder "nil" org
  alias_attribute :nil_organisation, :nil_org

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

  # callbacks -------------------------------------------------------------
  # when the `self_found` flag is set we treat the owning user as the signing
  # user and make sure that person is a member of the organisation. doing
  # this in a callback keeps the logic close to the model and means the same
  # behaviour applies on create *and* update (controllers no longer need to
  # remember to wire it up).
  before_validation :apply_self_found_logic

  attribute :join_requirements, :string, default: "nil"

  # validations -----------------------------------------------------------
  validates :signing_user, presence: true
  validate  :signing_user_must_be_member
  validate :auto_add_users

  after_save :give_all_users_roles
  after_create :ensure_default_roles

  def give_all_users_roles
    return unless signing_user
    return if @_give_all_users_roles_in_progress

    @_give_all_users_roles_in_progress = true
    signing_role = OrganisationRole.find_or_create_by!(organisation: self, name: "Signing User")
    member_role  = OrganisationRole.find_or_create_by!(organisation: self, name: "Member")

    # Keep the signing role exclusive to the current signing user.
    signing_role.users = [ signing_user ]

    # Signing users should never be treated as regular members.
    member_role.users.delete(signing_user) if member_role.users.where(id: signing_user.id).exists?

    # Ensure all other users have the member role.
    users.each do |user|
      next if user == signing_user
      member_role.users << user unless member_role.users.where(id: user.id).exists?
    end
  ensure
    @_give_all_users_roles_in_progress = false
  end

  def auto_add_users
    return if join_requirements == "nil" || join_requirements.blank?

    if join_requirements.include?("omniauth")
      _, provider = join_requirements.split(" ", 2)
      return if provider.blank?
      counter = 0
      User.where(provider: provider, organisation_id: nil).find_each do |user|
        users << user unless users.include?(user)
        member_role = OrganisationRole.find_or_create_by!(organisation: self, name: "Member")
        member_role.users << user unless member_role.users.include?(user)
        counter += 1
      end
      counter
    end
  end

  def ensure_default_roles
    OrganisationRole.find_or_create_by!(organisation: self, name: "Signing User") do |role|
      role.role_permissions = RolePermission.all
    end

    OrganisationRole.find_or_create_by!(organisation: self, name: "Member")
  end

  private

  # if the organisation is marked self‑found then the owner should act as the
  # signer. we also take care of adding the signing user to the membership
  # list so external callers (controllers, tests, etc.) don't have to do it
  # themselves. mutating the `users` association during validation is safe
  # because we're still working with an unsaved record; saving the
  # organisation will persist any new join records automatically.
  def apply_self_found_logic
    return unless self_found

    # Default to the owner only when no signing user has been chosen yet.
    # This keeps create behaviour intact without overriding future role edits.
    self.signing_user ||= user if user.present?

    # ensure the signing user is a member as well. the custom validator below
    # will add an error if this step fails, but pre‑emptively pushing the user
    # into `users` makes the normal case much smoother.
    if signing_user && !users.include?(signing_user)
      users << signing_user
    end
  end

  # ensure the signing user is also part of the organisation's members.
  # previously this method attempted to mutate and save the record during
  # validation, which caused surprising side‑effects; instead we add an
  # error and let controllers decide how to handle it.  callers can still
  # populate the membership list manually if desired (the controller create
  # action already adds the creator).
  def signing_user_must_be_member
    return unless signing_user

    unless users.include?(signing_user)
      users << signing_user
      errors.add(:signing_user, "must belong to this organisation")
    end
  end
end
