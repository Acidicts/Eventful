class Gallery < ApplicationRecord
  belongs_to :organisation
  has_many :gallery_images, dependent: :destroy
end
