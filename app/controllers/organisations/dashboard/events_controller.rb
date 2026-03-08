module Organisations
  module Dashboard
    class EventsController < ApplicationController
      before_action :require_login
      before_action :set_organisation

      # GET /org/:id/dashboard/events
      def index
        @events = @organisation.events
      end

      def attendees
        # fetch every attendee belonging to this organisation (across events)
        @attendees = @organisation.attendees
      end

      private

      def set_organisation
        @organisation = Organisation.find(params[:id])
      end
    end
  end
end
