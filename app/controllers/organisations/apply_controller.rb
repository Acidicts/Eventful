module Organisations
  class ApplyController < ApplicationController
    before_action :require_login, only: :create

    def new
      @organisation_application = OrganisationApplication.new
      render :new
    end

    def create
      return redirect_to(root_path, alert: "You must be signed in to submit an application.") unless logged_in?

      @organisation_application = OrganisationApplication.new(organisation_application_params)
      @organisation_application.user = current_user

      if @organisation_application.save
        redirect_to organisations_path, notice: "Application submitted successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def organisation_application_params
      params.require(:organisation_application).permit(:name)
    end
  end
end
