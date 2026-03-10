class Event < ApplicationRecord
  # each event can have many attendees; the foreign key lives on the
  # attendees table. existing data is migrated during a migration.
  has_many :attendees, dependent: :nullify

  # an event may be organised by a user; the foreign key lives on this model
  belongs_to :organiser, class_name: "User", foreign_key: "organiser_id", optional: true

  belongs_to :organisation

  # public-facing tokens used for applying. we also override `to_param`
  # so URL helpers will emit the token when present.
  before_create :generate_apply_token

  attribute :start_date, :datetime
  attribute :end_date, :datetime

  validate :end_date_after_start_date

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      end_date = start_date + 1.hour
    end
  end

  def finished?
    end_date.present? && end_date < Time.current
  end

  def to_param
    apply_token.presence || id.to_s
  end

  private

  def generate_apply_token
    self.apply_token ||= SecureRandom.alphanumeric(12)
  end
end
