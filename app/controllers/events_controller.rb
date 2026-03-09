class EventsController < ApplicationController
  # only look up an organisation when the request is scoped to one
  before_action :set_organisation, if: -> { params[:organisation_id].present? }
  # make sure we load @event for the member actions too (nested only)
  before_action :set_event, only: %i[show edit update destroy sign_in sign_out get_info attendees apply apply_create attendee edit_attendee update_attendee], if: -> { params[:organisation_id].present? }

  def index
    # events are only accessible via an organisation context. if somehow we
    # end up here without one, redirect back to root to avoid exposing a
    # standalone list.
    unless @organisation
      redirect_to root_path, alert: "Organisation required to view events" and return
    end

    @events = @organisation.events
    # reuse existing dashboard view
    render "organisations/dashboard/events/index"
  end

  def show
    # show view now lives under the organisation dashboard namespace
    render "organisations/dashboard/events/show"
  end

  def new
    @event = @organisation.events.build
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
    render "organisations/dashboard/events/sign_in"
  end

  def sign_out
    # TODO: implement sign-out logic
    render "organisations/dashboard/events/sign_out"
  end

  def get_info
    # TODO: implement info retrieval logic
    render "organisations/dashboard/events/get_info"
  end

  def attendees
    # return all attendee records associated with the event; once the
    # migration has run this will be a normal has_many query.
    @attendees = @event.attendees
    render "organisations/dashboard/events/attendees"
  end

  # GET /org/:org_id/events/:id/apply
  def apply
    # prepare a fresh attendee instance for form builder
    @attendee = @event.attendees.build
    render "organisations/dashboard/events/apply"
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
    # belong to events. only keep the remaining scalar columns.
    params.require(:event).permit(:name, :description, :capacity, :applied)
  end
end
