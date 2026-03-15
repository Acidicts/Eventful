class AttendeeMailer < ApplicationMailer
  # send a QR code to the attendee's email address.  the QR encodes a
  # link back to the attendee's own record, which will ultimately be used
  # by organisers during the check‑in flow.  embedding the code as an SVG
  # keeps the message lightweight and immediately visible in most mail
  # clients.
  def qr_code(attendee)
    @attendee = attendee
    @event = attendee.event

    # build an absolute URL that the QR scanner can hit.  the named helper
    # includes `attendee_id` as a query parameter so we mirror that here.
    @url = @attendee.code.to_s

    # also expose a simple endpoint that renders just the QR code image; this is
    # consumed by some clients that prefer a stable URL rather than embedded
    # data.  the path is expected to be `/qrcode/:code` on the public app host.
    base = ENV.fetch("APP_URL")
    @qr_page = base + "/attendee_portal?code=" + @attendee.code.to_s

    # generate a PNG and attach it inline so mail clients that strip out
    # data URIs can still display the image.  we keep the base64 logic in the
    # service but strip off the prefix and decode to raw bytes for the
    # attachment.
    png_uri = QrCodeGenerator.generate(@url, format: :png, size: 300)
    png_data = png_uri.sub(%r{\Adata:image/png;base64,}, "")
    attachments.inline["qr.png"] = Base64.decode64(png_data)
    # the view will reference this attachment via its `cid:` URL
    @qr_png_cid = attachments["qr.png"].url

    mail(
      to: @attendee.email,
      subject: "Your QR code for #{@event.name || 'the event'}",
      in_reply_to: nil,
      references: nil,
      message_id: "<attendee-qr-#{@attendee.id}-#{SecureRandom.uuid}@eventful.mail>",
      "X-Entity-Ref-ID" => "attendee-qr-#{@attendee.id}-#{SecureRandom.uuid}"
    )
  end
end
