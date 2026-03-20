class RolesController < ApplicationController
  before_action :set_organisation
  before_action :set_permissions, only: %i[new edit]
  before_action :set_role, only: %i[edit update destroy]
  before_action :require_login
  before_action -> { require_permission!("role-create", fallback: settings_roles_organisation_path(@organisation), organisation: @organisation) }, only: %i[new create]
  before_action -> { require_permission!("role-update", fallback: settings_roles_organisation_path(@organisation), organisation: @organisation) }, only: %i[edit update]
  before_action -> { require_permission!("role-destroy", fallback: settings_roles_organisation_path(@organisation), organisation: @organisation) }, only: %i[destroy]

  def new
    if params[:existing_role_id].present?
      existing_role = find_source_role(params[:existing_role_id], params[:template_source])

      unless existing_role
        redirect_to settings_roles_organisation_path(@organisation), alert: "Selected role template could not be found."
        return
      end

      @role = @organisation.organisation_roles.build(
        name: "#{existing_role.name} Copy",
        role_permission_ids: existing_role.role_permission_ids
      )
    else
      @role = @organisation.organisation_roles.build
    end
  end

  def select_template
    current_path = request.path
    if current_path.include?("from-existing")
      @template_source = "existing"
      @existing_roles = @organisation.organisation_roles
    elsif current_path.include?("from-template")
      @template_source = "template"
      nil_org = Organisation.find_by(name: "Nil Organisation")
      @existing_roles = nil_org ? OrganisationRole.where(organisation_id: nil_org.id) : OrganisationRole.none
    else
      redirect_to settings_roles_organisation_path(@organisation), alert: "Invalid role template selection."
    end
  end

  def create
    @role = @organisation.organisation_roles.build(role_params)

    if @role.save
      redirect_to settings_roles_organisation_path(@organisation), notice: "Role created."
    else
      flash.now[:alert] = "Failed to create role."
      render :new
    end
  end

  def edit
  end

  def update
    if @role.update(role_params)
      redirect_to settings_roles_organisation_path(@organisation), notice: "Role updated."
    else
      flash.now[:alert] = "Failed to update role."
      render :edit
    end
  end

  def destroy
    @role.destroy
    redirect_to settings_roles_organisation_path(@organisation), notice: "Role deleted."
  end

  private

  def set_permissions
    @permissions = RolePermission.order(:permission)
  end

  def set_organisation
    @organisation = Organisation.find(params[:id])
  end

  def set_role
    @role = @organisation.organisation_roles.find(params[:role_id])
  end

  def role_params
    params.require(:organisation_role).permit(:name, :is_default_role, role_permission_ids: [])
  end

  def find_source_role(role_id, template_source)
    case template_source
    when "template"
      nil_org = Organisation.find_by(name: "Nil Organisation")
      return nil unless nil_org

      OrganisationRole.find_by(id: role_id, organisation_id: nil_org.id)
    else
      @organisation.organisation_roles.find_by(id: role_id)
    end
  end
end
