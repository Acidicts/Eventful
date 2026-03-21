class AdminController < ApplicationController
  layout "admin"

  before_action :authenticate_user!
  before_action -> { require_permission!("admin-access", fallback: root_path, organisation: nil) }
  before_action :require_admin
  before_action :set_organisation_application, only: [ :approve_application, :reject_application ]

  def index
    @audit_logs = AuditLog.includes(:user).order(created_at: :desc).limit(100)
  end

  def approvals
    @organisation_applications = OrganisationApplication.includes(:user).order(created_at: :desc)
  end

  def approve_application
    application_user = @organisation_application.user

    organisation = Organisation.new(
      name: @organisation_application.name.presence || "New Organisation",
      user: application_user,
      signing_user: application_user,
      self_found: true
    )

    if organisation.save
      @organisation_application.destroy
      redirect_to admin_applications_path, notice: "Application approved and organisation created."
    else
      redirect_to admin_applications_path, alert: "Could not approve application: #{organisation.errors.full_messages.to_sentence}"
    end
  end

  def reject_application
    @organisation_application.destroy
    redirect_to admin_applications_path, notice: "Application rejected."
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

  def set_organisation_application
    @organisation_application = OrganisationApplication.find(params[:id])
  end
end
