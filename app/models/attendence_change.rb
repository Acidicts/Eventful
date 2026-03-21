class AttendenceChange < ApplicationRecord
  belongs_to :attendee

  alias_attribute :attendance, :attendence

  enum :attendance, { pending: 0, signed_in: 1, signed_out: 2, no_show: 3 }, prefix: true
end
