class EventsController < ApplicationController
  # only look up an organisation when the request is scoped to one
  before_action :set_organisation, if: -> { params[:organisation_id].present? }
  before_action :require_login, except: %i[show announcements apply apply_create apply_by_token]
  # make sure we load @event for the member actions too (nested only)
  before_action :set_event, only: %i[show edit update destroy sign_in sign_out get_info attendees apply apply_create attendee edit_attendee update_attendee scan attendee_waiver destroy_attendee_waiver], if: -> { params[:organisation_id].present? }
  before_action -> { require_permission!("event-view", fallback: root_path, organisation: @organisation) }, only: %i[index]
  before_action -> { require_permission!("event-create", fallback: organisation_events_path(@organisation), organisation: @organisation) }, only: %i[new create]
  before_action -> { require_permission!("event-update", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[edit update]
  before_action -> { require_permission!("event-destroy", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[destroy]
  before_action -> { require_permission!("event-attendees-view", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[attendees]
  before_action -> { require_permission!("event-attendee-view", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[attendee]
  before_action -> { require_permission!("event-attendee-edit", fallback: attendee_organisation_event_path(@organisation, @event, attendee_id: params[:attendee_id]), organisation: @organisation) }, only: %i[edit_attendee]
  before_action -> { require_permission!("event-attendee-update", fallback: attendee_organisation_event_path(@organisation, @event, attendee_id: params[:attendee_id]), organisation: @organisation) }, only: %i[update_attendee]
  before_action -> { require_permission!("event-attendee-waiver-view", fallback: attendee_organisation_event_path(@organisation, @event, attendee_id: params[:attendee_id]), organisation: @organisation) }, only: %i[attendee_waiver]
  before_action -> { require_permission!("event-attendee-waiver-destroy", fallback: attendee_organisation_event_path(@organisation, @event, attendee_id: params[:attendee_id]), organisation: @organisation) }, only: %i[destroy_attendee_waiver]
  before_action -> { require_permission!("event-sign-in", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[sign_in]
  before_action -> { require_permission!("event-sign-out", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[sign_out]
  before_action -> { require_permission!("event-get-info", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[get_info]
  before_action -> { require_permission!("event-scan", fallback: organisation_event_path(@organisation, @event), organisation: @organisation) }, only: %i[scan]

  def index
    if request.path == "/events"
      @events = Event.where(organiser_id: current_user.id).or(Event.where(organisation_id: current_user.user_organisations.select(:id)))
      render "events/index"
    else
      unless @organisation
        redirect_to root_path, alert: "Organisation required to view events" and return
      end

      @events = @organisation.events
      # reuse existing dashboard view
      render "organisations/dashboard/events/index"
    end
  end

  def show
    @event.finish_if_ended!

    if logged_in? && (current_user.admin? || current_user.superadmin? || has_permission?("event-view", organisation: @event.organisation))
      render "organisations/dashboard/events/show"
    else
      render "events/pub/show"
    end
  end

  def announcements
    @announcements = @event.announcements.where(public: true).order(created_at: :desc)
    render "events/announcements/show"
  end

  def new
    @event = @organisation.events.build

    # `default_event_start_time` and `default_event_end_time` are stored as
    # `time` columns (which Rails returns as a Time/TimeWithZone with a fixed
    # date). Convert them into offsets from midnight so we can add them to a
    # date without raising `TypeError`.
    start_time_offset = @organisation.default_event_start_time&.seconds_since_midnight
    end_time_offset = @organisation.default_event_end_time&.seconds_since_midnight

    @event.start_date = Date.current.beginning_of_day + start_time_offset if start_time_offset
    @event.end_date = Date.current.beginning_of_day + end_time_offset + @organisation.default_event_length.to_i.days if end_time_offset
    @event.location = @organisation.default_event_location if @organisation.default_event_location
  end

  def create
    @event = @organisation.events.build(event_params)
    if @event.save
      redirect_to [ @organisation, @event ], notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to [ @organisation, @event ], notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to organisation_events_path(@organisation), notice: "Event was successfully destroyed."
  end

  # custom member actions from generator intent
  def sign_in
    # TODO: implement sign-in logic
    render "organisations/dashboard/events/attendees/actions/sign_in"
  end

  def sign_out
    # TODO: implement sign-out logic
    render "organisations/dashboard/events/attendees/actions/sign_out"
  end

  def get_info
    # TODO: implement info retrieval logic
    render "organisations/dashboard/events/attendees/actions/get_info"
  end

  # receive payload from QR scanner frontend and perform whatever checks
  # are required (e.g. look up attendee by code, mark as signed in, etc).
  # the request body will contain JSON `{ "text": "..." }`.
  # keep logic in the controller or push into a service; nothing happens
  # here yet so tests can be written around expected behaviour.
  def scan
    scanned_code = params[:code].presence || params[:text]
    operation = params[:operation]
    message = nil

    if scanned_code.present? && operation.present?
      attendee = @event.attendees.find_by(code: scanned_code)

      if attendee.banned?
        message = "Attendee #{attendee.name} is banned and cannot be proccessed."
        redirect_to attendee_organisation_event_path(@organisation, @event, attendee_id: attendee.id), alert: message and flash_warn("Attendee is banned. Remove from event") and return
      end

      case operation
      when "sign_in"
        if attendee
          if attendee.attendance != "signed_in"
            attendee.update(attendance: :signed_in)
            message = "Attendee #{attendee.name} signed in successfully."
          else
            message = "Attendee #{attendee.name} is already signed in."
          end
        else
          message = "Attendee not found."
        end
      when "sign_out"
        if attendee
          if attendee.attendance == "signed_in"
            attendee.update(attendance: :signed_out)
            message = "Attendee #{attendee.name} signed out successfully."
          else
            message = "Attendee #{attendee.name} is signed out already."
          end
        else
          message = "Attendee not found."
        end
      when "get_info"
        if attendee
          redirect_to attendee_organisation_event_path(@organisation, @event, attendee_id: attendee.id) and return
        else
          message = "Attendee not found."
        end
      else
        head :bad_request and return
      end
    end

    flash[:notice] = message if message.present?
    render json: { message: message }
  end

  def attendees
    # return all attendee records associated with the event; once the
    # migration has run this will be a normal has_many query.
    @attendees = @event.attendees
    render "organisations/dashboard/events/attendees/attendees"
  end

  # GET /org/:org_id/events/:id/apply
  def apply
    # prepare a fresh attendee instance for form builder
    @attendee = @event.attendees.build

    # render the form without the surrounding layout
    render "organisations/dashboard/events/apply", layout: false
  end

  # GET /org/:org_id/events/:id/attendee/:attendee_id/edit
  def edit_attendee
    @attendee = @event.attendees.find(params[:attendee_id])
    render "organisations/dashboard/events/edit_attendee"
  end

  # PATCH /org/:org_id/events/:id/attendee/:attendee_id
  def update_attendee
    @attendee = @event.attendees.find(params[:attendee_id])

    if @attendee.update(attendee_params)
      redirect_to attendee_organisation_event_path(
        @organisation,
        @event,
        attendee_id: @attendee.id
      ), notice: "Attendee updated successfully."
    else
      render "organisations/dashboard/events/edit_attendee", status: :unprocessable_entity
    end
  end

  # GET /:apply_token/apply
  def apply_by_token
    @event = Event.find_by!(apply_token: params[:apply_token])
    @organisation = @event.organisation
    @public_apply = true
    @attendee = @event.attendees.build
    render "organisations/dashboard/events/apply"
  end

  # POST /org/:org_id/events/:id/apply
  # also handles POST /:apply_token/apply because set_event is now invoked
  def apply_create
    # ensure event is available for public-token requests as well
    set_event unless @event

    @attendee = @event.attendees.build(attendee_params)
    # capture remote IP for abuse prevention/validation
    @attendee.ip = request.remote_ip

    if @attendee.save
      # show a thank-you page instead of dumping the user back on the
      # attendee list. the view lives under organisations/dashboard/events
      # to match the namespace used by the dashboard routes but it works for
      # both public and nested flows.
      render "organisations/dashboard/events/thanks", status: :created
    else
      render "organisations/dashboard/events/apply", status: :unprocessable_entity, flash_warn: "There was an error with your application."
    end
  end

  # show an attendee that belongs to this event
  def attendee
    @attendee = @event.attendees.find(params[:attendee_id])
    render "organisations/dashboard/events/attendee"
  end

  # GET /org/:org_id/events/:id/attendee/:attendee_id/waiver
  def attendee_waiver
    @attendee = @event.attendees.find(params[:attendee_id])
    render "organisations/dashboard/events/attendee_waiver"
  end

  # DELETE /org/:org_id/events/:id/attendee/:attendee_id/waiver
  def destroy_attendee_waiver
    @attendee = @event.attendees.find(params[:attendee_id])
    if @attendee.presence
      @attendee.waiver_signature = nil
      @attendee.waiver_signed = false
      @attendee.waiver_signed_at = nil
      if @attendee.signed_waiver.attached?
        @attendee.signed_waiver.purge
        @attendee.update(waiver_signed: false, waiver_signed_at: nil, waiver_signature: nil)
        flash[:notice] = "Signed waiver removed."
      else
        flash[:alert] = "No waiver to delete."
      end
      @attendee.save
    end
    redirect_to attendee_waiver_organisation_event_path(@organisation, @event, attendee_id: @attendee.id)
  end

  private

  def attendee_params
    params.require(:attendee).permit(:name, :age, :email)
  end

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  end

  def set_event
    # allow either numeric id or apply_token to identify the record.  the
    # public apply form sends the token in `params[:apply_token]` rather than
    # `:id`, so treat both as interchangeable when no org is present.
    raw_id = params[:id] || params[:apply_token]

    if @organisation
      @event = if raw_id =~ /\A\d+\z/
                 @organisation.events.find(raw_id)
      else
                 @organisation.events.find_by!(apply_token: raw_id)
      end
    else
      @event = if raw_id =~ /\A\d+\z/
                 Event.find(raw_id)
      else
                 Event.find_by!(apply_token: raw_id)
      end
      # also provide organisation context for helpers/redirects
      @organisation = @event.organisation
    end
  end

  def event_params
    # `attendee_id` has been removed from the events table; attendees now
    # belong to events. only keep the remaining scalar columns. additionally
    # permit a waiver file upload via Active Storage.
    params.require(:event).permit(
      :name,
      :description,
      :capacity,
      :applied,
      :location,
      :start_date,
      :end_date,
      :organiser_id,
      :waiver,
      :icon
    )
  end
end
