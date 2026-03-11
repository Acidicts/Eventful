class AttendeePortalController < ApplicationController
  # every action in this controller should use the attendee_portal layout
  layout "attendee_portal"

  before_action :authenticate_attendee!, only: [ :index, :waiver, :sign_waiver, :update ]

  # GET /attendee_portal/login
  # render a simple code entry form unless already logged in
  def login
    if attendee_logged_in?
      redirect_to attendee_portal_path
    else
      render :login
    end
  end

  # POST /attendee_portal/login
  # look up the attendee by code and set session
  def authenticate
    code = params[:code].to_s.strip
    attendee = Attendee.find_by(code: code)
    if attendee
      session[:attendee_id] = attendee.id
      redirect_to attendee_portal_path
    else
      flash.now[:alert] = "Invalid code"
      render :login, status: :unprocessable_entity
    end
  end

  # DELETE /attendee_portal/logout
  def logout
    session.delete(:attendee_id)
    flash[:notice] = "Signed out of attendee portal"
    redirect_to attendee_portal_login_path
  end

  def index
    @attendee = current_attendee
    @event = @attendee.event
  end

  # GET /attendee-portal/waiver
  def waiver
    @attendee = current_attendee

    @attendee.reload if @attendee
    @event = @attendee.event

    if @attendee.waiver_signed?
      render "attendee_portal/waiver_signed"
    else
      render :waiver
    end
  end

  # PATCH /attendee-portal/waiver
  def sign_waiver
    @attendee = current_attendee
    @event = @attendee.event

    update_attrs = waiver_params.merge(
      waiver_signed: true,
      waiver_signed_at: Time.current
    )

    if @attendee.update(update_attrs)
      # if the user didn’t upload a file but did provide a signature, generate
      # a PDF copy with the name stamped and attach it for record keeping.
      if @attendee.waiver_signature.present? && !params.dig(:attendee, :signed_waiver)
        generated = SignedWaiverGenerator.generate(@attendee)
        if generated
          @attendee.signed_waiver.attach(
            io: generated,
            filename: "waiver-signed-#{@attendee.id}.pdf",
            content_type: "application/pdf"
          )
        end
      end

      flash[:notice] = "Waiver signed, thank you."
      redirect_to attendee_portal_waiver_path
    else
      render :waiver, status: :unprocessable_entity
    end
  end

  def attendee_params
    params.require(:attendee).permit(
      :email,
      :age,
      :diet,
      :other_diet,
      :allergies,
      :waiver_signature,
      :under_18,
      :parent_signature
    )
  end

  def waiver_params
    params.require(:attendee).permit(:waiver_signature, :signed_waiver, :under_18, :parent_signature)
  end

  # PATCH /attendee-portal or /attendee_portal via redirect rules
  # update the currently logged-in attendee's profile and remain on the portal
  def update
    @attendee = current_attendee

    if @attendee.update(attendee_params)
      flash[:notice] = "Profile updated successfully."
      redirect_to attendee_portal_path
    else
      # re‑load event for view template
      @event = @attendee.event
      render :index, status: :unprocessable_entity
    end
  end

  private

  # permit the same fields the portal form allows
  def attendee_params
    params.require(:attendee).permit(:email, :age, :diet, :other_diet, :allergies)
  end
end
