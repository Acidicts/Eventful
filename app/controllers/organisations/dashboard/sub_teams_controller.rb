module Organisations
  module Dashboard
    class SubTeamsController < ApplicationController
      before_action :require_login
      before_action :set_organisation
      before_action -> { require_permission!("organisation-dashboard-sub-teams-view", fallback: organisation_path(@organisation), organisation: @organisation) }, only: %i[index]
      before_action -> { require_permission!("organisation-dashboard-sub-teams-create", fallback: dashboard_sub_teams_organisation_path(@organisation), organisation: @organisation) }, only: %i[create]

      layout "org_dashboard"

      # GET /org/:id/dashboard/sub-teams
      def index
        load_hierarchy
        @new_sub_team = build_sub_team
      end

      # POST /org/:id/dashboard/sub-teams
      def create
        @new_sub_team = build_sub_team(sub_team_params)

        if @new_sub_team.save
          redirect_to dashboard_sub_teams_organisation_path(@organisation), notice: "Sub team created successfully."
        else
          load_hierarchy
          render :index, status: :unprocessable_entity
        end
      end

      private

      def set_organisation
        org_id = params[:organisation_id] || params[:id]
        @organisation = Organisation.find(org_id)
      end

      def build_sub_team(attrs = {})
        team = Organisation.new(attrs)
        team.parent_org = @organisation
        team.user ||= current_user
        team.signing_user ||= current_user
        team.users << current_user unless team.users.include?(current_user)
        team
      end

      def sub_team_params
        params.require(:organisation).permit(:name, :description, :img)
      end

      def load_hierarchy
        @parent_team = @organisation.parent_team
        @child_teams = @organisation.child_teams.order(:name)
      end
    end
  end
end
