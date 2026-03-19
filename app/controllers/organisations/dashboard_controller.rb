module Organisations
  class DashboardController < ApplicationController
    before_action :require_login
    before_action :set_organisation

    layout "org_dashboard"

    # GET /org/:id/dashboard
    def index
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

      @upcoming_events = @events.where("start_date >= ?", now)
                                .order(start_date: :asc)
                                .limit(5)
      @recent_attendees = @attendee_scope.includes(:event)
                                         .order(created_at: :desc)
                                         .limit(8)
    end

    private

    def set_organisation
      @organisation = Organisation.find(params[:id])
    end
  end
end
