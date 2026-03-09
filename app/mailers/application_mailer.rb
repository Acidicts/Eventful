class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_EMAIL") { "eventful@bing-bong.uk" }
  layout "mailer"
end
