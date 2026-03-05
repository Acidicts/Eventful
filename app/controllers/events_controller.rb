class EventsController < ApplicationController
  # only look up an organisation when the request is scoped to one
  before_action :set_organisation, if: -> { params[:organisation_id].present? }
  # make sure we load @event for the member actions too (nested only)
  before_action :set_event, only: %i[show edit update destroy sign_in sign_out get_info attendees], if: -> { params[:organisation_id].present? }

  def index
    # top‑level /events should show every event; nested route shows org-specific
    if @organisation
      @events = @organisation.events
    else
      @events = Event.all
    end
  end

  def show
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
  end

  def sign_out
    # TODO: implement sign-out logic
  end

  def get_info
    # TODO: implement info retrieval logic
  end

  def attendees
    # display a list of attendees for this event
    @attendees = @event.attendees if @event.respond_to?(:attendees)
  end

  private

  def set_organisation
    @organisation = Organisation.find(params[:organisation_id])
  end

  def set_event
    @event = @organisation.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :description, :capacity, :applied, :attendee_id)
  end
end
