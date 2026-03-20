module Organisations
  module Dashboard
    class EventsController < ApplicationController
      before_action :require_login
      before_action :set_organisation
      before_action -> { require_permission!("organisation-dashboard-events-view", fallback: organisation_path(@organisation), organisation: @organisation) }, only: %i[index]
      before_action -> { require_permission!("organisation-dashboard-attendees-view", fallback: dashboard_events_organisation_path(@organisation), organisation: @organisation) }, only: %i[attendees]
      before_action -> { require_permission!("event-send-qr-codes", fallback: dashboard_events_organisation_path(@organisation), organisation: @organisation) }, only: %i[send_qr_codes]

      layout "org_dashboard"

      # GET /org/:id/dashboard/events
      def index
        # `sub_teams` is a CollectionProxy; `events` is not available directly on
        # the collection. Fetch events by joining through organisation id instead.
        sub_team_ids = @organisation.sub_teams.select(:id) + [ @organisation.id ]
        @events = Event.where(organisation_id: sub_team_ids)
                       .joins(:organisation)
      end

      def attendees
        # fetch every attendee belonging to this organisation (across events)
        @attendees = @organisation.attendees
      end

      def send_qr_codes
        # a given event may be looked up by numeric id or by its
        # `apply_token` (the value returned by `to_param`). mirror the logic
        # used in the primary `EventsController#set_event` helper so that the
        # admin dashboard works seamlessly regardless of which form of id is
        # used in the URL.
        @event = if params[:id] =~ /\A\d+\z/
                   @organisation.events.find(params[:id])
        else
                   @organisation.events.find_by!(apply_token: params[:id])
        end

        @event.attendees.each do |attendee|
          AttendeeMailer.qr_code(attendee).deliver_now
        end
        redirect_to organisation_event_path(@organisation, @event), notice: "QR codes are being sent to attendees."
      end

      private

      def set_organisation
        # some routes pass the organisation id as `:id` (dashboard index
        # etc.), others (nested event actions) use `:organisation_id`.
        org_id = params[:organisation_id] || params[:id]
        @organisation = Organisation.find(org_id)
      end
    end
  end
end
