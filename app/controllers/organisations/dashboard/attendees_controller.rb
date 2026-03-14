module Organisations
  module Dashboard
    class AttendeesController < ApplicationController
      before_action :require_login
      before_action :set_organisation

      # GET /org/:id/dashboard/attendees
      def index
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
