class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

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

  def require_login
    unless logged_in?
      flash_warn("You must be logged in to access this section")
      redirect_to root_path and return
    end
  end

  def flash_warn(message)
    flash[:alert] = message
  end
end
