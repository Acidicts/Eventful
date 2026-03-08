class Event < ApplicationRecord
  # each event can have many attendees; the foreign key lives on the
  # attendees table. existing data is migrated during a migration.
  has_many :attendees, dependent: :nullify

  belongs_to :organisation

  # public-facing tokens used for applying. we also override `to_param`
  # so URL helpers will emit the token when present.
  before_create :generate_apply_token

  def to_param
    apply_token.presence || id.to_s
  end

  private

  def generate_apply_token
    self.apply_token ||= SecureRandom.alphanumeric(12)
  end
end
