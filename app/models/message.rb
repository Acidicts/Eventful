class Message < ApplicationRecord
  # sender is always an attendee, but the receiver can either be another
  # attendee or the event organiser (a User). switch to polymorphic
  # association so both are supported.
  belongs_to :sender, class_name: "Attendee"
  belongs_to :reciever, polymorphic: true

  # optional reference to the user who answered the message (e.g. event
  # organiser or staff).  nullable so old rows remain valid.
  belongs_to :answerer, class_name: "User", optional: true

  attribute :message, :string
  alias_attribute :content, :message

  attribute :answer, :string

  attribute :read, :boolean, default: false
end
