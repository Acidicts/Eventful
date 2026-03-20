class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # tests make requests without a real browser UA, so disable the check there.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :user_signed_in?, :current_attendee, :attendee_logged_in?, :has_permission?

  before_action :load_placeholder_user
  before_action :load_permissions

  PERMISSION_CATALOG = [
    # Organisation management
    "organisation-view",
    "organisation-create",
    "organisation-update",
    "organisation-destroy",
    "organisation-join-team-sub-team",
    "organisation-favorite",

    # Org dashboard
    "organisation-dashboard-view",
    "organisation-dashboard-events-view",
    "organisation-dashboard-attendees-view",
    "organisation-dashboard-sub-teams-view",
    "organisation-dashboard-sub-teams-create",

    # Organisation settings
    "organisation-settings-view",
    "organisation-settings-customisations",
    "organisation-settings-events-defaults",
    "organisation-settings-members",
    "organisation-settings-roles",
    "organisation-settings-branding",

    # Role management
    "role-create",
    "role-update",
    "role-destroy",

    # Event management
    "event-view",
    "event-create",
    "event-update",
    "event-destroy",
    "event-announcements-view",
    "event-attendees-view",
    "event-attendee-view",
    "event-attendee-edit",
    "event-attendee-update",
    "event-attendee-waiver-view",
    "event-attendee-waiver-destroy",
    "event-apply",
    "event-apply-create",
    "event-sign-in",
    "event-sign-out",
    "event-get-info",
    "event-scan",
    "event-send-qr-codes",

    # Attendee portal
    "attendee-portal-access",
    "attendee-portal-login",
    "attendee-portal-logout",
    "attendee-portal-contact",
    "attendee-portal-gallery-view",
    "attendee-portal-gallery-upload",
    "attendee-portal-qr-code-view",
    "attendee-portal-waiver-view",
    "attendee-portal-waiver-sign",
    "attendee-portal-profile-update",

    # QR code utilities
    "qr-code-generate",
    "qr-code-decode",
    "qr-code-public-view",

    # Admin area
    "admin-access",

    # Guides
    "guides-view"
  ].freeze

  def load_permissions
    PERMISSION_CATALOG.each do |permission|
      RolePermission.find_or_create_by!(permission: permission)
    end
  end

  def load_placeholder_user
    @nil_user ||= User.find_or_create_by!(provider: "placeholder", uid: "nil") do |user|
      user.name               = "Nil User"
      user.email              = "nil@example.com"
      user.role               = "member"
    end

    @nil_organisation ||= Organisation.find_or_create_by!(user: @nil_user, name: "Nil Organisation") do |org|
      org.signing_user = @nil_user
      org.self_found   = true
      org.description  = "Placeholder organisation used when no user is signed in."
      org.nil_org      = true
    end

    if !@nil_organisation.users.include?(@nil_user)
      @nil_user.organisation << @nil_organisation
    end
    # Ensure the placeholder user is linked to the placeholder organisation.
    @nil_user.update!(organisation: @nil_organisation) if @nil_user.organisation != @nil_organisation
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def user_signed_in?
    logged_in?
  end

  def authenticate_user!
    redirect_to root_path, alert: "You must sign in first" unless user_signed_in?
  end

  # attendee portal helpers --------------------------------------------------

  def current_attendee
    @current_attendee ||= Attendee.find_by(id: session[:attendee_id]) if session[:attendee_id]
  end

  def attendee_logged_in?
    current_attendee.present?
  end

  def authenticate_attendee!
    redirect_to attendee_portal_login_path, alert: "Please sign in to access the attendee portal" unless attendee_logged_in?
  end

  def require_login
    unless logged_in?
      flash_warn("You must be logged in to access this section")
      redirect_to root_path and return
    end
  end

  def require_permission!(permission, fallback: root_path, organisation: permission_organisation)
    unless logged_in?
      flash_warn("You must be logged in to access this section")
      redirect_to root_path and return false
    end

    # admins/superadmins always keep global access.
    return true if current_user.admin? || current_user.superadmin?

    # Creating a first organisation is a bootstrap action and should not
    # require pre-existing organisation role assignments.
    return true if permission == "organisation-create"

    return true if has_permission?(permission, organisation: organisation)

    redirect_to fallback, alert: "You do not have permission to perform this action."
    false
  end

  def has_permission?(permission, organisation: nil)
    scope = current_user.organisation_roles
                        .joins(:role_permissions)
                        .where(role_permissions: { permission: permission })

    scope = scope.where(organisation_id: organisation.id) if organisation.present?
    return true if scope.exists?

    return true if has_member_fallback_permission?(permission, organisation)

    has_inherited_parent_permission?(permission, organisation)
  end

  def has_member_fallback_permission?(permission, organisation)
    return false unless organisation.present?
    return false unless organisation.users.where(id: current_user.id).exists?

    # signing user is expected to have full access, even if role rows are
    # temporarily stale.
    return true if organisation.signing_user_id == current_user.id

    member_role = OrganisationRole.find_by(organisation: organisation, name: "Member")
    return false unless member_role

    member_role.role_permissions.where(permission: permission).exists?
  end

  def has_inherited_parent_permission?(permission, organisation)
    return false unless organisation.present?
    return false unless Organisation::PARENT_SUB_TEAM_MEMBER_ALLOWED_PERMISSIONS.include?(permission)

    organisation.sub_teams.joins(:users).where(users: { id: current_user.id }).exists?
  end

  def permission_organisation
    return @organisation if defined?(@organisation) && @organisation.present?
    return Organisation.find_by(id: params[:organisation_id]) if params[:organisation_id].present?

    nil
  end

  def flash_warn(message)
    flash[:alert] = message
  end

  def flash_info(message)
    flash[:notice] = message
  end
end
