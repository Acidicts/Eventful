# service for producing a signed copy of the event waiver with the attendee's
# name stamped onto it. used when the user simply types their name rather than
# uploading an existing signed file.

require "combine_pdf"
require "prawn"

class SignedWaiverGenerator
  class << self
    # @param attendee [Attendee]
    # @return [StringIO] PDF data ready to attach
    def generate(attendee)
      return unless attendee.event&.waiver&.attached?
      return unless attendee.waiver_signature.present?

      # load original waiver
      original_data = attendee.event.waiver.download
      pdf = CombinePDF.parse(original_data)

      # create an overlay containing the signature text at bottom of first page
      overlay = Prawn::Document.new(page_size: pdf.pages.first.page_size) do
        font "Helvetica", size: 12
        # determine text based on age status
        if attendee.under_18? && attendee.parent_signature.present?
          text = "Parent signed: #{attendee.parent_signature} (participant: #{attendee.waiver_signature})"
        else
          text = "Signed by: #{attendee.waiver_signature}"
        end
        # place centered near bottom margin
        text_width = width_of(text)
        x = (bounds.width - text_width) / 2
        y = bounds.bottom + 20
        draw_text text, at: [ x, y ]
      end
      overlay_pdf = CombinePDF.parse(overlay.render)

      # stamp overlay on every page (or just first, keep simple)
      pdf.pages.each do |page|
        page << overlay_pdf.pages.first
      end

      StringIO.new(pdf.to_pdf)
    end
  end
end
