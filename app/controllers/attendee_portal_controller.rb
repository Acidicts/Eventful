class AttendeePortalController < ApplicationController
  # every action in this controller should use the attendee_portal layout
  layout "attendee_portal"

  # if a guest visits the portal URL with a valid attendee code we want to
  # sign them in automatically rather than forcing them to go through the
  # explicit login page.  this before_action runs _before_ the normal
  # authenticate_attendee! filter so that the code is processed first.
  before_action :sign_in_via_code, only: [ :index ]

  # qr_code should only be visible to a logged‑in attendee; add it to the
  # filter list so unauthenticated requests are redirected to login instead of
  # rendering the "not found" placeholder.
  before_action :authenticate_attendee!, only: [ :index, :qr_code, :waiver, :sign_waiver, :update ]

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

  def qr_code
    @attendee = current_attendee

    unless @attendee
      # render a minimal error page (could be styled or localized) and skip
      # application layout so it's easy to embed or print.
      @error_message = "Attendee not found for code #{params[:code]}"
      render "show_not_found", layout: false, status: :not_found and return
    end

    @event = @attendee.event
    @organisation = @event.organisation

    # render a simple QR image containing the attendee’s unique code
    # (not the full link) so that scanners yield the raw code string.
    @qr_svg = QrCodeGenerator.generate(@attendee.code)
    # RQRCode emits fixed width/height on the <svg> root which prevents
    # responsive scaling. Strip only those two attributes from the opening
    # <svg> tag; rect elements must keep their width/height to be visible.
    @qr_svg = @qr_svg.sub(/<svg([^>]*)\s+width="\d+"([^>]*)\s+height="\d+"/, '<svg\1\2')
                     .sub(/<svg([^>]*)\s+height="\d+"([^>]*)\s+width="\d+"/, '<svg\1\2')
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

  # if we were given an attendee code as a query parameter, try to look it up
  # and sign the user in by stashing the ID in the session.  we purposefully
  # do _not_ redirect here; the normal authenticate_attendee! filter will let
  # the request continue once the session has been set.
  def sign_in_via_code
    return if attendee_logged_in? || params[:code].blank?

    code = params[:code].to_s.strip
    if (attendee = Attendee.find_by(code: code))
      session[:attendee_id] = attendee.id
      # do not redirect – let the normal authenticate_attendee! filter run
      # and render whatever action was originally requested (usually index).
    end
  end

  # permit the same fields the portal form allows
  def attendee_params
    params.require(:attendee).permit(:email, :age, :diet, :other_diet, :allergies)
  end
end
