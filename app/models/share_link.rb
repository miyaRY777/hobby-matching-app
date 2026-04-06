class ShareLink < ApplicationRecord
  belongs_to :room

  validates :room_id, uniqueness: true

  before_validation :set_token, on: :create

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
