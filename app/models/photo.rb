class Photo < ApplicationRecord
  belongs_to :event
  belongs_to :attendee

  has_one_attached :image
end
