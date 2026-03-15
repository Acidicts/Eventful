class SessionsController < ApplicationController
  # omniauth callback typically comes as a GET, which doesn't include a CSRF token
  skip_before_action :verify_authenticity_token, only: [ :create, :failure ]

  def new_email
  end

  def create_email
    email = params[:email].to_s.strip.downcase
    if email.blank?
      redirect_to login_path, alert: "Enter a valid email address."
      return
    end

    user = User.find_or_create_by!(provider: "email", uid: email) do |u|
      u.email = email
      u.name = email.split("@", 2).first.to_s.titleize
      u.role = "member"
      u.organisation_role = "member"
    end
    if EmailLoginOtp.where(user: user).any?
      EmailLoginOtp.where(user: user).update_all(used_at: Time.current)
    end
    otp = user.email_login_otps.create!
    LoginMailer.otp_login(user, otp).deliver_later

    flash[:notice] = "Check your email for a one‑time sign‑in code."

    # Keep the user on the current page and open the sign-in menu in verification mode.
    referer = request.referer || root_path
    uri = URI.parse(referer)
    query = Rack::Utils.parse_nested_query(uri.query).merge("login_stage" => "verify", "email" => email)
    uri.query = query.to_query

    redirect_to uri.to_s
  end

  def verify_email
    @token = params[:token]

    if @token.present?
      otp = EmailLoginOtp.active.find_by(token: @token)
      if otp
        sign_in_user(otp)
        return
      end

      flash.now[:alert] = "Invalid or expired sign‑in link."
    end
  end

  def confirm_email
    @token = params[:token]
    @code = params[:code]
    email = params[:email].to_s.strip.downcase

    otp = if @token.present?
      EmailLoginOtp.active.find_by(token: @token)
    elsif @code.present? && email.present?
      user = User.find_by(provider: "email", uid: email)
      user&.email_login_otps&.active&.find_by(code: @code)
    end

    if otp
      sign_in_user(otp)
    else
      flash[:alert] = "Invalid or expired code. Please try again."

      referer = request.referer || root_path
      uri = URI.parse(referer)
      query = Rack::Utils.parse_nested_query(uri.query).merge("login_stage" => "verify", "email" => email)
      uri.query = query.to_query

      redirect_to uri.to_s
    end
  end

  def create
    auth = request.env["omniauth.auth"]
    unless auth.present?
      redirect_to root_path, alert: "Sign in failed. Please try again."
      return
    end

    user = User.from_omniauth(auth)
    session[:user_id] = user.id
    # Run any auto‑add rules for organisations that have join requirements.
    # `auto_add_users` is a no-op for organisations with a nil/blank join_requirements.
    orgs = Organisation.where.not(join_requirements: [ nil, "" ])
    orgs.find_each do |org|
      org.auto_add_users
    end
    redirect_to root_path, notice: "Signed in successfully"
  end

  def failure
    error_message = params[:message].presence || "unknown_error"
    provider = params[:strategy].presence || "provider"
    session.delete(:user_id)

    redirect_to root_path, alert: "Sign in with #{provider.humanize} failed (#{error_message.humanize}). Please try again."
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out"
  end

  private

  def sign_in_user(otp)
    otp.consume!
    session[:user_id] = otp.user.id
    redirect_to root_path, notice: "Signed in successfully"
  end
end
