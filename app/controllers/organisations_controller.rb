class OrganisationsController < ApplicationController
  before_action :set_organisation, only: %i[show join favorite edit update destroy]
  before_action :set_hierarchy_options, only: %i[new create edit update]
  before_action :require_login, except: %i[show]
  before_action -> { require_permission!("organisation-create", fallback: organisations_path, organisation: nil) }, only: %i[new create]
  before_action -> { require_permission!("organisation-update", fallback: organisation_path(@organisation), organisation: @organisation) }, only: %i[edit update]
  before_action -> { require_permission!("organisation-destroy", fallback: organisation_path(@organisation), organisation: @organisation) }, only: %i[destroy]
  before_action -> { require_permission!("organisation-favorite", fallback: organisation_path(@organisation), organisation: @organisation) }, only: %i[favorite]

  def index
    if current_user.admin? || current_user.superadmin?
      @organisations = Organisation.where(nil_org: false, parent_org_id: nil).order(:name)
      render "organisations/admin/index"
    else
      # include top-level organisations the user belongs to directly, plus
      # parent organisations of teams the user belongs to.
      user_org_ids = Organisation.for_user(current_user).select(:id)
      parent_org_ids = Organisation.for_user(current_user).where.not(parent_org_id: nil).select(:parent_org_id)
      legacy_parent_org_ids = Organisation.where(child_org_id: user_org_ids).select(:id)

      visible_top_level_ids = Organisation.where(id: user_org_ids)
                                          .or(Organisation.where(id: parent_org_ids))
                                          .or(Organisation.where(id: legacy_parent_org_ids))
                                          .select(:id)

      @organisations = Organisation.where(nil_org: false, parent_org_id: nil, id: visible_top_level_ids)
                                   .order(:name)
      render "index"
    end
  end

  def attendees
    @attendees = Attendee.joins(:event).where(events: { organisation_id: @organisation.id })
  end

  def show
    @top_organisation = resolve_top_organisation(@organisation) || @organisation
    @menu_organisations = @top_organisation.child_teams
                                          .where(nil_org: false)
                                          .order(:name)

    @events = @organisation.events.order(start_date: :asc)
    @event_count = @events.count
    @attendee_scope = Attendee.joins(:event).where(events: { organisation_id: @organisation.id })
    @attendee_count = @attendee_scope.count

    now = Time.current
    @active_events_count = @events.where(finished: false)
                                .where("start_date <= :now AND (end_date IS NULL OR end_date >= :now)", now: now)
                                .count
    @upcoming_events_count = @events.where("start_date > ?", now).count
    @recent_events_count = @events.where("created_at >= ?", 30.days.ago).count

    @total_capacity = @events.sum(:capacity)
    @available_spots = [ @total_capacity - @attendee_count, 0 ].max

    @waiver_signed_count = @attendee_scope.where(waiver_signed: true).count
    @signed_in_count = @attendee_scope.where(attendance: Attendee.attendances[:signed_in]).count
    @signed_out_count = @attendee_scope.where(attendance: Attendee.attendances[:signed_out]).count

    @upcoming_events = Event.where(organisation_id: @organisation.id)
                            .where(finished: false)
                            .order(start_date: :asc)
                            .limit(5)
    #
    if logged_in? && (current_user.admin? || @organisation.users.include?(current_user) || @organisation.sub_teams.joins(:users).where(users: { id: current_user.id }).exists?)
      redirect_to dashboard_organisation_path(@organisation)
    else
      render "organisations/public/show"
    end
  end

  def join
    parent = @organisation.parent_team

    can_join = current_user.admin? || current_user.superadmin? ||
      (parent.present? && has_permission?("organisation-join-team-sub-team", organisation: parent))

    if can_join
      @organisation.users << current_user unless @organisation.users.include?(current_user)
      redirect_to dashboard_organisation_path(@organisation), notice: "You have joined #{@organisation.name}."
      return
    end

    redirect_to root_path, alert: "You do not have permission to join this team."
  end

  def settings
  end

  def public
    render "organisations/public/index"
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

  def favorite
    return unless logged_in? && @organisation.users.include?(current_user)

    if request.delete?
      current_user.update(favorite_org: nil)
      flash[:notice] = "Favorite organisation removed."
    else
      current_user.update(favorite_org: @organisation)
      flash[:notice] = "Favorite organisation set to #{@organisation.name}."
    end

    redirect_back fallback_location: organisations_path
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
    # shown in the `create` action above.  the form now also accepts a
    # few optional metadata fields (name, description, image URL and a
    # boolean flag) so permit them here as well.
    params.require(:organisation).permit(
      :user_id,
      :signing_user_id,
      :parent_org_id,
      :child_org_id,
      :name,
      :description,
      :img,
      :self_found
    )
  end

  def set_hierarchy_options
    current_id = @organisation&.id
    @organisation_options = Organisation.where(nil_org: false)
                                        .where.not(id: current_id)
                                        .order(:name)
  end

  def resolve_top_organisation(organisation)
    current = organisation
    visited_ids = []

    while current.parent_team.present? && !visited_ids.include?(current.id)
      visited_ids << current.id
      current = current.parent_team
    end

    current
  end
end
