module Events
  class AttendeesController < EventsController
    # These actions are used by the organisation-scoped attendee routes (e.g.
    # /org/:organisation_id/events/:id/attendee/:attendee_id).
    #
    # The majority of the behaviour (set_event, set_organisation, etc.) is
    # handled via EventsController, and the views are shared under
    # app/views/organisations/dashboard/events/attendees.

    def attendee
      @attendee = @event.attendees.find(params[:attendee_id])
      render "organisations/dashboard/events/attendees/attendee"
    end

    def edit_attendee
      @attendee = @event.attendees.find(params[:attendee_id])
      render "organisations/dashboard/events/attendees/edit_attendee"
    end

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

    def attendee_waiver
      @attendee = @event.attendees.find(params[:attendee_id])
      render "organisations/dashboard/events/attendees/waiver/attendee_waiver"
    end

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
  end
end
