class OrganisationsController < ApplicationController
  before_action :set_organisation, only: %i[show edit update destroy]
  before_action :require_login

  def index
    if params[:user_id] && current_user.admin?
      @organisations = Organisation.where(user_id: params[:user_id])
    elsif params[:all].present? && current_user.admin?
      @organisations = Organisation.all
    else
      # fall back to organisations the current user owns or belongs to
      # `current_user.organisations` returns those they own; membership is
      # tracked via `user.organisation_id`, so we also include their own org
      # when set.
      owned = current_user.organisations
      member = Organisation.where(id: current_user.organisation_id) if current_user.organisation_id
      @organisations = (owned + Array(member)).uniq
    end
  end

  def show
  end

  def setting
  end

  def new
    @organisation = Organisation.new
    # for new organisations we already filter out elevated accounts
    @users = User.where.not(role: :admin).where.not(role: :superadmin)
  end

  def create
    # assign ownership to the currently authenticated user.  the form no
    # longer exposes `user_id` directly, but permitting it keeps the
    # parameters list flexible for administrators who might later need to
    # transfer ownership.
    @organisation = Organisation.new(organisation_params)
    @organisation.user ||= current_user
    @organisation.users << current_user unless @organisation.users.include?(current_user)

    if @organisation.save
      redirect_to @organisation, notice: "Organisation was successfully created."
    else
      # need the same user list as the `new` action so the form dropdown
      # can render properly when validation fails.
      @users = User.where.not(role: :admin).where.not(role: :superadmin)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # only regular users should be selectable as signing users; exclude
    # admins and superadmins just like the `new` action does.  this removes
    # the unwanted superadmin from the dropdown.
    @users = User.where.not(role: :admin).where.not(role: :superadmin)
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
    # `user_id` is permitted for flexibility (admins can manually set it),
    # but in the normal flow it will be populated from `current_user` as
    # shown in the `create` action above.  events are now associated via the
    # `has_many :events` side of the relationship, so there is no longer any
    # database constraint on an organisation requiring an event.
    params.require(:organisation).permit(:user_id, :signing_user_id)
  end
end
