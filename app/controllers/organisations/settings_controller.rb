module Organisations
  class SettingsController < ApplicationController
    layout "org_settings"

    before_action :require_login
    before_action :set_organisation
    before_action -> { require_permission!("organisation-settings-view", fallback: organisation_path(@organisation), organisation: @organisation) }, only: %i[index]
    before_action -> { require_permission!("organisation-settings-customisations", fallback: settings_organisation_path(@organisation), organisation: @organisation) }, only: %i[customisations customisations_save]
    before_action -> { require_permission!("organisation-settings-events-defaults", fallback: settings_organisation_path(@organisation), organisation: @organisation) }, only: %i[events_defaults default_events_save]
    before_action -> { require_permission!("organisation-settings-members", fallback: settings_organisation_path(@organisation), organisation: @organisation) }, only: %i[members update_member]
    before_action -> { require_permission!("organisation-settings-roles", fallback: settings_organisation_path(@organisation), organisation: @organisation) }, only: %i[roles]
    before_action -> { require_permission!("organisation-settings-branding", fallback: settings_organisation_path(@organisation), organisation: @organisation) }, only: %i[custom_branding custom_branding_save]

    def index
    end

    def customisations
    end

    def events_defaults
    end

    def custom_branding
    end

    def members
      @organisation_roles = @organisation.organisation_roles
    end

    def update_member
      member_attrs = params.require(:member).permit(:user_id, :organisation_role)
      user = User.find(member_attrs[:user_id])

      unless [ "Signing User", "Member" ].include?(member_attrs[:organisation_role])
        redirect_to settings_members_organisation_path(@organisation), alert: "Unknown role selection." and return
      end

      if member_attrs[:organisation_role] == "Member" && @organisation.signing_user == user
        redirect_to settings_members_organisation_path(@organisation), alert: "Cannot demote the signing user. Please choose a different signing user first." and return
      end

      Organisation.transaction do
        @organisation.users << user unless @organisation.users.exists?(user.id)

        if member_attrs[:organisation_role] == "Signing User"
          @organisation.update!(signing_user: user)
        end

        @organisation.give_all_users_roles
      end

      notice = member_attrs[:organisation_role] == "Signing User" ? "Signing user updated." : "Member role updated."
      redirect_to settings_members_organisation_path(@organisation), notice: notice
    rescue ActiveRecord::RecordInvalid => e
      redirect_to settings_members_organisation_path(@organisation), alert: e.record.errors.full_messages.to_sentence.presence || "Failed to update member role."
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

    def custom_branding_save
      if @organisation.update(organisation_params)
        redirect_to settings_custom_branding_organisation_path(@organisation), notice: "Custom branding updated successfully."
      else
        flash.now[:alert] = "Failed to update custom branding. Please check the form for errors."
        render :custom_branding
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
      @organisation = Organisation.find(params[:id])
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
        :default_event_length,
        :primary_color,
        :secondary_color,
        :default_online_event_url
      )
    end
  end
end
