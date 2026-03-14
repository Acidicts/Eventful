class Event < ApplicationRecord
  # allow a waiver document (txt or pdf) to be attached to the event
  # for attendees to review or download. this uses Active Storage, so the
  # corresponding tables are created via a new migration.
  has_one_attached :waiver
  has_one_attached :icon

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

  attribute :finished, :boolean, default: false



  # ensure the attached waiver is either a PDF or plaintext file and
  # isn't ridiculously large. avoid relying on the built–in
  # ContentTypeValidator since it isn't loaded in the test harness
  # unless activestorage migrations have run, which leads to
  # `Unknown validator: 'ContentTypeValidator'` errors. a custom
  # validation is simpler and explicit.
  validate :waiver_format
  validate :icon_format

  def waiver_format
    return unless waiver.attached?

    unless waiver.content_type.in?([ "application/pdf", "text/plain" ])
      errors.add(:waiver, "must be a PDF or TXT file")
    end

    if waiver.blob.byte_size > 5.megabytes
      errors.add(:waiver, "cannot be larger than 5 MB")
    end
  end

  def icon_format
    return unless icon.attached?

    unless icon.content_type.in?("image/png image/jpeg image/gif".split)
      errors.add(:icon, "must be a PNG, JPEG or GIF image")
    end

    if icon.blob.byte_size > 2.megabytes
      errors.add(:icon, "cannot be larger than 2 MB")
    end
  end

  validate :end_date_after_start_date

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      end_date = start_date + 1.hour
    end
  end

  def finished?
    finished || (end_date.present? && end_date < Time.current)
  end

  def to_param
    apply_token.presence || id.to_s
  end

  private

  def generate_apply_token
    self.apply_token ||= SecureRandom.alphanumeric(12)
  end
end
