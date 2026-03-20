class AdminController < ApplicationController
  layout "admin"

  before_action :authenticate_user!
  before_action -> { require_permission!("admin-access", fallback: root_path, organisation: nil) }
  before_action :require_admin

  def index
  end

  private

  def require_admin
    unless current_user&.admin?
      flash_warn "You do not have permission to access this page."
      redirect_to root_path
    end
  end

  def authenticate_user!
    redirect_to root_path, alert: "You must sign in first" unless user_signed_in?
  end
end
