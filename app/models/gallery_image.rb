class GalleryImage < ApplicationRecord
  belongs_to :attendee
  belongs_to :gallery
end
