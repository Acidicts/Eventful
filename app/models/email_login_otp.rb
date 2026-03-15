class EmailLoginOtp < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  before_validation :generate_token_and_code, on: :create
  validates :token, presence: true, uniqueness: true
  validates :code, presence: true
  validates :expires_at, presence: true

  def consume!
    update!(used_at: Time.current)
  end

  def expired?
    expires_at < Time.current
  end

  private

  def generate_token_and_code
    self.token ||= SecureRandom.urlsafe_base64(24)
    self.code  ||= SecureRandom.random_number(10**6).to_s.rjust(6, "0")
    self.expires_at ||= 10.minutes.from_now
  end
end
