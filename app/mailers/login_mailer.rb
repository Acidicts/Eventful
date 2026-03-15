class LoginMailer < ApplicationMailer
  def otp_login(user, otp)
    @user = user
    @otp = otp

    # token link for one-click sign-in (use APP_URL so it isn't bound to localhost)
    app_base = ENV.fetch("APP_URL") { Rails.application.routes.default_url_options[:host] }
    app_uri = URI.parse(app_base)

    @login_url = Rails.application.routes.url_helpers.login_verify_url(
      token: otp.token,
      host: app_uri.host,
      port: (app_uri.port if app_uri.port && app_uri.port != app_uri.default_port),
      protocol: app_uri.scheme
    )

    mail(
      to: @user.email,
      subject: "Your sign-in code for Eventful",
      in_reply_to: nil,
      references: nil,
      message_id: "<login-otp-#{@user.id}-#{SecureRandom.uuid}@eventful.mail>",
      "X-Entity-Ref-ID" => "login-otp-#{@user.id}-#{SecureRandom.uuid}"
    )
  end
end
