class OrganisationsController < ApplicationController
  before_action :set_organisation, only: %i[show edit update destroy]
  before_action :require_login

  def index
    redirect_to root_path, notice: "Organisations are not publicly listed. Please log in to view your organisations." unless current_user.admin?
    @organisations = Organisation.all
  end

  def show
  end

  def new
    @organisation = Organisation.new
    @users = User.all
  end

  def create
    @organisation = Organisation.new(organisation_params)
    if @organisation.save
      redirect_to @organisation, notice: "Organisation was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.all
  end

  def update
    if @organisation.update(organisation_params)
      redirect_to @organisation, notice: "Organisation was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @organisation.destroy
    redirect_to organisations_url, notice: "Organisation was successfully destroyed."
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:id])
  end

  def organisation_params
    # permit the new signing_user_id along with the existing fields
    params.require(:organisation).permit(:user_id, :events_id, :signing_user_id)
  end
end
