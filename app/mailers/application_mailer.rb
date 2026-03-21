class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_EMAIL") { "eventful@bing-bong.uk" }
  layout "mailer"

  private

  def app_base_url
    env_base = ENV["APP_URL"].to_s.strip
    return env_base if env_base.present?

    options = Rails.application.routes.default_url_options
    host = options[:host].to_s.strip
    protocol = options[:protocol].presence || "https"
    return "#{protocol}://#{host}" if host.present?

    "http://localhost:3000"
  end
end
