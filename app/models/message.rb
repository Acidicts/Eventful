class Message < ApplicationRecord
  belongs_to :sender
  belongs_to :reciever

  attribute :message, :string
  attribute :answer, :string

  attribute :read, :boolean, default: false
end
