class ShareLink < ApplicationRecord
  belongs_to :room

  validates :room_id, uniqueness: true

  before_validation :set_token, on: :create
  before_validation :set_expires_at, on: :create

  def expired?
    expires_at <= Time.current
  end

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end

  def set_expires_at
    self.expires_at ||= 24.hours.from_now
  end
end
