class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # tests make requests without a real browser UA, so disable the check there.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :current_attendee, :attendee_logged_in?

  before_action :load_placeholder_user

  def load_placeholder_user
    @nil_user ||= User.find_or_create_by!(provider: "placeholder", uid: "nil") do |user|
      user.name               = "Nil User"
      user.email              = "nil@example.com"
      user.role               = "member"
      user.organisation_role  = "member"
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

  def flash_warn(message)
    flash[:alert] = message
  end

  def flash_info(message)
    flash[:notice] = message
  end
end
