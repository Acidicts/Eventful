class Attendee < ApplicationRecord
  # an attendee belongs to exactly one event (after migration). this
  # enforces presence by default unless nulls are allowed on the column.
  belongs_to :event, optional: true

  # store the copy submitted by the attendee when they sign the waiver
  has_one_attached :signed_waiver

  validate :capacity_not_exceeded, on: :create
  validate :ip_address_valid?, on: :create
  validate :ensure_unique_identifier, on: [ :create, :update ]

  # the underlying column was originally misspelled `attendence`; a
  # later migration fixes the spelling. declaring the attribute explicitly
  # allows the enum to boot even if the database hasn’t been migrated yet.
  attribute :attendance, :integer, default: 0
  attribute :status, :integer, default: 0
  attribute :diet, :integer, default: 0

  # use positional arguments to avoid Ruby keyword/positional ambiguity
  # (Rails 8's enum signature requires a name argument, so a pure
  # keyword call would pass zero positional args and throw).
  # prefix:true prevents method-name collisions with existing AR methods
  # (ActiveRecord::Base already defines `pending?`, hence the earlier
  # conflict). callers will use `attendance_pending?` etc.
  enum :attendance, { pending: 0, signed_in: 1, signed_out: 2, no_show: 3 }, prefix: true
  enum :status, { pending: 0, approved: 1, denied: 2 }, prefix: true
  enum :diet, { none: 0, pescitarian: 1, vegetarian: 2, vegan: 3, other: 4 }, prefix: true

  validates :diet, inclusion: { in: diets.keys }        # ensures integrity
  after_initialize { self.diet ||= :none }              # default

  def diet_label
    if diet == "other"
      return "Other: Write In Allergies Section"
    end
    I18n.t("attendee.diets.#{diet}")
  end


  # simple validation on file mime type/size for uploaded signed waivers
  validate :signed_waiver_format

  def signed_waiver_format
    return unless signed_waiver.attached?
    unless signed_waiver.content_type.in?([ "application/pdf", "text/plain" ])
      errors.add(:signed_waiver, "must be a PDF or TXT file")
    end
    if signed_waiver.blob.byte_size > 5.megabytes
      errors.add(:signed_waiver, "cannot be larger than 5 MB")
    end
  end
  # require either a typed signature or an uploaded copy when the record is
  # being marked as signed; the controller sets `waiver_signed` before
  # updating, so this ensures the request included some evidence.
  validate :signature_or_upload_present, if: :waiver_signed?
  validate :parent_signature_present_if_underage, if: :under_18?

  def signature_or_upload_present
    if waiver_signature.blank? && !signed_waiver.attached?
      errors.add(:base, "Please provide your name or upload the signed waiver")
    end
  end

  def parent_signature_present_if_underage
    if under_18? && parent_signature.blank?
      errors.add(:parent_signature, "must be provided for under‑18 attendees")
    end
  end
  def capacity_not_exceeded
    return unless event

    if event.attendees.count >= event.capacity
      errors.add(:base, "Event capacity exceeded")
    end
  end

  def ensure_unique_identifier
    return unless event

    # avoid using `update` within a callback or validation since that
    # triggers the validation again and can lead to infinite recursion.
    # instead just assign the attribute and let the normal save process
    # persist it.
    if code.blank?
      self.code = "!" + SecureRandom.hex(6)
    elsif Attendee.where(code: code).exists? && Attendee.find_by(code: code).id != id
      self.code = "!" + SecureRandom.hex(6)
      ensure_unique_identifier
    elsif !code.start_with?("!")
      self.code = ""
      ensure_unique_identifier
    end
  end

  # Ensure IP is normalized and not overused for this event.
  # The controller is responsible for assigning `ip` (e.g. from
  # `request.remote_ip`) before validation.  This method tolerates
  # blank values so that callers can choose whether to assign one.
  def ip_address_valid?
    return unless event
    return if ip.blank?

    begin
      normalized = IPAddr.new(ip).to_s
    rescue ArgumentError
      errors.add(:ip, "is invalid")
      return
    end

    if event.attendees.where(ip: normalized).count >= 3
      errors.add(:base, "An attendee with this IP address has already signed up for this event")
    end

    self.ip = normalized
  end
end
