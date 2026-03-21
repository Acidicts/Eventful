class EventMailer < ApplicationMailer
  def event_finished_email
    @event = params[:event]
    @user = params[:user]
    @gallery_url = app_base_url + "/" + attendee_portal_gallery_url.to_s.split("/").last(2).join("/") + "?" + "code=" + @user.code.to_s

    mail(
      to: @user.email,
      subject: "Event Finished: #{@event.name}",
      template_path: "mailers/event",
      template_name: "ended",
      message_id: "<login-otp-#{@user.id}-#{SecureRandom.uuid}@eventful.mail>",
      "X-Entity-Ref-ID" => "login-otp-#{@user.id}-#{SecureRandom.uuid}"
    )
  end
end
