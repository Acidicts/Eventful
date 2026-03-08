module Organisations
  class DashboardController < ApplicationController
    before_action :require_login
    before_action :set_organisation

    # GET /org/:id/dashboard
    def index
      # @organisation is already loaded by set_organisation before_action
    end

    private

    def set_organisation
      @organisation = Organisation.find(params[:id])
    end
  end
end
