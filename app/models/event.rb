class Event < ApplicationRecord
  belongs_to :attendee
  belongs_to :organisation
end
