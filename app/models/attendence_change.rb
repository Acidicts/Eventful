class AttendenceChange < ApplicationRecord
  belongs_to :attendee

  alias_attribute :attendance, :attendence

  enum :attendance, { pending: 0, signed_in: 1, signed_out: 2, no_show: 3 }, prefix: true

  after_create_commit -> { broadcast_prepend_to "event_#{attendee.event_id}_stats",
                          target: "recent_changes",
                          partial: "organisations/dashboard/events/attendence_change" }
end
