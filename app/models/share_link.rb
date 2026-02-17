class ShareLink < ApplicationRecord
  belongs_to :room

  before_validation :set_token, on: :create
  before_validation :set_expires_at, on: :create

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end

  def set_expires_at
    self.expires_at ||= 24.hours.from_now
  end
end
