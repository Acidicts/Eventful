module Organisations
  class SettingsController < ApplicationController
    before_action :set_organisation

    def index
    end

    def customisations
    end

    def events_defaults
    end

    def members
    end

    def roles
    end

    def customisations_save
      if @organisation.update(organisation_params)
        redirect_to settings_customisations_organisation_path(@organisation), notice: "Customisations updated successfully."
      else
        flash.now[:alert] = "Failed to update customisations. Please check the form for errors."
        render :customisations
      end
    end

    def default_events_save
      if @organisation.update(organisation_params)
        redirect_to settings_events_defaults_organisation_path(@organisation), notice: "Default event settings updated successfully."
      else
        flash.now[:alert] = "Failed to update default event settings. Please check the form for errors."
        render :events_defaults
      end
    end

    private

    def set_organisation
      @organisation = current_user.organisations.find(params[:id])
    end

    def organisation_params
      params.require(:organisation).permit(
        :name,
        :description,
        :default_event_title,
        :img,
        :default_event_description,
        :default_event_location,
        :default_event_start_time,
        :default_event_end_time,
        :default_event_length
      )
    end
  end
end
