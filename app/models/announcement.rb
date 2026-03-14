class Announcement < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to :event, optional: true
  belongs_to :organisation

  attribute :content, :string, default: ""
  attribute :public, :boolean, default: false
end
