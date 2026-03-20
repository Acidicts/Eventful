class Organisation < ApplicationRecord
  MEMBER_RESTRICTED_PERMISSIONS = [
    "role-create",
    "role-update",
    "role-destroy"
  ].freeze

  PARENT_SUB_TEAM_MEMBER_ALLOWED_PERMISSIONS = [
    "organisation-view",
    "organisation-join-team-sub-team",
    "organisation-dashboard-view",
    "organisation-dashboard-events-view",
    "organisation-dashboard-attendees-view",
    "organisation-dashboard-sub-teams-view",
    "organisation-dashboard-sub-teams-create",
    "event-view",
    "event-attendees-view",
    "event-attendee-view",
    "event-attendee-waiver-view"
  ].freeze

  # each organisation is "owned" by a user; this corresponds to the
  # `user_id` foreign key added in the original migration.  the bidirectional
  # association makes it easy to build new records from a user instance.
  belongs_to :user

  # the application also keeps a list of members via the reverse
  # relationship on `User` (see `User#organisations`).
  #
  # When an organisation is deleted we don't want to delete user accounts, so
  # simply nullify their association.
  has_many :users,
           dependent: :nullify,
           after_add: :sync_roles_after_member_added,
           after_remove: :sync_roles_after_member_removed

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

  # hierarchy links between organisations.
  #
  # `parent_org_id` is the primary path for sub-team relationships.
  # `child_org_id` is kept for compatibility with older records where a
  # single child link may have been stored directly on the parent.
  belongs_to :parent_org, class_name: "Organisation", optional: true, inverse_of: :sub_teams
  has_many :sub_teams, class_name: "Organisation", foreign_key: :parent_org_id, dependent: :nullify, inverse_of: :parent_org
  belongs_to :child_org, class_name: "Organisation", optional: true
  has_one :legacy_parent_org, class_name: "Organisation", foreign_key: :child_org_id, dependent: :nullify, inverse_of: :child_org

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
  before_validation :sync_top_level_org
  before_destroy :mark_role_sync_teardown

  attribute :join_requirements, :string, default: "nil"

  # validations -----------------------------------------------------------
  validates :signing_user, presence: true
  validate  :signing_user_must_be_member
  validate  :ensure_sub_teams_are_members
  validate :auto_add_users
  validate :hierarchy_links_must_not_self_reference

  after_save :give_all_users_roles
  after_save :sync_featured_child_parent_link
  after_create :ensure_default_roles

  # The most reliable parent reference across legacy/current schema.
  def parent_team
    parent_org || legacy_parent_org
  end

  # Collect child teams from both the modern (`parent_org_id`) and legacy
  # (`child_org_id`) link styles so callers can render one navigation list.
  def child_teams
    teams = sub_teams
    teams = teams.or(Organisation.where(id: child_org_id)) if child_org_id.present?
    teams.distinct
  end

  def ensure_sub_teams_are_members
    users = sub_teams.joins(:users).where(users: { id: signing_user_id }).distinct
    users.each do |user|
      self.users << user unless self.users.where(id: user.id).exists?
      give_all_users_roles
    end
  end

  def give_all_users_roles
    return unless signing_user
    return if @_give_all_users_roles_in_progress

    @_give_all_users_roles_in_progress = true
    signing_role = OrganisationRole.find_or_create_by!(organisation: self, name: "Signing User")
    member_role  = OrganisationRole.find_or_create_by!(organisation: self, name: "Member")

    # Signing users should always have access to all permissions.
    signing_role.role_permissions = RolePermission.all

    # Keep the signing role exclusive to the current signing user.
    signing_role.users = [ signing_user ]

    # Signing users should never be treated as regular members.
    member_role.users.delete(signing_user) if member_role.users.where(id: signing_user.id).exists?

    ensure_default_member_permissions(member_role)

    # Ensure all other users have the member role.
    users.each do |user|
      next if user == signing_user
      member_role.users << user unless member_role.users.where(id: user.id).exists?
    end

    # Remove stale member assignments for users no longer in this organisation.
    member_ids = users.where.not(id: signing_user.id).pluck(:id)
    member_role.users.where.not(id: member_ids).find_each do |user|
      member_role.users.delete(user)
    end

    cleanup_stale_non_member_roles

    sync_parent_member_role_for_child_members
  ensure
    @_give_all_users_roles_in_progress = false
  end

  def auto_add_users
    return if join_requirements == "nil" || join_requirements.blank?
    signing_role = OrganisationRole.find_or_create_by!(organisation: self, name: "Signing User")
    signing_role.role_permissions = RolePermission.all

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
    signing_role = OrganisationRole.find_or_create_by!(organisation: self, name: "Signing User")
    signing_role.role_permissions = RolePermission.all

    member_role = OrganisationRole.find_or_create_by!(organisation: self, name: "Member")
    ensure_default_member_permissions(member_role)
  end

  private

  def sync_roles_after_member_added(_user)
    return unless persisted?
    return if @_role_sync_teardown

    ensure_default_roles
    give_all_users_roles
  end

  def sync_roles_after_member_removed(user)
    return unless persisted?
    return if @_role_sync_teardown

    # Signing users keep their explicit signing role even if membership rows
    # are temporarily inconsistent.
    unless signing_user_id.present? && user.id == signing_user_id
      organisation_roles.find_each do |role|
        role.users.delete(user) if role.users.where(id: user.id).exists?
      end
    end

    ensure_default_roles
    give_all_users_roles
  end

  def cleanup_stale_non_member_roles
    allowed_user_ids = users.pluck(:id)
    allowed_user_ids << signing_user.id if signing_user
    allowed_user_ids.uniq!

    organisation_roles.where.not(name: "Sub Team Member").find_each do |role|
      role.users.where.not(id: allowed_user_ids).find_each do |user|
        role.users.delete(user)
      end
    end
  end

  def mark_role_sync_teardown
    @_role_sync_teardown = true
  end

  def ensure_default_member_permissions(member_role)
    RolePermission.where.not(permission: MEMBER_RESTRICTED_PERMISSIONS).find_each do |permission|
      next if member_role.role_permissions.where(id: permission.id).exists?

      member_role.role_permissions << permission
    end

    restricted_permissions = RolePermission.where(permission: MEMBER_RESTRICTED_PERMISSIONS)
    member_role.role_permissions.delete(restricted_permissions) if restricted_permissions.exists?
  end

  def ensure_parent_sub_team_member_permissions(role)
    allowed_permissions = RolePermission.where(permission: PARENT_SUB_TEAM_MEMBER_ALLOWED_PERMISSIONS)
    role.role_permissions = allowed_permissions
  end

  def sync_parent_member_role_for_child_members
    parent = parent_team
    return unless parent

    parent_member_role = OrganisationRole.find_by(organisation: parent, name: "Member")
    parent_sub_team_role = OrganisationRole.find_or_create_by!(organisation: parent, name: "Sub Team Member")
    ensure_parent_sub_team_member_permissions(parent_sub_team_role)

    users.each do |user|
      # keep signing users exclusive on each organisation.
      next if parent.signing_user_id.present? && user.id == parent.signing_user_id

      parent_sub_team_role.users << user unless parent_sub_team_role.users.where(id: user.id).exists?

      # Older records may still have inherited child members in the broad
      # parent "Member" role. Remove that assignment only when this user
      # isn't a direct parent member and has no custom parent role.
      next unless parent_member_role&.users&.where(id: user.id)&.exists?
      next if parent.users.where(id: user.id).exists?
      next if user.organisation_roles.where(organisation: parent).where.not(name: [ "Member", "Sub Team Member" ]).exists?

      parent_member_role.users.delete(user)
    end
  end

  def sync_top_level_org
    self.top_level_org = parent_org_id.blank?
  end

  def hierarchy_links_must_not_self_reference
    if parent_org_id.present? && parent_org_id == id
      errors.add(:parent_org_id, "cannot point to this organisation")
    end

    if child_org_id.present? && child_org_id == id
      errors.add(:child_org_id, "cannot point to this organisation")
    end
  end

  def sync_featured_child_parent_link
    return if child_org_id.blank? || child_org_id == id

    child_org_record = Organisation.find_by(id: child_org_id)
    return unless child_org_record
    return if child_org_record.parent_org_id == id

    # Keep parent -> featured child selections navigable without requiring
    # manual edits on both records.
    child_org_record.update_columns(parent_org_id: id, top_level_org: false)
  end

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
