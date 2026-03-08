class Attendee < ApplicationRecord
  # an attendee belongs to exactly one event (after migration). this
  # enforces presence by default unless nulls are allowed on the column.
  belongs_to :event, optional: true
  validate :capacity_not_exceeded, on: :create
  validate :ip_address_valid?, on: :create
  validate :ensure_unique_identifier, on: [ :create, :update ]

  # the underlying column was originally misspelled `attendence`; a
  # later migration fixes the spelling. declaring the attribute explicitly
  # allows the enum to boot even if the database hasn’t been migrated yet.
  attribute :attendance, :integer, default: 0

  # use positional arguments to avoid Ruby keyword/positional ambiguity
  # (Rails 8's enum signature requires a name argument, so a pure
  # keyword call would pass zero positional args and throw).
  # prefix:true prevents method-name collisions with existing AR methods
  # (ActiveRecord::Base already defines `pending?`, hence the earlier
  # conflict). callers will use `attendance_pending?` etc.
  enum :attendance, { pending: 0, signed_in: 1, signed_out: 2, no_show: 3 }, prefix: true

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
    elsif Attendee.where(code: code).exists?
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
